import Foundation
import SwiftUI
import WidgetKit

struct ChargeSettingsPage: View {
  @AppStorage("preferences", store: UserDefaults(suiteName: APP_GROUP_IDENTIFIER))
  var preferences = Preferences()

  @State var batteryLevel: Double = 50
  @State var isCharging: Bool = true
  var body: some View {
    List {
      Section {
        HStack {
#if !os(watchOS)
          Text("Layout")
          Spacer(minLength: 24)
#endif
          Picker("Layout", selection: $preferences.chargeWidget.circularLayout) {
            ForEach(ChargeWidgetPreferences.CircularLayout.allCases, id: \.self) { item in
              switch item {
              case .chargeStateInCenter:
                Text("Charge state")
              case .percentInCenter:
                Text("Percent")
              }
            }
          }
          .onChange(of: preferences.chargeWidget.circularLayout) { tag in
            reloadAllTimelines()
          }
#if !os(watchOS)
          .pickerStyle(.segmented)
#endif
        }
      } header: {
        VStack(alignment: .leading) {
          HStack {
            Spacer()
            ChargeView(
              batteryLevel: batteryLevel,
              isCharging: isCharging,
              layout: preferences.chargeWidget.circularLayout
            )
            .frame(width: circularComplicationSize().width,
                   height: circularComplicationSize().height)
            .cornerRadius(circularComplicationSize().width / 2)
            Spacer()
          }
          Text("Options")
        }
      }

      Section("Simulator") {
        HStack {
#if os(watchOS)
          Image(systemName: "bolt")
            .foregroundColor(.primary)
#else
          Text("Charge")
            .foregroundColor(.primary)
          Spacer(minLength: 24)
#endif
          Slider(value: $batteryLevel, in: 0...100) {
            Text("Charge")
          } minimumValueLabel: {
            Text("0")
              .foregroundColor(.secondary)
          } maximumValueLabel: {
            Text("100")
              .foregroundColor(.secondary)
          }
        }
        HStack {
          Toggle("Is charging", isOn: $isCharging)
            .foregroundColor(.primary)
        }
      }
    }
    .navigationTitle("Charge widget")
  }
}

struct ChargeSettingsPage_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ChargeSettingsPage()
    }
  }
}
