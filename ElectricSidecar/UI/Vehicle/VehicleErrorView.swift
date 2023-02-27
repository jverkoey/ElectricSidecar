import Foundation
import SwiftUI

struct VehicleErrorView: View {
  @Binding var statusError: Error?
  @Binding var emobilityError: Error?
  @Binding var positionError: Error?

  var body: some View {
    List {
      if let statusError {
        Section("Status failed") {
          Text(statusError.localizedDescription)
        }
      }
      if let emobilityError {
        Section("Emobility failed") {
          Text(emobilityError.localizedDescription)
        }
      }
      if let positionError {
        Section("Location failed") {
          Text(positionError.localizedDescription)
        }
      }
    }
  }
}

struct VehicleErrorView_Previews: PreviewProvider {
  static var previews: some View {
    VehicleErrorView(
      statusError: .constant(URLError(.badServerResponse)),
      emobilityError: .constant(URLError(.badServerResponse)),
      positionError: .constant(URLError(.badServerResponse))
    )
    .previewDevice("Apple Watch Series 8 (45mm)")
    .previewDisplayName("All errors")

    VehicleErrorView(
      statusError: .constant(nil),
      emobilityError: .constant(nil),
      positionError: .constant(nil)
    )
    .previewDevice("Apple Watch Series 8 (45mm)")
    .previewDisplayName("No errors")

    VehicleErrorView(
      statusError: .constant(URLError(.badServerResponse)),
      emobilityError: .constant(nil),
      positionError: .constant(nil)
    )
    .previewDevice("Apple Watch Series 8 (45mm)")
    .previewDisplayName("Status error")
  }
}
