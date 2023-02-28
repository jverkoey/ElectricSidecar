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
        VStack {
          HStack {
            VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
              date: Date(),
              chargeRemaining: 12,
              isCharging: false
            ))
            .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

            VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
              date: Date(),
              chargeRemaining: 35,
              isCharging: true
            ))
            .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)
          }
          HStack {
            VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
              date: Date(),
              chargeRemaining: 50,
              isCharging: false
            ))
            .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

            VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
              date: Date(),
              chargeRemaining: 84,
              isCharging: true
            ))
            .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)
          }
        }.accessibilityIdentifier("root-view")
      default:
        Text("Unknown test case")
      }
    }
  }

  func circularComplicationSize() -> CGSize {
    let deviceSize = WKInterfaceDevice.current().screenBounds.size
    switch deviceSize {
    case CGSize(width: 205, height: 251):
      return CGSize(width: 50, height: 50)
    case CGSize(width: 198, height: 242):
      return CGSize(width: 50, height: 50)
    case CGSize(width: 176, height: 215):
      return CGSize(width: 44.5, height: 44.5)
    default:
      fatalError("Unknown device size")
    }
  }
}
