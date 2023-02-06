import SwiftUI
import WatchConnectivity

struct LoginView: View {
  @ObservedObject fileprivate var model = LoginModel()
  let didLogin: (String, String) -> Void

  init(email: String, password: String, didLogin: @escaping (String, String) -> Void) {
    self.didLogin = didLogin

    model.email = email
    model.password = password
  }

  var body: some View {
    VStack {
      TextField("Email", text: $model.email)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .multilineTextAlignment(.center)
        .font(.body)
      SecureField("Password", text: $model.password)
        .textContentType(.password)
        .multilineTextAlignment(.center)
      Button("Log in") {
        didLogin(model.email, model.password)
      }
      .disabled(model.email.isEmpty || model.password.isEmpty)
    }
    .padding()
  }
}

private final class LoginModel: ObservableObject {
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var watchIsReachable: Bool = false

  init() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(Self.reachabilityDidChange),
      name: .activationDidComplete, object: nil
    )
    NotificationCenter.default.addObserver(
      self, selector: #selector(Self.reachabilityDidChange),
      name: .reachabilityDidChange, object: nil
    )

    reachabilityDidChange()
  }

  @objc func reachabilityDidChange() {
    if ProcessInfo.processInfo.environment["TESTING"] == "1" {
      // Don't try to handle any reachability while testing.
      return
    }
    Logging.watchConnectivity.info("Reachability state: \(WCSession.default.isReachable)")

    var isReachable = false
    if WCSession.default.activationState == .activated {
      isReachable = WCSession.default.isReachable
    }
    watchIsReachable = isReachable

    if isReachable {
      Logging.watchConnectivity.info("Requesting auth credentials from the phone...")
      WCSession.default.sendMessage(["request": "auth-credentials"]) { response in
        DispatchQueue.main.async {
          Logging.watchConnectivity.info("Received response \(response, privacy: .sensitive)")
          if let email = response["email"] as? String,
             let password = response["password"] as? String {
            if !email.isEmpty {
              self.email = email
            }
            if !password.isEmpty {
              self.password = password
            }
          }
        }
      }
    }
  }
}

// MARK: - Previews

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    ContainerView()
      .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 8 (45mm)"))
      .previewDisplayName("Series 8 45mm")

    ContainerView()
      .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 8 (41mm)"))
      .previewDisplayName("Series 8 41mm")

    ContainerView()
      .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra (49mm)"))
      .previewDisplayName("Ultra 49mm")

    ContainerView()
      .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 (40mm)"))
      .previewDisplayName("Series 5 40mm")
  }

  struct ContainerView : View {
    var body: some View {
      LoginView(email: "", password: "") { email, password in
        print("Did login")
      }
    }
  }
}
