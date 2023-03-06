import SwiftUI

@main
struct UICatalogApp: App {
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
      case "vehicle-details-view":
        VehicleDetailsView(status: .constant(UIModel.Vehicle.Status(
          batteryLevel: 100,
          electricalRange: "100 miles",
          mileage: "100 miles",
          doors: UIModel.Vehicle.Doors(
            frontLeft: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
            frontRight: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
            backLeft: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
            backRight: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: true),
            frontTrunk: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: true),
            backTrunk: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
            overallLockStatus: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: true)
          )
        )), modelDescription: "Taycan", modelYear: "2022", vin: "WP0AB1C23DEF45678")
        .accessibilityIdentifier("root-view")
      default:
        Text("Unknown test case")
      }
    }
  }
}
