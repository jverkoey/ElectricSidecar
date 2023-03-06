import Foundation
import WidgetKit

func reloadAllTimelines() {
  UserDefaults(suiteName: APP_GROUP_IDENTIFIER)!.synchronize()
  WidgetCenter.shared.reloadAllTimelines()
}
