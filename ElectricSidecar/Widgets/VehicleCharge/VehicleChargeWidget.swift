import WidgetKit
import SwiftUI

struct VehicleChargeWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "ESComplications.VehicleCharge",
      provider: VehicleChargeTimelineProvider()
    ) { entry in
      VehicleChargeWidgetView(entry: entry)
    }
    .configurationDisplayName("Charge")
    .description("Show the remaining charge on your vehicle")
#if os(watchOS)
    .supportedFamilies([
      .accessoryCircular,
      .accessoryCorner,
      .accessoryInline
    ])
#else
    .supportedFamilies([
      .accessoryCircular,
      .accessoryInline
    ])
#endif
  }
}

struct VehicleChargeWidgetView : View {
  @Environment(\.widgetFamily) var family
  @Environment(\.widgetRenderingMode) var widgetRenderingMode

  let entry: VehicleChargeTimelineProvider.Entry

  var body: some View {

    switch family {
    case .accessoryCircular:
#if os(watchOS)
      ChargeView(
        batteryLevel: entry.chargeRemaining,
        isCharging: entry.isCharging == true,
        lineWidth: 5
      )
      .padding(2.5)
#else
      ChargeView(
        batteryLevel: entry.chargeRemaining,
        isCharging: entry.isCharging == true,
        iconOffset: 2,
        iconFontSize: 26,
        labelFontSize: 14,
        lineWidth: 5
      )
      .padding(2.5)
#endif
    case .accessoryCorner:
      if let chargeRemaining = entry.chargeRemaining {
        HStack(spacing: 0) {
          Image(entry.isCharging == true ? "taycan.charge" : "taycan")
#if os(watchOS)
            .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 23 : 26))
#else
            .font(.system(size: 26))
#endif
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
#if os(watchOS)
          .gaugeStyle(LinearGaugeStyle(tint: Gradient(colors: [.red, .orange, .yellow, .green])))
#endif
        }
      } else {
        HStack(spacing: 0) {
          Image(entry.isCharging == true ? "taycan.charge" : "taycan")
#if os(watchOS)
            .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 23 : 26))
#endif
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
    return BatteryStyle.batteryColor(for: entry.chargeRemaining)
  }

  static func formatted(chargeRemaining: Double) -> String {
    return String(format: "%.0f%%", chargeRemaining)
  }
}

struct VehicleChargeWidget_Previews: PreviewProvider {
  static var previews: some View {
    VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: 100,
      isCharging: true
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
  }
}
