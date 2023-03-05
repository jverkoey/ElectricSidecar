import Foundation
import SwiftUI

struct ChargeView: View {
  var batteryLevel: Double?
  var isCharging: Bool?

  var allowsAnimation = false
  @State var pulseIsOn = true

  var body: some View {
    ZStack {
      if let batteryLevel, let batteryLevelFormatted, let isCharging, let chargeColor = BatteryStyle.batteryColor(for: batteryLevel) {
        // Gutter
        RadialProgressView(
          fillPercent: 1,
          color: chargeColor.opacity(0.2),
          lineWidth: lineWidth,
          fillRatio: fillRatio
        )

        // Fill
        RadialProgressView(
          fillPercent: batteryLevel * 0.01,
          color: pulseIsOn ? chargeColor : chargeColor.opacity(0.5),
          lineWidth: lineWidth,
          fillRatio: fillRatio
        )
        .animation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true), value: pulseIsOn)
        .onAppear {
          guard allowsAnimation, isCharging else {
            return
          }
          pulseIsOn = false
        }
        .widgetAccentable(true)

        VStack(spacing: 0) {
          Image(isCharging == true ? "taycan.charge" : "taycan")
            .font(.system(size: iconFontSize))
            .padding(.top, iconOffset)
            .unredacted()
          Text(batteryLevelFormatted)
            .fontDesign(.rounded)
            .font(.system(size: labelFontSize))
            .padding(.top, iconPadding)
            .unredacted()
        }
      } else {
        RadialProgressView(
          fillPercent: 1,
          color: .gray,
          lineWidth: lineWidth,
          fillRatio: fillRatio
        )
        Image("taycan")
          .foregroundColor(.gray)
          .font(.system(size: iconFontSize))
          .padding(.top, -5)
          .unredacted()
      }
    }
  }

  var iconFontSize: Double {
    switch formFactor() {
    case .phone:
      return 26
    case .watch45mm, .ultra49mm:
      return 24
    case .watch41mm:
      return 20
    }
  }

  var iconOffset: Double {
    switch formFactor() {
    case .phone:
      return 12
    case .watch45mm, .ultra49mm:
      return 9
    case .watch41mm:
      return 9
    }
  }

  var iconPadding: Double {
    switch formFactor() {
    case .phone:
      return 0
    case .watch45mm, .ultra49mm:
      return -2
    case .watch41mm:
      return -2
    }
  }

  var labelFontSize: Double {
    switch formFactor() {
    case .phone:
      return 14
    case .watch45mm, .ultra49mm:
      return 13
    case .watch41mm:
      return 12
    }
  }

  var lineWidth: Double {
    return circularComplicationLineWidth()
  }

  var fillRatio: Double {
    switch formFactor() {
    case .phone:
      if batteryLevel == 100 {
        // Give a bit of breathing room around the text
        return 0.67
      }
      return 0.7
    case .watch45mm, .ultra49mm:
      return 0.7
    case .watch41mm:
      return 0.65
    }
  }

  var batteryLevelFormatted: String? {
    guard let batteryLevel else {
      return nil
    }
    return String(format: "%.0f%%", batteryLevel)
  }
}

struct ChargeView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color.red  // For debugging layout.
      HStack {
        ChargeView(
          batteryLevel: 100,
          isCharging: true
        )
      }
    }
    .frame(width: circularComplicationSize().width,
           height: circularComplicationSize().height)
    .cornerRadius(circularComplicationSize().width / 2)
    .previewDisplayName("Valid")

    ZStack {
      HStack {
        ChargeView(
          batteryLevel: nil,
          isCharging: nil
        )
      }
    }
    .frame(width: circularComplicationSize().width,
           height: circularComplicationSize().height)
    .cornerRadius(circularComplicationSize().width / 2)
    .previewDisplayName("Nil state")
  }
}
