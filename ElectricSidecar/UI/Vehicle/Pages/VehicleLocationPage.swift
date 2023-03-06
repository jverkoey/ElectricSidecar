import Foundation
import PorscheConnect
import MapKit
import SwiftUI

private struct VehicleLocation: Identifiable {
  let id = UUID()
  var coordinate: CLLocationCoordinate2D
}

struct VehicleLocationPage: View {
  var vehicleName: String
  @Binding var position: UIModel.Vehicle.Position?
  var body: some View {
    if let position {
      Map(
        coordinateRegion: .constant(position.coordinateRegion),
        showsUserLocation: true,
        annotationItems: [
          VehicleLocation(coordinate: position.coordinateRegion.center)
        ]
      ) { item in
        MapMarker(coordinate: item.coordinate, tint: .red)
      }
      .aspectRatio(CGSize(width: 2, height: 1), contentMode: .fill)
      .onTapGesture {
        let placemark = MKPlacemark(coordinate: position.coordinateRegion.center, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = vehicleName
        mapItem.openInMaps(launchOptions: nil)
      }
    } else {
      ProgressView()
    }
  }
}

// Note: MapKit crashes SwiftUI previews so the only preview here
// is intentionally just checking the nil state.
struct VehicleLocationView_Previews: PreviewProvider {
  static var previews: some View {
    VehicleLocationPage(vehicleName: "Taycan", position: .constant(nil))
    .previewDevice("Apple Watch Series 8 (45mm)")
    .previewDisplayName("Series 8 45mm")
  }
}
