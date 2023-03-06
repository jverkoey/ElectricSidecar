import WidgetKit
import SwiftUI

struct VehicleRangeWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: "ESComplications.VehicleRange",
      provider: VehicleRangeTimelineProvider()
    ) { entry in
      WidgetView(entry: entry)
    }
    .configurationDisplayName("Range")
    .description("Show the remaining range on your vehicle")
#if os(watchOS)
    .supportedFamilies([
      .accessoryCircular,
      .accessoryCorner
    ])
#else
    .supportedFamilies([
      .accessoryCircular
    ])
#endif
  }
}

private struct WidgetView : View {
  @Environment(\.widgetFamily) var family
  @Environment(\.widgetRenderingMode) var widgetRenderingMode

  let entry: VehicleRangeTimelineProvider.Entry

  var body: some View {
    switch family {
    case .accessoryCircular:
      RangeView(
        batteryLevel: entry.chargeRemaining,
        rangeRemaining: entry.rangeRemaining
      )

#if os(watchOS)
    case .accessoryCorner:
      Image(entry.isCharging == true ? "taycan.charge" : "taycan")
        .font(.system(size: cornerFontSize))
        .fontWeight(.regular)
        .unredacted()
        .widgetLabel {
          if let rangeRemaining = entry.rangeRemaining, let chargeRemaining = entry.chargeRemaining {
            Gauge(value: chargeRemaining, in: 0...100.0) {
              Text("")
            } currentValueLabel: {
              Text("")
            } minimumValueLabel: {
              Text(String(format: "%.0f", rangeRemaining))
            } maximumValueLabel: {
              Text(chargeRemaining < 100 ? String(format: "%.0f%%", chargeRemaining) : "100")
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
      Text("\(family.debugDescription)")
    }
  }

  var batteryColor: Color {
    return BatteryStyle.batteryColor(for: entry.chargeRemaining)
  }

  var cornerFontSize: Double {
    switch formFactor() {
    case .phone:
      return 26
    case .watch45mm, .ultra49mm:
      return 26
    case .watch41mm:
      return 23
    case .watch40mm:
      return 23
    }
  }
}

struct VehicleRangeWidget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetView(entry: VehicleRangeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: 80,
      rangeRemaining: 30,
      isCharging: true
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    .previewDisplayName("Valid")

    WidgetView(entry: VehicleRangeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: nil,
      rangeRemaining: nil,
      isCharging: nil
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    .previewDisplayName("Nil")
  }
}

struct VehicleRangeWidgetUITestView: View {
  var body: some View {
    VStack {
      HStack {
        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 0,
          rangeRemaining: 0,
          isCharging: false
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 12,
          rangeRemaining: 20,
          isCharging: true
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 35,
          rangeRemaining: 50,
          isCharging: false
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)
      }
      HStack {
        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 50,
          rangeRemaining: 100,
          isCharging: true
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 84,
          rangeRemaining: 180,
          isCharging: false
        ))
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 100,
          rangeRemaining: 250,
          isCharging: true
        ))
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
      }
    }
  }
}

struct VehicleRangeWidget_UITest_Previews: PreviewProvider {
  static var previews: some View {
    VehicleRangeWidgetUITestView()
  }
}
