import Foundation
import SwiftUI

struct VehicleErrorPage: View {
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

struct VehicleErrorPage_Previews: PreviewProvider {
  static var previews: some View {
    VehicleErrorPage(
      statusError: .constant(URLError(.badServerResponse)),
      emobilityError: .constant(URLError(.badServerResponse)),
      positionError: .constant(URLError(.badServerResponse))
    )
    .previewDisplayName("All errors")

    VehicleErrorPage(
      statusError: .constant(nil),
      emobilityError: .constant(nil),
      positionError: .constant(nil)
    )
    .previewDisplayName("No errors")

    VehicleErrorPage(
      statusError: .constant(URLError(.badServerResponse)),
      emobilityError: .constant(nil),
      positionError: .constant(nil)
    )
    .previewDisplayName("Status error")
  }
}
