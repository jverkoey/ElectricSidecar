import SwiftUI

@main
struct WatchUICatalog_Watch_AppApp: App {
  var body: some Scene {
    WindowGroup {
      switch ProcessInfo.processInfo.environment["test-case"] {
      case "login-view":
        LoginView(email: ProcessInfo.processInfo.environment["email"] ?? "",
                  password: ProcessInfo.processInfo.environment["password"] ?? "") { email, password in
          print("Did log in")
        }.accessibilityIdentifier("root-view")
      default:
        Text("Unknown test case")
      }
    }
  }
}
