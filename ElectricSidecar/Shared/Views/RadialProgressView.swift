import Foundation
import SwiftUI

struct RadialProgressView: View {
  let fillPercent: Double
  let color: Color
  let lineWidth: Double
  var fillRatio: Double
  private var orientation: Angle {
    .degrees(-90 - fillRatio / 2.0 * 360)
  }

  var body: some View {
    Circle()
      .trim(from: 0, to: fillRatio * fillPercent)
      .stroke(color,
              style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
      .rotationEffect(orientation)
      .padding(lineWidth / 2)
  }
}

struct RadialProgressView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color.white
      RadialProgressView(
        fillPercent: 1,
        color: .red,
        lineWidth: 5,
        fillRatio: 0.7
      )
    }
    .frame(width: circularComplicationSize().width,
           height: circularComplicationSize().height)
  }
}
