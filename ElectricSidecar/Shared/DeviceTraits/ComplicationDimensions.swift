import Foundation
#if os(watchOS)
import WatchKit
#endif

public enum FormFactor {
  case ultra49mm
  case watch45mm
  case watch44mm
  case watch41mm
  case watch40mm
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
  case CGSize(width: 184, height: 224):
    return .watch44mm
  case CGSize(width: 176, height: 215):
    return .watch41mm
  case CGSize(width: 162, height: 197):
    return .watch40mm
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
  case .watch44mm:
    return CGSize(width: 47, height: 47)
  case .watch41mm:
    return CGSize(width: 44.5, height: 44.5)
  case .watch40mm:
    return CGSize(width: 42, height: 42)
  case .phone:
    return CGSize(width: 58.5, height: 58.5)
  }
}

public func circularComplicationLineWidth() -> Double {
  switch formFactor() {
  case .phone:
    return 6
  case .watch45mm, .ultra49mm:
    return 5
  case .watch44mm:
    return 5
  case .watch41mm:
    return 5
  case .watch40mm:
    return 4
  }
}
