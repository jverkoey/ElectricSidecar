import Foundation
import PorscheConnect
import SwiftUI

struct ValueCell: View {
  var label: String
  var value: String

  var body: some View {
    HStack {
      Text(label)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .foregroundColor(.primary)
    }
  }
}

struct VehicleDetailsView: View {
  @Binding var status: UIModel.Vehicle.Status?
  var modelDescription: String
  var modelYear: String
  var vin: String

  var body: some View {
    List {
      if let status {
        ValueCell(label: "Mileage", value: "\(status.mileage)")
      }

      ValueCell(label: "Model", value: "\(modelDescription) (\(modelYear))")
      Section("VIN") {
        Text(vin)
#if !os(watchOS)
          .textSelection(.enabled)
#endif
      }
    }
  }
}

struct VehicleDetailsView_Previews: PreviewProvider {
  static let status = UIModel.Vehicle.Status(
    batteryLevel: 100,
    electricalRange: "100 miles",
    mileage: "100 miles",
    doors: UIModel.Vehicle.Doors(
      frontLeft: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
      frontRight: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
      backLeft: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
      backRight: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: true),
      frontTrunk: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: true),
      backTrunk: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: false),
      overallLockStatus: UIModel.Vehicle.Doors.Status(isLocked: true, isOpen: true)
    )
  )
  static var previews: some View {
    VehicleDetailsView(
      status: .constant(status),
      modelDescription: "Taycan",
      modelYear: "2022",
      vin: "WP0AB1C23DEF45678"
    )
  }
}
