import Combine
import CryptoKit
import Foundation
import MapKit
import PorscheConnect

private let fm = FileManager.default

extension FileManager {
  static var sharedContainerURL: URL {
    return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: APP_GROUP_IDENTIFIER
    )!
  }
}

final class ModelStore: ObservableObject {
  private let porscheConnect: PorscheConnect
  private let authStorage: AuthStorage
  private let cacheCoordinator = CodableCacheCoordinator()

  private let simulating: Bool
  private let cacheURL: URL
  private let vehiclesURL: URL
  private let vehicleCacheTimeout: TimeInterval = 60 * 60 * 24
  private let cacheTimeout: TimeInterval = 15 * 60
  private let longCacheTimeout: TimeInterval = 60 * 60 * 24 * 365

  @Published var vehicles: [UIModel.Vehicle]?

  init(username: String, password: String, simulatedGarage: String? = nil) {
    let baseURL = FileManager.sharedContainerURL
    let hashed = SHA256.hash(data: username.data(using: .utf8)!)
    let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()

    // Root cache directory
    if let simulatedGarage,
       !simulatedGarage.isEmpty,
       let mockDataUrl = Bundle.main.url(forResource: "MockData", withExtension: nil) {
      self.cacheURL = mockDataUrl.appendingPathComponent(simulatedGarage)
      simulating = true
    } else {
      self.cacheURL = baseURL.appendingPathComponent(".cache").appendingPathComponent(hashString)
      if !fm.fileExists(atPath: cacheURL.path) {
        try! fm.createDirectory(at: cacheURL, withIntermediateDirectories: true)
      }
      simulating = false
    }

    // Auth tokens
    let authTokensURL = self.cacheURL.appendingPathComponent("auth_tokens")
    if !simulating && !fm.fileExists(atPath: authTokensURL.path) {
      try! fm.createDirectory(at: authTokensURL, withIntermediateDirectories: true)
    }
    self.authStorage = AuthStorage(authTokensURL: authTokensURL, fileCoordinator: cacheCoordinator)

    // Vehicle data
    self.vehiclesURL = self.cacheURL.appendingPathComponent("vehicles")

    porscheConnect = PorscheConnect(
      username: username,
      password: password,
      environment: Environment(locale: SupportedLocale.default)!,
      authStorage: authStorage
    )
  }

  // MARK: - Combine-based cache warming

  func load() async throws {
    Logging.network.info("Initial load")
    let vehicles: [Vehicle]
    do {
      vehicles = try await vehicleList()

      // Verify that the preferred VIN exists, or default to the first one
      if vehicles.first(where: { $0.vin == AUTH_MODEL.preferences.primaryVIN }) == nil {
        AUTH_MODEL.preferences.primaryVIN = vehicles.first?.vin ?? ""
      }
    } catch {
      Logging.network.error("Failed initial load with error: \(error, privacy: .public)")
      throw error
    }

    Logging.network.debug("Loaded \(vehicles.count, privacy: .public) vehicles")
    let vehicleModels = vehicles.map { vehicle in
      return UIModel.Vehicle(
        vin: vehicle.vin,
        licensePlate: vehicle.licensePlate,
        modelDescription: vehicle.modelDescription,
        modelYear: vehicle.modelYear,
        color: vehicle.color,
        personalizedPhoto: vehicle.personalizedPhoto,
        externalPhotos: vehicle.pictures ?? []
      )
    }

    await MainActor.run {
      Logging.network.log(level: .debug, "Vehicles provided to model")
      self.vehicles = vehicleModels
    }
  }

  func refreshStatus(for vin: String, ignoreCache: Bool = false) async {
    do {
      Logging.network.info("Refreshing status for \(vin, privacy: .private(mask: .hash))")
      let status: Stored

#if DEBUG
      status = try await self.status(for: vin, ignoreCache: ignoreCache)
#else
      status = try await self.status(for: vin, ignoreCache: ignoreCache)
#endif
      let distanceFormatter = DistanceFormatter()
      let electricalRange: String?
      if let distance = status.remainingRanges.electricalRange.distance {
        electricalRange = distanceFormatter.string(from: distance)
      } else {
        electricalRange = nil
      }
      self.statusSubject(for: vin).send(.loaded(UIModel.Vehicle.Status(
        batteryLevel: status.batteryLevel.value,
        electricalRange: electricalRange,
        mileage: distanceFormatter.string(from: status.mileage),
        doors: UIModel.Vehicle.Doors(
          frontLeft: status.doors.frontLeft.uiModel,
          frontRight: status.doors.frontRight.uiModel,
          backLeft: status.doors.backLeft.uiModel,
          backRight: status.doors.backRight.uiModel,
          frontTrunk: status.doors.frontTrunk.uiModel,
          backTrunk: status.doors.backTrunk.uiModel,
          overallLockStatus: status.doors.overallLockStatus.uiModel
        )
      )))
      Logging.network.info("Finished refreshing status for \(vin, privacy: .private(mask: .hash))")
    } catch {
      Logging.network.error("Status failed \(error, privacy: .public)")
      self.statusSubjects[vin]?.send(.error(error))
    }
  }

