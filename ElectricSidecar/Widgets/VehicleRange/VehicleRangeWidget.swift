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

  var body: some View {
    switch family {
    case .accessoryCircular:
      RangeView(
        batteryLevel: entry.chargeRemaining,
        rangeRemaining: entry.rangeRemaining
      )

    default:
      Text("Unsupported")
    }
  }
}

struct VehicleRangeWidget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetView(entry: VehicleRangeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: 80,
      rangeRemaining: 120
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    .previewDisplayName("Valid")

    WidgetView(entry: VehicleRangeTimelineProvider.Entry(
      date: Date(),
      chargeRemaining: nil,
      rangeRemaining: nil
    ))
    .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    .previewDisplayName("Nil")
  }
}
