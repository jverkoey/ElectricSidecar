import Intents

class IntentHandler: INExtension, SelectVehicleIntentHandling {
  func provideVehicleOptionsCollection(for intent: SelectVehicleIntent) async throws -> INObjectCollection<IntentVehicle> {
    Logging.intents.info("provideVehicleOptionsCollection")
    guard let store = AUTH_MODEL.store else {
      Logging.intents.info("No store available, returning nothing")
      return INObjectCollection(items: [])
    }
    Logging.intents.info("Fetching vehicles")
    let vehicleList = try await store.vehicleList()
    let vehicles = vehicleList.map { IntentVehicle(identifier: $0.vin, display: $0.licensePlate ?? $0.modelDescription) }
    Logging.intents.info("Returning vehicles \(vehicles.count)")
    return INObjectCollection(items: vehicles)
  }

  override func handler(for intent: INIntent) -> Any {
    return self
  }
}

