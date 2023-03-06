import PorscheConnect
import OSLog
import SwiftUI

extension URLCache {
  static let imageCache = URLCache(memoryCapacity: 20*1024*1024, diskCapacity: 128*1024*1024)
}

struct GarageView: View {
  @StateObject var store: ModelStore
  let authFailure: (Error) -> Void

  enum LoadState {
    case error(error: Error)
    case loadingVehicles
    case loaded
  }

  @State var isLogReadingEnabled: Bool = false

  @State var loadState: LoadState = .loadingVehicles
  var body: some View {
    NavigationStack {
      if let vehicles = store.vehicles {
        TabView {
          ForEach(vehicles) { vehicle in
            VehicleView(
              vehicle: vehicle,
              statusPublisher: store.statusPublisher(for: vehicle.vin),
              emobilityPublisher: store.emobilityPublisher(for: vehicle.vin),
              positionPublisher: store.positionPublisher(for: vehicle.vin)
            ) { ignoreCache in
              try await store.refresh(vin: vehicle.vin, ignoreCache: ignoreCache)
            } lockCallback: {
              guard let commandToken = try await store.lock(vin: vehicle.vin) else {
                return
              }

              var lastStatus = try await store.checkStatus(
                vin: vehicle.vin,
                remoteCommand: commandToken
              )?.remoteStatus
              while lastStatus == .inProgress {
                // Avoid excessive API calls.
                try await Task.sleep(nanoseconds: UInt64(0.5 * Double(NSEC_PER_SEC)))

                lastStatus = try await store.checkStatus(
                  vin: vehicle.vin,
                  remoteCommand: commandToken
                )?.remoteStatus
              }

              await store.refreshStatus(for: vehicle.vin)
            } unlockCallback: {
              print("Unlock the car...")
            }
            .navigationTitle(vehicle.licensePlate ?? "\(vehicle.modelDescription) (\(vehicle.modelYear))")
#if !os(watchOS)
            .tabItem {
              Label(vehicle.licensePlate ?? vehicle.modelDescription, image: "taycan")
            }
#endif
          }
          if isLogReadingEnabled {
            LogsView()
#if os(watchOS)
              .tabItem {
                Label("Debug logs", systemImage: "magnifyingglass")
              }
#else
              .tabItem {
                Label("Debug logs", systemImage: "rectangle.and.text.magnifyingglass")
              }
#endif
          }
        }
      } else {
        ProgressView()
      }
    }
    .task(priority: .background) {
      do {
        isLogReadingEnabled = try checkIfLogReadingIsEnabled()
      } catch {
        isLogReadingEnabled = false
      }
    }
  }

  func checkIfLogReadingIsEnabled() throws -> Bool {
    let subsystem = "group.com.featherless.electricsidecar.testlogger"
    let testLogger = Logger(subsystem: subsystem, category: "test")
    testLogger.error("test")
    let startTime = Date(timeIntervalSinceNow: -5)
    let logStore = try OSLogStore(scope: .currentProcessIdentifier)
    let predicate = NSPredicate(format: "subsystem == %@", argumentArray: [subsystem])
    let position = logStore.position(date: startTime)
    return try logStore.getEntries(at: position, matching: predicate).makeIterator().next() != nil
  }
}
