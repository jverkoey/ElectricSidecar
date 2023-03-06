import Foundation
import SwiftUI
import WidgetKit

private final class Storage {
  var lastKnownCharge: Double?
  var lastKnownChargingState: Bool?
}

struct VehicleChargeTimelineEntry: TimelineEntry {
  let date: Date
  let chargeRemaining: Double?
  let isCharging: Bool?
}

struct VehicleChargeTimelineProvider: TimelineProvider {
  typealias Entry = VehicleChargeTimelineEntry

  private let storage = Storage()

  func placeholder(in context: Context) -> Entry {
    Entry(
      date: Date(),
      chargeRemaining: storage.lastKnownCharge ?? 100,
      isCharging: storage.lastKnownChargingState
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> ()) {
    if context.isPreview {
      completion(Entry(
        date: Date(),
        chargeRemaining: storage.lastKnownCharge ?? 100,
        isCharging: storage.lastKnownChargingState
      ))
    } else {
      completion(Entry(date: Date(), chargeRemaining: 100, isCharging: false))
    }
  }

  func vin(store: ModelStore) async throws -> String {
    guard !AUTH_MODEL.preferences.primaryVIN.isEmpty else {
      // Use the first vehicle as a default.
      let vehicleList = try await store.vehicleList()
      return vehicleList[0].vin
    }
    return AUTH_MODEL.preferences.primaryVIN
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    guard let store = AUTH_MODEL.store else {
      completion(Timeline(entries: [Entry(
        date: Date(),
        chargeRemaining: storage.lastKnownCharge,
        isCharging: storage.lastKnownChargingState
      )], policy: .after(.now.addingTimeInterval(60 * 30))))
      return
    }
    Task {
      do {
        let vin = try await vin(store: store)
        let emobility = try await store.emobility(for: vin)

        storage.lastKnownCharge = emobility.batteryChargeStatus.stateOfChargeInPercentage
        storage.lastKnownChargingState = emobility.isCharging
      } catch {
        Logging.network.error("Failed to update complication with error: \(error.localizedDescription)")
      }

      // Always provide a timeline, even if the update request failed.
      let timeline = Timeline(entries: [Entry(
        date: Date(),
        chargeRemaining: storage.lastKnownCharge,
        isCharging: storage.lastKnownChargingState
      )], policy: .after(.now.addingTimeInterval(60 * 30)))
      completion(timeline)
    }
  }
}
