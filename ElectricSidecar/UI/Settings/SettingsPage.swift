import Foundation
import SwiftUI

struct SettingsPage: View {
  @AppStorage("preferences", store: UserDefaults(suiteName: APP_GROUP_IDENTIFIER))
  var preferences = Preferences()

  var body: some View {
    List {
      Section("Widgets") {
        NavigationLink("Charge") {
          ChargeSettingsPage()
        }
      }
    }
    .navigationTitle("Settings")
  }
}

struct SettingsPage_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SettingsPage()
    }
  }
}
