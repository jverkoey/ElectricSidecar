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

struct VehicleChargeTimelineProvider: IntentTimelineProvider {
  typealias Intent = SelectVehicleIntent
  typealias Entry = VehicleChargeTimelineEntry

  private let storage = Storage()

  func placeholder(in context: Context) -> Entry {
    Entry(
      date: Date(),
      chargeRemaining: storage.lastKnownCharge ?? 100,
      isCharging: storage.lastKnownChargingState
    )
  }

  func getSnapshot(for configuration: SelectVehicleIntent, in context: Context, completion: @escaping (Entry) -> ()) {
    Logging.widgets.info("VehicleCharge/getSnapshot preview: \(context.isPreview)")
    guard !context.isPreview else {
      completion(Entry(
        date: Date(),
        chargeRemaining: storage.lastKnownCharge ?? 100,
        isCharging: storage.lastKnownChargingState
      ))
      return
    }

    Logging.widgets.info("VehicleCharge/getSnapshot Task starting...")
    Task {
      let entry = await latestEntry(for: configuration)
      completion(entry)
      Logging.widgets.info("VehicleCharge/getSnapshot Completed.")
    }
  }

  func getTimeline(for configuration: SelectVehicleIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    Logging.widgets.info("VehicleCharge/getTimeline")
    Task {
      Logging.widgets.info("VehicleCharge/getTimeline: Task starting...")
      let entry = await latestEntry(for: configuration)
      let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(60 * 30)))
      completion(timeline)
      Logging.widgets.info("VehicleCharge/getTimeline: Completed.")
    }
  }

  func recommendations() -> [IntentRecommendation<SelectVehicleIntent>] {
    let intent = SelectVehicleIntent()
    intent.vehicle = IntentVehicle(identifier: "", display: "")
    return [
      IntentRecommendation(intent: intent, description: VehicleChargeWidget.configurationDisplayName)
    ]
  }

  private func latestEntry(for configuration: SelectVehicleIntent) async -> Entry {
    Logging.widgets.info("VehicleCharge/latestEntry: Start")
    guard let store = AUTH_MODEL.store else {
      Logging.widgets.info("VehicleCharge/latestEntry: No model store, returning last known state")
      return Entry(
        date: Date(),
        chargeRemaining: storage.lastKnownCharge,
        isCharging: storage.lastKnownChargingState
      )
    }
    do {
      Logging.widgets.info("VehicleCharge/latestEntry: Fetching vin...")
      let vin = try await vin(for: configuration, store: store)
      Logging.widgets.info("VehicleCharge/latestEntry: vin: \(vin) found, fetching emobility")
      let emobility = try await store.emobility(for: vin)

      Logging.widgets.info("VehicleCharge/latestEntry: Storing results...")
      storage.lastKnownCharge = emobility.batteryChargeStatus.stateOfChargeInPercentage
      storage.lastKnownChargingState = emobility.isCharging
    } catch {
      Logging.network.error("Failed to update complication with error: \(error.localizedDescription)")
    }
    Logging.widgets.info("VehicleCharge/latestEntry: Returning entry.")
    return Entry(
      date: Date(),
      chargeRemaining: storage.lastKnownCharge,
      isCharging: storage.lastKnownChargingState
    )
  }

  private func vin(for configuration: SelectVehicleIntent, store: ModelStore) async throws -> String {
    if let vin = configuration.vehicle?.identifier, !vin.isEmpty {
      return vin
    }
    guard !AUTH_MODEL.preferences.primaryVIN.isEmpty else {
      // Use the first vehicle as a default.
      let vehicleList = try await store.vehicleList()
      return vehicleList[0].vin
    }
    return AUTH_MODEL.preferences.primaryVIN
  }
}
