#if !os(watchOS)
import ActivityKit
#endif
import CachedAsyncImage
import ClockKit
import Combine
import Foundation
import OSLog
import PorscheConnect
import SwiftUI
import WidgetKit

struct VehicleView: View {
  @SwiftUI.Environment(\.scenePhase) var scenePhase

  let vehicle: UIModel.Vehicle

  let statusPublisher: AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Status>, Never>
  let emobilityPublisher: AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Emobility>, Never>
  let positionPublisher: AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Position>, Never>

  @State var lastRefresh: Date = .now
  let refreshCallback: (Bool) async throws -> Void
  let lockCallback: () async throws -> Void
  let unlockCallback: () async throws -> Void

  @MainActor @State var status: UIModel.Vehicle.Status?
  @MainActor @State var emobility: UIModel.Vehicle.Emobility?
  @MainActor @State var position: UIModel.Vehicle.Position?
  @MainActor @State var statusError: Error?
  @MainActor @State var emobilityError: Error?
  @MainActor @State var positionError: Error?

  @MainActor @State var statusRefreshing: Bool = false
  @MainActor @State var emobilityRefreshing: Bool = false
  @MainActor @State var positionRefreshing: Bool = false

  @MainActor @State private var isRefreshing = false
  @MainActor @State private var isChangingLockState = false

  var body: some View {
    List {
      Section {
        if isRefreshing {
          RefreshStatusView(
            statusRefreshing: $statusRefreshing,
            emobilityRefreshing: $emobilityRefreshing,
            positionRefreshing: $positionRefreshing
          )
          .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
        } else {
          Button("Refresh") {
            Task {
              try await refresh(ignoreCache: true)
            }
          }
        }
      } header: {
        VStack(alignment: .center) {
          ZStack {
            //          ZStack {
            //            if !isChangingLockState {
            //              Button { unlock() } label: { Image(systemName: "lock.open") }
            //                .font(.title3)
            //            } else {
            //              ProgressView()
            //            }
            //          }
            //          .padding(.trailing)

            HStack {
              Spacer()
                .frame(maxWidth: .infinity)
              VStack {
                ChargeView(
                  batteryLevel: status?.batteryLevel,
                  isCharging: emobility?.isCharging,
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
                Button { lock() } label: { Image(systemName: "lock") }
                  .font(.title3)
                  .offset(x: 8)
                  .frame(width: 48, height: 48)
              } else {
                ProgressView()
              }
            }
          }
          if let electricalRange = status?.electricalRange {
            Text(electricalRange)
              .font(.system(size: 14))
              .padding(.top, -8)
          }
          VehicleClosedStatusView(doors: status?.doors)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        // Reset the section header styling that causes header text to be uppercased
        .textCase(.none)
      }
      
      Section {
        NavigationLink {
          VehicleLocationView(
            vehicleName: vehicle.licensePlate ?? vehicle.modelDescription,
            position: $position
          )
          .navigationTitle("Location")
        } label: {
          NavigationLinkContentView(imageSystemName: "location", title: "Location")
        }
        NavigationLink {
          VehicleDetailsView(
            status: $status,
            modelDescription: vehicle.modelDescription,
            modelYear: vehicle.modelYear,
            vin: vehicle.vin
          )
          .navigationTitle("Details")
        } label: {
          NavigationLinkContentView(imageSystemName: "info.circle", title: "More details")
        }
        NavigationLink {
          VehiclePhotosView(vehicle: vehicle)
            .navigationTitle("Photos")
        } label: {
          NavigationLinkContentView(imageSystemName: "photo.on.rectangle.angled", title: "Photos")
        }
        
        if statusError != nil || emobilityError != nil || positionError != nil {
          NavigationLink {
            VehicleErrorView(statusError: $statusError, emobilityError: $emobilityError, positionError: $positionError)
          } label: {
            NavigationLinkContentView(imageSystemName: "exclamationmark.triangle", title: "Errors")
          }
        }
      }
    }
    .onChange(of: scenePhase) { newPhase in
      if newPhase == .active, lastRefresh < .now.addingTimeInterval(-15 * 60) {
        Task {
          try await refresh(ignoreCache: true)
        }
      }
    }
    .onAppear {
      Task {
        try await refresh(ignoreCache: false)
      }
    }
    .onReceive(statusPublisher.receive(on: RunLoop.main)) { result in
      status = result.value
      statusError = result.error

      if result.value != nil || result.error != nil {
        statusRefreshing = false
      }

//      checkChargeStatus()
    }
    .onReceive(emobilityPublisher.receive(on: RunLoop.main)) { result in
      emobility = result.value
      emobilityError = result.error

      if result.value != nil || result.error != nil {
        emobilityRefreshing = false
      }

//      checkChargeStatus()
    }
    .onReceive(positionPublisher.receive(on: RunLoop.main)) { result in
      position = result.value
      positionError = result.error

      if result.value != nil || result.error != nil {
        positionRefreshing = false
      }
    }
  }

  @MainActor
  private func checkChargeStatus() {
    guard let status, let emobility else {
      return
    }
#if !os(watchOS)
    if #available(iOS 16.2, *) {
      if ActivityAuthorizationInfo().areActivitiesEnabled, emobility.isCharging {
        let initialContentState = ChargingActivityAttributes.ContentState(batteryPercent: status.batteryLevel)
        let activityAttributes = ChargingActivityAttributes()

        let activityContent = ActivityContent(
          state: initialContentState,
          staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: .now)!)

        do {
          let activity = try Activity.request(attributes: activityAttributes, content: activityContent)
          print("Requested a charging Live Activity \(String(describing: activity.id)).")
        } catch (let error) {
          print("Error requesting charging Live Activity \(error.localizedDescription).")
        }
      }
    }
#endif
  }

  static func formatted(chargeRemaining: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale.current
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 0
    return formatter.string(from: chargeRemaining as NSNumber)!
  }

  @MainActor
  private func unlock() {
    Task {
      Logging.network.info("Unlocking \(vehicle.vin, privacy: .private)")
      isChangingLockState = true
      defer {
        Task {
          await MainActor.run {
            isChangingLockState = false
          }
        }
      }
      try await unlockCallback()
    }
  }

  @MainActor
  private func lock() {
    Task {
      Logging.network.info("Locking \(vehicle.vin, privacy: .private)")
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

  @MainActor
  private func refresh(ignoreCache: Bool) async throws {
    isRefreshing = true
    statusRefreshing = true
    emobilityRefreshing = true
    positionRefreshing = true

    Task {
      defer {
        Task {
          await MainActor.run {
            withAnimation {
              statusRefreshing = false
              emobilityRefreshing = false
              positionRefreshing = false
              isRefreshing = false
            }
            Logging.network.info("Refreshing all widget timelines")
            WidgetCenter.shared.reloadAllTimelines()
          }
        }
      }
      try await refreshCallback(ignoreCache)
      lastRefresh = .now
    }
  }
}