  func refreshEmobility(for vin: String, ignoreCache: Bool = false) async {
    do {
      Logging.network.info("Refreshing emobility for \(vin, privacy: .private(mask: .hash))")
      let emobility = try await emobility(for: vin, ignoreCache: ignoreCache)
      let emobilityFreshnessDate = try emobilityFreshnessDate(for: vin)

      let climatizationCompletionDate: Date?
      if let remainingClimatisationTime = emobility.directClimatisation.remainingClimatisationTime,
         let emobilityFreshnessDate {
        climatizationCompletionDate = emobilityFreshnessDate.addingTimeInterval(TimeInterval(remainingClimatisationTime) * 60)
      } else {
        climatizationCompletionDate = nil
      }

      self.emobilitySubject(for: vin).send(.loaded(UIModel.Vehicle.Emobility(
        isCharging: emobility.isCharging == true,
        isClimatizationEnabled: emobility.directClimatisation.climatisationState == "ON",
        climatizationCompletionDate: climatizationCompletionDate
      )))
      Logging.network.info("Finished refreshing emobility for \(vin, privacy: .private(mask: .hash))")
    } catch {
      Logging.network.error("Status failed \(error, privacy: .public)")
      self.emobilitySubjects[vin]?.send(.error(error))
    }
  }

  private var refreshState: [String: Bool] = [:]
  func refresh(vin: String, ignoreCache: Bool = false) async throws {
    Logging.network.info("Refresh state attempt for \(vin, privacy: .private(mask: .hash))")
    if refreshState[vin] == true {
      return  // Already refreshing.
    }
    refreshState[vin] = true
    defer {
      refreshState[vin] = false
    }

    Logging.network.info("Starting refresh task group for \(vin, privacy: .private(mask: .hash))")

    // TODO: Keep an in-memory cache of the last-known status.
    await withTaskGroup(of: Void.self, body: { taskGroup in
      taskGroup.addTask {
        await self.refreshStatus(for: vin, ignoreCache: ignoreCache)
      }
      taskGroup.addTask {
        await self.refreshEmobility(for: vin, ignoreCache: ignoreCache)
      }
      taskGroup.addTask {
        do {
          Logging.network.info("Refreshing position for \(vin, privacy: .private(mask: .hash))")
          let position = try await self.position(for: vin, ignoreCache: ignoreCache)
          let coordinateRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: position.carCoordinate.latitude,
                                           longitude: position.carCoordinate.longitude),
            latitudinalMeters: 200,
            longitudinalMeters: 200
          )
          self.positionSubject(for: vin).send(.loaded(UIModel.Vehicle.Position(
            coordinateRegion: coordinateRegion
          )))
          Logging.network.info("Finished refreshing position for \(vin, privacy: .private(mask: .hash))")
        } catch {
          Logging.network.error("Status failed \(error, privacy: .public)")
          self.positionSubjects[vin]?.send(.error(error))
        }
      }
    })
    Logging.network.info("Finished refreshing \(vin, privacy: .private(mask: .hash))")
  }

  private var statusSubjects: [String: any Subject<UIModel.Refreshable<UIModel.Vehicle.Status>, Never>] = [:]
  private func statusSubject(for vin: String) -> any Subject<UIModel.Refreshable<UIModel.Vehicle.Status>, Never> {
    if let subject = statusSubjects[vin] {
      return subject
    }
    let subject = CurrentValueSubject<UIModel.Refreshable<UIModel.Vehicle.Status>, Never>(.loading)
    statusSubjects[vin] = subject
    return subject
  }
  func statusPublisher(for vin: String) -> AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Status>, Never> {
    return statusSubject(for: vin).eraseToAnyPublisher()
  }

  private var emobilitySubjects: [String: any Subject<UIModel.Refreshable<UIModel.Vehicle.Emobility>, Never>] = [:]
  private func emobilitySubject(for vin: String) -> any Subject<UIModel.Refreshable<UIModel.Vehicle.Emobility>, Never> {
    if let subject = emobilitySubjects[vin] {
      return subject
    }
    let subject = CurrentValueSubject<UIModel.Refreshable<UIModel.Vehicle.Emobility>, Never>(.loading)
    emobilitySubjects[vin] = subject
    return subject
  }
  func emobilityPublisher(for vin: String) -> AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Emobility>, Never> {
    return emobilitySubject(for: vin).eraseToAnyPublisher()
  }

  private var positionSubjects: [String: any Subject<UIModel.Refreshable<UIModel.Vehicle.Position>, Never>] = [:]
  private func positionSubject(for vin: String) -> any Subject<UIModel.Refreshable<UIModel.Vehicle.Position>, Never> {
    if let subject = positionSubjects[vin] {
      return subject
    }
    let subject = CurrentValueSubject<UIModel.Refreshable<UIModel.Vehicle.Position>, Never>(.loading)
    positionSubjects[vin] = subject
    return subject
  }
  func positionPublisher(for vin: String) -> AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Position>, Never> {
    return positionSubject(for: vin).eraseToAnyPublisher()
  }

  // MARK: - API invocations

  func vehicleList(ignoreCache: Bool = false) async throws -> [Vehicle] {
    let url = cacheURL.appendingPathComponent("vehicleList")
    // Try disk cache first, if allowed.
    if !ignoreCache,
       let result: [Vehicle] = try cacheCoordinator.decode(url: url, timeout: vehicleCacheTimeout) {
      return result
    }

    assert(!simulating)

    // Fetch data if we don't have it.
    let response = try await porscheConnect.vehicles()
    guard response.response.statusCode < 300,
          let vehicles = response.vehicles else {
      fatalError()
    }

    try cacheCoordinator.encode(url: url, object: vehicles)

    return vehicles
  }

  func capabilities(for vin: String, ignoreCache: Bool = false) async throws -> Capabilities {
    return try await get(
      vin: vin,
      cacheKey: "capabilities",
      timeout: longCacheTimeout,
      ignoreCache: ignoreCache
    ) {
      let response = try await porscheConnect.capabilities(vin: vin)
      guard response.response.statusCode < 300,
            let result = response.capabilities else {
        fatalError()
      }
      return result
    }
  }

  func emobility(for vin: String, ignoreCache: Bool = false) async throws -> Emobility {
    let capabilities = try await capabilities(for: vin, ignoreCache: ignoreCache)
    return try await get(
      vin: vin,
      cacheKey: "emobility",
      timeout: cacheTimeout,
      ignoreCache: ignoreCache
    ) {
      let response = try await porscheConnect.emobility(vin: vin, capabilities: capabilities)
      guard response.response.statusCode < 300,
            let result = response.emobility else {
        fatalError()
      }
      return result
    }
  }

  func emobilityFreshnessDate(for vin: String) throws -> Date? {
    return try lastModificationTime(vin: vin, cacheKey: "emobility")
  }

  func summary(for vin: String, ignoreCache: Bool = false) async throws -> Summary {
    return try await get(
      vin: vin,
      cacheKey: "summary",
      timeout: cacheTimeout,
      ignoreCache: ignoreCache
    ) {
      let response = try await porscheConnect.summary(vin: vin)
      guard response.response.statusCode < 300,
            let result = response.summary else {
        fatalError()
      }
      return result
    }
  }

  func position(for vin: String, ignoreCache: Bool = false) async throws -> Position {
    return try await get(
      vin: vin,
      cacheKey: "position",
      timeout: cacheTimeout,
      ignoreCache: ignoreCache
    ) {
      let response = try await porscheConnect.position(vin: vin)
      guard response.response.statusCode < 300,
            let result = response.position else {
        fatalError()
      }
      return result
    }
  }

  func status(for vin: String, ignoreCache: Bool = false) async throws -> Stored {
    return try await get(
      vin: vin,
      cacheKey: "stored",
      timeout: cacheTimeout,
      ignoreCache: ignoreCache
    ) {
      let response = try await porscheConnect.stored(vin: vin)
      guard response.response.statusCode < 300,
            let result = response.stored else {
        fatalError()
      }
      return result
    }
  }

  func lockUnlockLastActions(vin: String, ignoreCache: Bool = false) async throws -> LockUnlockLastActions {
    return try await get(
      vin: vin,
      cacheKey: "lock-unlock-last-actions",
      timeout: cacheTimeout,
      ignoreCache: ignoreCache
    ) {
      let response = try await porscheConnect.lockUnlockLastActions(vin: vin)
      guard response.response.statusCode < 300,
            let result = response.lastActions else {
        fatalError()
      }
      return result
    }
  }

  // MARK: - Actions

  func lock(vin: String) async throws -> RemoteCommandAccepted? {
    assert(!simulating)
    let response = try await porscheConnect.lock(vin: vin)
    guard response.response.statusCode < 300 else {
      Logging.network.error("Failed to lock the car: \(response.response)")
      // TODO: Throw an error here.
      return nil
    }
    return response.remoteCommandAccepted
  }

  func toggleClimatization(vin: String, enable: Bool) async throws -> RemoteCommandAccepted? {
    assert(!simulating)
    let response = try await porscheConnect.toggleDirectClimatisation(vin: vin, enable: enable)
    guard response.response.statusCode < 300 else {
      Logging.network.error("Failed to toggle direct climatization: \(response.response)")
      // TODO: Throw an error here.
      return nil
    }
    return response.remoteCommandAccepted
  }

  func checkStatus(vin: String, remoteCommand: RemoteCommandAccepted) async throws -> RemoteCommandStatus? {
    let response = try await porscheConnect.checkStatus(vin: vin, remoteCommand: remoteCommand)
    guard response.response!.statusCode < 300 else {
      Logging.network.error("Failed to lock the car: \(response.response)")
      // TODO: Throw an error here.
      return nil
    }
    return response.status
  }

  private func lastModificationTime(vin: String, cacheKey: String) throws -> Date? {
    let vehicleURL = vehiclesURL.appendingPathComponent(vin)
    let url = vehicleURL.appendingPathComponent(cacheKey)
    return cacheCoordinator.fileModificationDate(url: url)
  }

  private func get<T: Codable>(
    vin: String,
    cacheKey: String,
    timeout: TimeInterval,
    ignoreCache: Bool = false,
    api: () async throws -> T
  ) async throws -> T {
    // Try disk cache first.
    let vehicleURL = vehiclesURL.appendingPathComponent(vin)
    let url = vehicleURL.appendingPathComponent(cacheKey)
    if !simulating && !fm.fileExists(atPath: vehicleURL.path) {
      try fm.createDirectory(at: vehicleURL, withIntermediateDirectories: true)
    }
    if (simulating || !ignoreCache),
       let result: T = try cacheCoordinator.decode(url: url, timeout: simulating ? nil : timeout) {
      return result
    }

    assert(!simulating, "Shouldn't be simulating when loading \(url)")

    // Fetch data if we don't have it.
    let result = try await api()

    try cacheCoordinator.encode(url: url, object: result)

    return result
  }

  func flash(vin: String) async throws {
    assert(!simulating)
    let response = try await porscheConnect.flash(vin: vin)
    guard response.response.statusCode == 200 else {
      fatalError()
    }
  }
}

