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
  let hasManyVehicles: Bool

  @AppStorage("preferences", store: UserDefaults(suiteName: APP_GROUP_IDENTIFIER))
  var preferences = Preferences()

  let statusPublisher: AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Status>, Never>
  let emobilityPublisher: AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Emobility>, Never>
  let positionPublisher: AnyPublisher<UIModel.Refreshable<UIModel.Vehicle.Position>, Never>

  @State var lastRefresh: Date = .now
  let refreshCallback: (Bool) async throws -> Void
  let lockCallback: () async throws -> Void
  let climatizationCallback: (Bool) async throws -> Void

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
        ControlPanelView(
          vin: vehicle.vin,
          batteryLevel: status?.batteryLevel,
          isCharging: emobility?.isCharging,
          isClimatizationEnabled: emobility?.isClimatizationEnabled,
          climatizationCompletionDate: emobility?.climatizationCompletionDate,
          chargeLayout: preferences.chargeWidget.circularLayout,
          electricalRange: status?.electricalRange,
          doors: status?.doors,
          lockCallback: lockCallback,
          climatizationCallback: climatizationCallback
        )
        // Reset the section header styling that causes header text to be uppercased
        .textCase(.none)
      }

      if hasManyVehicles {
        Section {
          Toggle("Primary", isOn: Binding<Bool>(
            get: {
              return AUTH_MODEL.preferences.primaryVIN == vehicle.vin
            },
            set: {
              if $0 {
                AUTH_MODEL.preferences.primaryVIN = vehicle.vin
                reloadAllTimelines()
              }
            }
          ))
        }
      }

      Section {
        NavigationLink {
          VehicleLocationPage(
            vehicleName: vehicle.licensePlate ?? vehicle.modelDescription,
            position: $position
          )
          .navigationTitle("Location")
        } label: {
          NavigationLinkContentView(imageSystemName: "location", title: "Location")
        }
        NavigationLink {
          VehicleDetailsPage(
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
          VehiclePhotosPage(vehicle: vehicle)
            .navigationTitle("Photos")
        } label: {
          NavigationLinkContentView(imageSystemName: "photo.on.rectangle.angled", title: "Photos")
        }
        
        if statusError != nil || emobilityError != nil || positionError != nil {
          NavigationLink {
            VehicleErrorPage(statusError: $statusError, emobilityError: $emobilityError, positionError: $positionError)
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
            reloadAllTimelines()
          }
        }
      }
      try await refreshCallback(ignoreCache)
      lastRefresh = .now
    }
  }
}
