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
    .supportedFamilies([.accessoryCircular])
  }
}

private struct WidgetView : View {
  @Environment(\.widgetFamily) var family
  @Environment(\.widgetRenderingMode) var widgetRenderingMode

  let entry: VehicleRangeTimelineProvider.Entry

  var batteryColor: Color {
    return BatteryStyle.batteryColor(for: entry.chargeRemaining)
  }

  var body: some View {
    ZStack {
      RadialProgressView(fillPercent: 1, color: batteryColor.opacity(0.2), lineWidth: 5, fillRatio: 0.7)
      if let chargeRemaining = entry.chargeRemaining {
        RadialProgressView(fillPercent: chargeRemaining * 0.01, color: batteryColor, lineWidth: 5, fillRatio: 0.7)
          .widgetAccentable(true)
      }
      if let rangeRemaining = entry.rangeRemaining {
        VStack(spacing: 0) {
          Text(String(format: "%.0f", rangeRemaining))
#if os(watchOS)
            .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 18 : 20))
#else
            .font(.system(size: 22))
#endif
            .bold()
          Text(Locale.current.measurementSystem == .metric ? "km" : "mi")
#if os(watchOS)
            .font(.system(size: WKInterfaceDevice.current().screenBounds.width < 195 ? 12 : 14))
            .padding(.top, -2)
            .padding(.bottom, -14)
#else
            .font(.system(size: 16))
            .padding(.top, -2)
            .padding(.bottom, -16)
#endif
        }
      }
    }
    .padding(2.5)
  }
}

struct VehicleRangeWidget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetView(entry: VehicleRangeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: 80,
      rangeRemaining: 120
    ))
    .previewDevice("Apple Watch Series 8 (45mm)")
    .previewDisplayName("45mm")
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    WidgetView(entry: VehicleRangeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: 80,
      rangeRemaining: 120
    ))
    .previewDevice("Apple Watch Series 8 (41mm)")
    .previewDisplayName("41mm")
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
  }
}