/// This actor type ensures that all storage/retrieval of auth tokens happens in a thread-safe manner.
private actor AuthStoreActor {
  private var authTokens: [String: OAuthToken] = [:]

  func storeAuthentication(token: OAuthToken?, for key: String) {
    authTokens[key] = token
  }

  func authentication(for key: String) async -> OAuthToken? {
    return authTokens[key]
  }
}

private final class AuthStorage: AuthStoring {
  private let actor = AuthStoreActor()
  private let authTokensURL: URL
  private let cacheCoordinator: CodableCacheCoordinator
  init(authTokensURL: URL, fileCoordinator: CodableCacheCoordinator) {
    self.authTokensURL = authTokensURL
    self.cacheCoordinator = fileCoordinator
  }

  func storeAuthentication(token: OAuthToken?, for key: String) async throws {
    let url = authTokenUrl(key: key)

    if ProcessInfo.processInfo.environment["TESTING"] != "1" {
      try cacheCoordinator.encode(url: url, object: token)
    }

    await actor.storeAuthentication(token: token, for: key)
  }

  func authentication(for key: String) async -> OAuthToken? {
    // Prioritize in-memory tokens.
    if let token = await actor.authentication(for: key) {
      return token
    }

    if ProcessInfo.processInfo.environment["TESTING"] == "1" {
      return nil
    }

    let url = authTokenUrl(key: key)
    if let token: OAuthToken = try! cacheCoordinator.decode(url: url) {
      await actor.storeAuthentication(token: token, for: key)
      return token
    }

    // No token able to be loaded from memory or disk.
    return nil
  }

  private func authTokenUrl(key: String) -> URL {
    return authTokensURL.appendingPathComponent(key)
  }
}
