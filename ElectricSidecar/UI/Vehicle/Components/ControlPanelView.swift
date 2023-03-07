import Foundation
import SwiftUI

struct ControlPanelView: View {
  var vin: String
  var batteryLevel: Double?
  var isCharging: Bool?
  var isClimatizationEnabled: Bool?
  var climatizationCompletionDate: Date?
  var chargeLayout: ChargeWidgetPreferences.CircularLayout
  var electricalRange: String?
  var doors: UIModel.Vehicle.Doors?
  let lockCallback: () async throws -> Void
  let climatizationCallback: (Bool) async throws -> Void

  @State private var minutesUntilClimatizationCompletes: String = "..."
  @State private var climatizationTimer: Timer?
  @MainActor @State private var isChangingClimatizationState = false
  @MainActor @State private var isChangingLockState = false

  var body: some View {
    VStack(alignment: .center) {
      ZStack {
        if let isClimatizationEnabled {
          HStack(spacing: 0) {
            if !isChangingClimatizationState {
              ZStack {
                Button {
                  climatization(enable: !isClimatizationEnabled)
                } label: {
                  Image("climatization")
                    .frame(width: 48, height: 48)
                }
                .font(.title3)
                .overlay(
                  RoundedRectangle(cornerRadius: 24)
                    .stroke(isClimatizationEnabled ? Color.green : Color.accentColor, lineWidth: 2)
                )
                if isClimatizationEnabled {
                  VStack {
                    Spacer()
                    HStack {
                      Spacer()
                      Text("\(minutesUntilClimatizationCompletes)")
                        .foregroundColor(.black)
                        .fontDesign(.rounded)
                        .fontWeight(.semibold)
                        .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        .background(.green)
                        .cornerRadius(4)
                        .onAppear {
                          climatizationTimer?.invalidate()
                          let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                            recomputeClimatizationTime()
                          }
                          climatizationTimer = timer
                          RunLoop.current.add(timer, forMode: .common)
                          recomputeClimatizationTime()
                        }
                    }
                  }
                  .offset(x: 8)
                }
              }
              .offset(x: -8)
              .frame(width: 48, height: 48)
            } else {
              ProgressView()
            }
            Spacer()
              .frame(maxWidth: .infinity)
          }
        }

        HStack {
          Spacer()
            .frame(maxWidth: .infinity)
          VStack {
            ChargeView(
              batteryLevel: batteryLevel,
              isCharging: isCharging,
              layout: chargeLayout,
              allowsAnimation: true
            )
            .frame(width: circularComplicationSize().width,
                   height: circularComplicationSize().height)
            .padding(.top, 8)
          }
          Spacer()
            .frame(maxWidth: .infinity)
        }

        HStack(spacing: 0) {
          Spacer()
            .frame(maxWidth: .infinity)
          if !isChangingLockState {
            Button {
              lock()
            } label: {
              Image(systemName: "lock")
                .frame(width: 48, height: 48)
            }
            .overlay(
              RoundedRectangle(cornerRadius: 24)
                .stroke(Color.accentColor, lineWidth: 2)
            )
            .font(.title3)
            .offset(x: 8)
            .frame(width: 48, height: 48)
          } else {
            ProgressView()
          }
        }
      }
      if let electricalRange {
        Text(electricalRange)
          .font(.system(size: 14))
          .padding(.top, -6)
      }
      VehicleClosedStatusView(doors: doors)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
  }

  func recomputeClimatizationTime() {
    guard let climatizationCompletionDate else {
      climatizationTimer?.invalidate()
      climatizationTimer = nil
      return
    }
    let calendar = Calendar.current
    let components = calendar.dateComponents([.minute], from: .now, to: climatizationCompletionDate)
    guard let minutesRemaining = components.minute else {
      climatizationTimer?.invalidate()
      climatizationTimer = nil
      return
    }
    minutesUntilClimatizationCompletes = "\(minutesRemaining)"
  }

  @MainActor
  private func climatization(enable: Bool) {
    Task {
      Logging.network.info("Toggling climatization \(vin, privacy: .private)")
      isChangingClimatizationState = true
      defer {
        Task {
          await MainActor.run {
            isChangingClimatizationState = false
          }
        }
      }
      try await climatizationCallback(enable)
    }
  }

  @MainActor
  private func lock() {
    Task {
      Logging.network.info("Locking \(vin, privacy: .private)")
      isChangingLockState = true
      defer {
        Task {
          await MainActor.run {
            isChangingLockState = false
          }
        }
      }
      try await lockCallback()
    }
  }

}

struct ControlPanelView_Previews: PreviewProvider {
  static var previews: some View {
    List {
      Section {
        Text("")
      } header: {
        ControlPanelView(
          vin: "WP0AB1C23DEF11111",
          batteryLevel: 50,
          isCharging: true,
          isClimatizationEnabled: true,
          climatizationCompletionDate: Date(timeIntervalSinceNow: 30 * 60),
          chargeLayout: .chargeStateInCenter,
          electricalRange: "100 miles",
          doors: UIModel.Vehicle.Doors(
            frontLeft: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true),
            frontRight: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true),
            backLeft: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true),
            backRight: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true),
            frontTrunk: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true),
            backTrunk: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true),
            overallLockStatus: UIModel.Vehicle.Doors.Status(isLocked: false, isOpen: true)
          ),
          lockCallback: {
            print("Lock")
          },
          climatizationCallback: { enable in
            print("Climatization")
          }
        ).textCase(.none)
      }
    }
  }
}
