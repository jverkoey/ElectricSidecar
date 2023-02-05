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
            if AUTH_MODEL.email.isEmpty || AUTH_MODEL.password.isEmpty {
              authState = .loggedOut(error: nil)
            } else {
              let store = ModelStore(username: AUTH_MODEL.email, password: AUTH_MODEL.password)
              Task {
                try await store.load()
              }
              authState = .authenticated(store: store)
            }
          }
      case .authenticated(let store):
        GarageView(store: store) { error in
          authState = .loggedOut(error: error)
        }
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
