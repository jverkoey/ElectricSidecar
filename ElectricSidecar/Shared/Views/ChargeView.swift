import Foundation
import SwiftUI

struct ChargeView: View {
  var batteryLevel: Double?
  var isCharging: Bool?
  var layout: ChargeWidgetPreferences.CircularLayout = .chargeStateInCenter

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

        switch layout {
        case .chargeStateInCenter:
          VStack(spacing: 0) {
            Spacer().frame(maxHeight: .infinity)
            Image(isCharging == true ? "taycan.charge" : "taycan")
              .font(.system(size: primaryFontSize))
              .fontWeight(.medium)
              .offset(primaryOffset)
              .unredacted()
            Spacer().frame(maxHeight: .infinity)
          }
          VStack(spacing: 0) {
            Spacer().frame(maxHeight: .infinity)
            Text(batteryLevelFormatted)
              .fontDesign(.rounded)
              .fontWeight(.medium)
              .font(.system(size: secondaryFontSize))
              .offset(secondaryOffset)
              .unredacted()
          }
        case .percentInCenter:
          VStack(spacing: 0) {
            Spacer().frame(maxHeight: .infinity)
            Text(batteryLevelFormatted)
              .font(.system(size: primaryFontSize))
              .fontDesign(.rounded)
              .bold()
              .offset(primaryOffset)
              .unredacted()
            Spacer().frame(maxHeight: .infinity)
          }
          VStack(spacing: 0) {
            Spacer().frame(maxHeight: .infinity)
            Image(isCharging == true ? "taycan.charge" : "taycan")
              .font(.system(size: secondaryFontSize))
              .fontWeight(.medium)
              .offset(secondaryOffset)
              .unredacted()
          }
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
          .font(.system(size: iconInCenterFontSize))
          .fontWeight(.medium)
          .offset(primaryOffset)
          .unredacted()
      }
    }
  }

  private var iconInCenterFontSize: Double {
    switch formFactor() {
    case .phone:
      return 26
    case .ultra49mm, .watch45mm:
      return 24
    case .watch44mm:
      return 22
    case .watch41mm, .watch40mm:
      return 20
    }
  }

  var primaryFontSize: Double {
    switch layout {
    case .chargeStateInCenter:
      return iconInCenterFontSize
    case .percentInCenter:
      switch formFactor() {
      case .phone:
        return 22
      case .ultra49mm, .watch45mm:
        return 20
      case .watch44mm, .watch41mm, .watch40mm:
        return 18
      }
    }
  }

  var secondaryFontSize: Double {
    switch layout {
    case .chargeStateInCenter:
      switch formFactor() {
      case .phone:
        return 14
      case .ultra49mm, .watch45mm, .watch44mm:
        return 13
      case .watch41mm:
        return 12
      case .watch40mm:
        return 11
      }
    case .percentInCenter:
      switch formFactor() {
      case .phone:
        return 16
      case .ultra49mm, .watch45mm, .watch44mm, .watch41mm:
        return 14
      case .watch40mm:
        return 12
      }
    }
  }

  var primaryOffset: CGSize {
    return CGSize(width: 0, height: -2)
  }

  var secondaryOffset: CGSize {
    switch layout {
    case .chargeStateInCenter:
      return CGSize(width: 0, height: formFactor() == .phone ? -1 : -0.5)
    case .percentInCenter:
      return CGSize(width: 0, height: -1)
    }
  }

  var lineWidth: Double {
    return circularComplicationLineWidth()
  }

  var fillRatio: Double {
    switch formFactor() {
    case .phone:
      if layout == .chargeStateInCenter && is100Percent {
        // Give a bit of breathing room around the text
        return 0.67
      }
      return 0.7
    case .watch45mm, .ultra49mm:
      return 0.7
    case .watch44mm:
      if layout == .chargeStateInCenter && is100Percent {
        // Give a bit of breathing room around the text
        return 0.67
      }
      return 0.7
    case .watch41mm:
      return 0.65
    case .watch40mm:
      return 0.65
    }
  }

  var is100Percent: Bool {
    guard let batteryLevel else {
      return false
    }
    return String(format: "%.0f%", batteryLevel) == "100"
  }

  var batteryLevelFormatted: String? {
    guard let batteryLevel else {
      return nil
    }
    switch layout {
    case .chargeStateInCenter:
      return String(format: "%.0f%%", batteryLevel)
    case .percentInCenter:
      return String(format: "%.0f%", batteryLevel)
    }
  }
}

struct ChargeView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      HStack {
        ZStack {
//          Color.red  // For debugging layout.
          ChargeView(
            batteryLevel: 50,
            isCharging: false,
            layout: .chargeStateInCenter
          )
        }
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
        .cornerRadius(circularComplicationSize().width / 2)
        ZStack {
//          Color.red  // For debugging layout.
          ChargeView(
            batteryLevel: 100,
            isCharging: true,
            layout: .chargeStateInCenter
          )
        }
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
        .cornerRadius(circularComplicationSize().width / 2)
      }
      HStack {
        ZStack {
//          Color.red  // For debugging layout.
          ChargeView(
            batteryLevel: 50,
            isCharging: true,
            layout: .percentInCenter
          )
        }
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
        .cornerRadius(circularComplicationSize().width / 2)
        ZStack {
//          Color.red  // For debugging layout.
          ChargeView(
            batteryLevel: 100,
            isCharging: false,
            layout: .percentInCenter
          )
        }
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
        .cornerRadius(circularComplicationSize().width / 2)
      }
      HStack {
        ZStack {
          //          Color.red  // For debugging layout.
          ChargeView(
            batteryLevel: nil,
            isCharging: nil,
            layout: .chargeStateInCenter
          )
        }
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
        .cornerRadius(circularComplicationSize().width / 2)
        ZStack {
          //          Color.red  // For debugging layout.
          ChargeView(
            batteryLevel: nil,
            isCharging: nil,
            layout: .percentInCenter
          )
        }
        .frame(width: circularComplicationSize().width,
               height: circularComplicationSize().height)
        .cornerRadius(circularComplicationSize().width / 2)
      }
    }
  }
}
