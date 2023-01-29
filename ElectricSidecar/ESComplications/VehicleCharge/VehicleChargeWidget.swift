import WidgetKit
import SwiftUI

struct VehicleChargeWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "ESComplications.VehicleCharge",
      provider: VehicleChargeTimelineProvider()
    ) { entry in
      WidgetView(entry: entry)
    }
    .configurationDisplayName("Charge")
    .description("Show the remaining charge on your vehicle")
    .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
  }
}

private struct WidgetView : View {
  @Environment(\.widgetFamily) var family
  @Environment(\.widgetRenderingMode) var widgetRenderingMode

  let entry: VehicleChargeTimelineProvider.Entry

  var body: some View {

    switch family {
    case .accessoryCircular:
      ChargeView(
        batteryLevel: entry.chargeRemaining,
        isCharging: entry.isCharging == true,
        lineWidth: 4
      )
      .padding(2)
    case .accessoryCorner:
      if let chargeRemaining = entry.chargeRemaining {
        HStack(spacing: 0) {
          Image(entry.isCharging == true ? "taycan.charge" : "taycan")
            .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 23 : 26))
            .fontWeight(.regular)
        }
        .widgetLabel {
          Gauge(value: chargeRemaining, in: 0...100.0) {
            Text("")
          } currentValueLabel: {
            Text("")
          } minimumValueLabel: {
            Text("")
          } maximumValueLabel: {
            Text(chargeRemaining < 100 ? Self.formatted(chargeRemaining: chargeRemaining) : "100")
              .foregroundColor(batteryColor)
          }
          .tint(batteryColor)
          .gaugeStyle(LinearGaugeStyle(tint: Gradient(colors: [.red, .orange, .yellow, .green])))
        }
      } else {
        HStack(spacing: 0) {
          Image(entry.isCharging == true ? "taycan.charge" : "taycan")
            .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 23 : 26))
            .fontWeight(.regular)
        }
      }
    case .accessoryInline:
      // Note: inline accessories only support one Text and/or Image element. Any additional
      // elements will be ignored.
      HStack {
        if widgetRenderingMode == .fullColor {
          Image(systemName: "bolt.car")
            .symbolRenderingMode(.palette)
            .foregroundStyle(entry.isCharging == true ? .white : .clear, .white)
        } else {
          // Non-full-color rendering modes don't support palette rendering, so we need to use
          // an alternate glyph instead.
          Image(systemName: entry.isCharging == true ? "bolt.car" : "car")
        }
        if let chargeRemaining = entry.chargeRemaining {
          Text(Self.formatted(chargeRemaining: chargeRemaining))
        }
      }
    default:
      Text("Unsupported")
    }
  }

  var batteryColor: Color {
    guard let chargeRemaining = entry.chargeRemaining else {
      return .gray
    }
    if chargeRemaining >= 80 {
      return .green
    } else if chargeRemaining >= 50 {
      return .yellow
    } else if chargeRemaining > 20 {
      return .orange
    } else {
      return .red
    }
  }

  static func formatted(chargeRemaining: Double) -> String {
    return String(format: "%.0f%%", chargeRemaining)
  }
}

struct VehicleChargeWidget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetView(entry: VehicleChargeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: 100,
      isCharging: true
    ))
    .previewDevice("Apple Watch Series 8 (45mm)")
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
  }
}
