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
      case "error-view":
        VehicleErrorView(
          statusError: .constant(URLError(.badServerResponse)),
          emobilityError: .constant(URLError(.badServerResponse)),
          positionError: .constant(URLError(.badServerResponse))
        ).accessibilityIdentifier("root-view")
      case "vehicle-charge-widget":
        VehicleChargeWidgetUITestView().accessibilityIdentifier("root-view")
      case "vehicle-range-widget":
        VehicleRangeWidgetUITestView().accessibilityIdentifier("root-view")
      default:
        Text("Unknown test case")
      }
    }
  }
}
