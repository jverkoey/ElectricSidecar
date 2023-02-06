import Foundation
import SwiftUI

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
