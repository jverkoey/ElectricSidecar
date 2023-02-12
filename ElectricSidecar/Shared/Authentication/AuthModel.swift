import Foundation
import SwiftUI
import WatchConnectivity

protocol AuthModeling: AnyObject {
  var email: String { get set }
  var password: String { get set }
  var store: ModelStore? { get }
}

final class AuthModel: AuthModeling {
  @AppStorage("email", store: UserDefaults(suiteName: APP_GROUP_IDENTIFIER))
  var email: String = ""
  @AppStorage("password", store: UserDefaults(suiteName: APP_GROUP_IDENTIFIER))
  var password: String = ""

  var store: ModelStore? {
    if email.isEmpty || password.isEmpty {
      return nil
    }
    if let store = _store {
      return store
    }
    _store = ModelStore(username: email, password: password)
    return _store
  }
  private var _store: ModelStore?

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

  var store: ModelStore? {
    if email.isEmpty || password.isEmpty {
      return nil
    }
    if let store = _store {
      return store
    }
    _store = ModelStore(username: email, password: password)
    return _store
  }
  private var _store: ModelStore?
}

let AUTH_MODEL: AuthModeling = {
  if ProcessInfo.processInfo.environment["TESTING"] == "1" {
    return FakeAuthModel()
  }
  return AuthModel()
}()
