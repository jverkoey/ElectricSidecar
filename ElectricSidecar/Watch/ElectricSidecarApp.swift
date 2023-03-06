import Combine
import SwiftUI
import WatchConnectivity

@main
struct ElectricSidecar: App {
  enum AuthState {
    case launching
    case loggedOut(error: Error?)
    case authenticated(store: ModelStore)
  }
  @State var authState: AuthState = .launching

  private let watchConnectivityDelegate = WatchConnectivityObserver()

  init() {
    WCSession.default.delegate = watchConnectivityDelegate
    WCSession.default.activate()
  }

  var body: some Scene {
    WindowGroup {
      switch authState {
      case .launching:
        ProgressView()
          .task {
            guard let store = AUTH_MODEL.store else {
              authState = .loggedOut(error: nil)
              return
            }
            Task {
              do {
                try await store.load()
              } catch {
                DispatchQueue.main.async {
                  AUTH_MODEL.authenticationFailed()
                  authState = .loggedOut(error: error)
                }
              }
            }
            authState = .authenticated(store: store)
          }
      case .authenticated(let store):
        GarageView(store: store)
      case .loggedOut(let error):
        ScrollView {
          VStack {
            if let error = error {
              Text(error.localizedDescription)
            }
            LoginView(email: AUTH_MODEL.email, password: AUTH_MODEL.password) { email, password in
              guard !email.isEmpty && !password.isEmpty else {
                return
              }
              AUTH_MODEL.email = email
              AUTH_MODEL.password = password
              guard let store = AUTH_MODEL.store else {
                return
              }
              Task {
                try await store.load()
              }
              authState = .authenticated(store: store)
            }
          }
        }
      }
    }
  }
}
