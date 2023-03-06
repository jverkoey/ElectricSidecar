import CachedAsyncImage
import Foundation
import PorscheConnect
import SwiftUI

struct VehiclePhotosPage: View {
  let vehicle: UIModel.Vehicle

  var body: some View {
    List {
      ForEach(vehicle.externalPhotos.filter { $0.size == 2 }) { camera in
        CachedAsyncImage(
          url: camera.url,
          urlCache: .imageCache,
          content: { image in
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          },
          placeholder: {
            ZStack {
              (vehicle.color ?? .gray)
                .aspectRatio(CGSize(width: CGFloat(camera.width), height: CGFloat(camera.height)),
                             contentMode: .fill)
              ProgressView()
            }
          }
        )
        .listRowBackground(Color.clear)
      }
    }
#if os(watchOS)
    .listStyle(.carousel)
#endif
  }
}
