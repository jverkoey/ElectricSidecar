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

struct VehicleRangeWidgetUITestView: View {
  var body: some View {
    VStack {
      HStack {
        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 0,
          rangeRemaining: 0
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 12,
          rangeRemaining: 20
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 35,
          rangeRemaining: 50
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)
      }
      HStack {
        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 50,
          rangeRemaining: 100
        ))
        .frame(width: circularComplicationSize().width, height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 84,
          rangeRemaining: 180
        ))
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)

        WidgetView(entry: VehicleRangeTimelineProvider.Entry(
          date: Date(),
          chargeRemaining: 100,
          rangeRemaining: 250
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
