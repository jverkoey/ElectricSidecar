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
      .accessoryInline,
      .accessoryCorner,
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
      ChargeView(
        batteryLevel: entry.chargeRemaining,
        isCharging: entry.isCharging == true
      )

    case .accessoryInline:
      // Note: inline accessories only support one Text and/or Image element. Any additional
      // elements will be ignored.
      HStack {
        if widgetRenderingMode == .fullColor {
          // taycan.charge is too wide, so we have to use a system car image instead.
          Image(systemName: "bolt.car")
            .symbolRenderingMode(.palette)
            .foregroundStyle(entry.isCharging == true ? .white : .clear, .white)
            .unredacted()
        } else {
          // Non-full-color rendering modes don't support palette rendering, so we need to use
          // an alternate glyph instead.
          Image(systemName: entry.isCharging == true ? "bolt.car" : "car")
            .unredacted()
        }
        if let chargeRemaining = entry.chargeRemaining {
          Text(Self.formatted(chargeRemaining: chargeRemaining))
            .unredacted()
        }
      }

#if os(watchOS)
    case .accessoryCorner:
      Image(entry.isCharging == true ? "taycan.charge" : "taycan")
        .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 23 : 26))
        .fontWeight(.regular)
        .unredacted()
        .widgetLabel {
          if let chargeRemaining = entry.chargeRemaining {
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
            .unredacted()
          } else {
            // Gauge doesn't can't represent an unknown value, so use a ProgressView instead.
            ProgressView(value: 1)
              .tint(.gray)
          }
        }
#endif

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
      chargeRemaining: 60,
      isCharging: true
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    .previewDisplayName("Valid")

    VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: nil,
      isCharging: nil
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    .previewDisplayName("Nil")
  }
}

struct VehicleChargeWidgetUITestView: View {
  var body: some View {

    VStack {
      HStack {
        VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 0,
          isCharging: false
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

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
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)

        VehicleChargeWidgetView(entry: VehicleChargeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 100,
          isCharging: true
        ))
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
      }
    }
  }
}

struct VehicleChargeWidget_UITest_Previews: PreviewProvider {
  static var previews: some View {
    VehicleChargeWidgetUITestView()
  }
}
