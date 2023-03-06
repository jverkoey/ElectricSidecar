import Foundation
import OSLog
import os

private let LOGGER_SUBSYSTEM = "com.featherless.electricsidecar.logging"

public final class Logging {
  public static let intents = Logger(subsystem: LOGGER_SUBSYSTEM, category: "intents")
  public static let network = Logger(subsystem: LOGGER_SUBSYSTEM, category: "network")
  public static let watchConnectivity = Logger(subsystem: LOGGER_SUBSYSTEM, category: "watch-connectivity")

  /// Returns log entries for ElectricSidecar that have occurred within the given timeIntervalSinceNow.
  static func latestEntries(timeIntervalSinceNow: TimeInterval = -60 * 60) -> [OSLogEntry] {
    let startTime = Date(timeIntervalSinceNow: timeIntervalSinceNow)
    guard let logStore = try? OSLogStore(scope: .currentProcessIdentifier) else {
      return []
    }
    let predicate = NSPredicate(format: "subsystem == %@", argumentArray: [LOGGER_SUBSYSTEM])
    let position = logStore.position(date: startTime)
    guard let entries = try? logStore.getEntries(at: position, matching: predicate) else {
      return []
    }
    return Array(entries)
  }
}
