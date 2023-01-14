import Foundation

extension PorscheConnect {

  public func checkStatus(
    vehicle: Vehicle, capabilities: Capabilities? = nil,
    remoteCommand: RemoteCommandAccepted
  ) async throws -> (
    status: RemoteCommandStatus?, response: HTTPURLResponse?
  ) {
    let headers = try await performAuthFor(application: .carControl)

    let result = try await networkClient.get(
      RemoteCommandStatus.self,
      url: urlForCommand(
        vehicle: vehicle, capabilities: capabilities, remoteCommand: remoteCommand),
      headers: headers, jsonKeyDecodingStrategy: .useDefaultKeys)
    return (status: result.data, response: result.response)
  }

  // MARK: - Private

  private func urlForCommand(
    vehicle: Vehicle, capabilities: Capabilities?, remoteCommand: RemoteCommandAccepted
  ) -> URL {
    switch remoteCommand.remoteCommand {
    case .honkAndFlash:
      return networkRoutes.vehicleHonkAndFlashRemoteCommandStatusURL(
        vin: vehicle.vin, remoteCommand: remoteCommand)
    case .toggleDirectCharge:
      return networkRoutes.vehicleToggleDirectChargingRemoteCommandStatusURL(
        vin: vehicle.vin, capabilities: capabilities, remoteCommand: remoteCommand)
    case .toggleDirectClimatisation:
      return networkRoutes.vehicleToggleDirectClimatisationRemoteCommandStatusURL(
        vin: vehicle.vin, remoteCommand: remoteCommand)
    case .lock, .unlock:
      return networkRoutes.vehicleLockUnlockRemoteCommandStatusURL(
        vin: vehicle.vin, remoteCommand: remoteCommand)
    case .none:
      return URL(string: kBlankString)!
    }
  }
}
