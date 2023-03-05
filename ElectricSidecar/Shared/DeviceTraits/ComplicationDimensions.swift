import Foundation
#if os(watchOS)
import WatchKit
#endif

public enum FormFactor {
  case watch41mm
  case watch45mm
  case ultra49mm
  case phone
}

public func formFactor() -> FormFactor {
#if os(watchOS)
  let deviceSize = WKInterfaceDevice.current().screenBounds.size
  switch deviceSize {
  case CGSize(width: 205, height: 251):
    return .ultra49mm
  case CGSize(width: 198, height: 242):
    return .watch45mm
  case CGSize(width: 176, height: 215):
    return .watch41mm
  default:
    fatalError("Unknown device size")
  }
#else
  return .phone
#endif
}

public func circularComplicationSize() -> CGSize {
  switch formFactor() {
  case .ultra49mm:
    return CGSize(width: 50, height: 50)
  case .watch45mm:
    return CGSize(width: 50, height: 50)
  case .watch41mm:
    return CGSize(width: 44.5, height: 44.5)
  case .phone:
    return CGSize(width: 58.5, height: 58.5)
  }
}
