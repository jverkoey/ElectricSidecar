import Foundation
import SwiftUI

struct RangeView: View {
  var batteryLevel: Double?
  var rangeRemaining: Double?

  var allowsAnimation = false
  @State var pulseIsOn = true

  var body: some View {
    ZStack {
      // Gutter
      RadialProgressView(
        fillPercent: 1,
        color: batteryColor.opacity(0.2),
        lineWidth: circularComplicationLineWidth(),
        fillRatio: fillRatio
      )
      if let batteryLevel {
        RadialProgressView(
          fillPercent: batteryLevel * 0.01,
          color: batteryColor,
          lineWidth: circularComplicationLineWidth(),
          fillRatio: fillRatio
        )
        .widgetAccentable(true)
      }
      if let rangeRemaining {
        VStack(spacing: 0) {
          Text(String(format: "%.0f", rangeRemaining))
            .font(.system(size: primaryFontSize))
            .fontDesign(.rounded)
            .bold()
            .unredacted()
          Text(Locale.current.measurementSystem == .metric ? "km" : "mi")
            .font(.system(size: secondaryFontSize))
            .fontWeight(.medium)
            .padding(.top, labelTopPadding)
            .padding(.bottom, labelBottomPadding)
            .unredacted()
        }
      } else {
        Text(Locale.current.measurementSystem == .metric ? "km" : "mi")
          .font(.system(size: secondaryFontSize))
          .fontWeight(.medium)
          .padding(.top, labelTopPadding + 20)
          .padding(.bottom, labelBottomPadding)
          .foregroundColor(.gray)
          .unredacted()
      }
    }
  }

  var primaryFontSize: Double {
    switch formFactor() {
    case .phone:
      return 22
    case .watch45mm, .ultra49mm, .watch44mm:
      return 20
    case .watch41mm, .watch40mm:
      return 18
    }
  }

  var secondaryFontSize: Double {
    switch formFactor() {
    case .phone:
      return 16
    case .watch45mm, .ultra49mm:
      return 14.5
    case .watch44mm:
      return 13
    case .watch41mm:
      return 12.5
    case .watch40mm:
      return 12
    }
  }

  var labelTopPadding: Double {
    switch formFactor() {
    case .phone:
      return -2
    case .watch45mm, .ultra49mm:
      return -2
    case .watch44mm:
      return -2
    case .watch41mm:
      return -2
    case .watch40mm:
      return -2
    }
  }

  var labelBottomPadding: Double {
    switch formFactor() {
    case .phone:
      return -16
    case .watch45mm, .ultra49mm:
      return -14
    case .watch44mm:
      return -14
    case .watch41mm:
      return -14
    case .watch40mm:
      return -14
    }
  }

  var lineWidth: Double {
    return circularComplicationLineWidth()
  }

  var fillRatio: Double {
    return 0.7
  }

  var batteryColor: Color {
    return BatteryStyle.batteryColor(for: batteryLevel)
  }
}

struct RangeView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
//      Color.red  // For debugging layout.
      HStack {
        RangeView(
          batteryLevel: 50,
          rangeRemaining: 250
        )
      }
    }
    .frame(width: circularComplicationSize().width,
           height: circularComplicationSize().height)
    .cornerRadius(circularComplicationSize().width / 2)
    .previewDisplayName("Valid")

    ZStack {
//      Color.red  // For debugging layout.
      HStack {
        RangeView(
          batteryLevel: nil,
          rangeRemaining: nil
        )
      }
    }
    .frame(width: circularComplicationSize().width,
           height: circularComplicationSize().height)
    .cornerRadius(circularComplicationSize().width / 2)
    .previewDisplayName("Nil state")
  }
}
