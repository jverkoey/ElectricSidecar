import Foundation
import SwiftUI
import WatchConnectivity

private let userDefaults = UserDefaults(suiteName: APP_GROUP_IDENTIFIER)

protocol AuthModeling: AnyObject {
  var email: String { get set }
  var password: String { get set }
  var store: ModelStore? { get }
  func authenticationFailed()

  var preferences: Preferences { get set }

#if DEBUG
  var simulatedGarage: String { get set }
#else
  var simulatedGarage: String { get }
#endif
}

struct Preferences: Codable, RawRepresentable {
  var primaryVIN: String = ""

  enum CodingKeys: String, CodingKey {
    case primaryVIN
  }

  init(from decoder: Decoder) throws {
    let group = try decoder.container(keyedBy: CodingKeys.self)
    primaryVIN = try group.decode(String.self, forKey: .primaryVIN)
  }

  func encode(to encoder: Encoder) throws {
    var group = encoder.container(keyedBy: CodingKeys.self)
    try group.encode(primaryVIN, forKey: .primaryVIN)
  }

  init() {
  }

  init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(Self.self, from: data)
    else {
      return nil
    }
    self = result
  }

  var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

final class AuthModel: AuthModeling {
  @AppStorage("email", store: userDefaults)
  var email: String = ""
  @AppStorage("password", store: userDefaults)
  var password: String = ""
  @AppStorage("preferences", store: userDefaults)
  var preferences = Preferences()

#if DEBUG
  @AppStorage("simulatedGarage", store: userDefaults)
  var simulatedGarage: String = ""
#else
  let simulatedGarage = ""
#endif

  var store: ModelStore? {
    Logging.intents.info("Simulated garage: \(self.simulatedGarage)")
    if simulatedGarage.isEmpty && (email.isEmpty || password.isEmpty) {
      return nil
    }
    if let store = _store {
      return store
    }
    _store = ModelStore(username: email, password: password, simulatedGarage: simulatedGarage)
    return _store
  }
  private var _store: ModelStore?
  func authenticationFailed() {
    _store = nil
  }

  init() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(Self.reachabilityDidChange),
      name: .activationDidComplete, object: nil
    )
    NotificationCenter.default.addObserver(
      self, selector: #selector(Self.reachabilityDidChange),
      name: .reachabilityDidChange, object: nil
    )

    reachabilityDidChange()
  }

  @objc func reachabilityDidChange() {
    if ProcessInfo.processInfo.environment["TESTING"] == "1" {
      // Don't try to handle any reachability while testing.
      return
    }
    Logging.watchConnectivity.info("Reachability state: \(WCSession.default.isReachable)")

    var isReachable = false
    if WCSession.default.activationState == .activated {
      isReachable = WCSession.default.isReachable
    }

    if isReachable {
      Logging.watchConnectivity.info("Requesting auth credentials from the phone...")
      WCSession.default.sendMessage(["request": "auth-credentials"]) { response in
        DispatchQueue.main.async {
          Logging.watchConnectivity.info("Received response \(response, privacy: .sensitive)")
          if let email = response["email"] as? String,
             let password = response["password"] as? String {
            if !email.isEmpty {
              self.email = email
            }
            if !password.isEmpty {
              self.password = password
            }
          }
        }
      }
    }
  }
}

final class FakeAuthModel: AuthModeling {
  var email: String = ""
  var password: String = ""
  @AppStorage("preferences", store: userDefaults)
  var preferences = Preferences()
#if DEBUG
  @AppStorage("simulatedGarage", store: userDefaults)
  var simulatedGarage: String = ""
#else
  let simulatedGarage = ""
#endif

  var store: ModelStore? {
    if simulatedGarage.isEmpty && (email.isEmpty || password.isEmpty) {
      return nil
    }
    if let store = _store {
      return store
    }
    _store = ModelStore(username: email, password: password, simulatedGarage: simulatedGarage)
    return _store
  }
  private var _store: ModelStore?

  func authenticationFailed() {
    _store = nil
  }
}

let AUTH_MODEL: AuthModeling = {
  let model: AuthModeling
  if ProcessInfo.processInfo.environment["TESTING"] == "1"
      || ProcessInfo.processInfo.environment["SIMULATED_GARAGE"] != nil {
    model = FakeAuthModel()
  } else {
    model = AuthModel()
  }

#if DEBUG
  if let simulatedGarage = ProcessInfo.processInfo.environment["SIMULATED_GARAGE"] {
    model.email = "test@test.com"
    model.password = "test"
    model.simulatedGarage = simulatedGarage
  } else if Bundle.main.bundleURL.pathExtension != "appex" {
    model.simulatedGarage = ""
  }
#endif
  return model
}()
