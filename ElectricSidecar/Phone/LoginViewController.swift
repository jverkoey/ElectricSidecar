import UIKit
import SwiftUI
import WatchConnectivity

private final class ViewModel: ObservableObject {
  internal init(email: String, password: String) {
    self.email = email
    self.password = password
  }

  @Published var email: String
  @Published var password: String
  @Published var watchIsReachable: Bool = false
}

protocol LoginViewControllerDelegate: AnyObject {
  func loginViewController(_ loginViewController: LoginViewController, didLoginWithEmail email: String, password: String)
}

final class LoginViewController: UIViewController {
  weak var delegate: LoginViewControllerDelegate?

  init(email: String, password: String) {
    self.model = ViewModel(email: email, password: password)
    super.init(nibName: nil, bundle: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
      name: .activationDidComplete, object: nil
    )
    NotificationCenter.default.addObserver(
      self, selector: #selector(type(of: self).reachabilityDidChange(_:)),
      name: .reachabilityDidChange, object: nil
    )
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private let model: ViewModel
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    let loginView = LoginView2(model: model, didLogin: { [weak self] in
      guard let self else {
        return
      }
      self.delegate?.loginViewController(self, didLoginWithEmail: self.model.email, password: self.model.password)
    })
    let loginHostingController = UIHostingController(rootView: loginView)
    addChild(loginHostingController)
    loginHostingController.view.frame = view.bounds
    loginHostingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(loginHostingController.view)
    loginHostingController.didMove(toParent: self)

    NSLayoutConstraint.activate([
      loginHostingController.view.leadingAnchor.constraint(equalTo: view.readableContentGuide.leadingAnchor),
      loginHostingController.view.trailingAnchor.constraint(equalTo: view.readableContentGuide.trailingAnchor),
      loginHostingController.view.centerYAnchor.constraint(equalTo: view.readableContentGuide.centerYAnchor)
    ])
  }

  @objc func reachabilityDidChange(_ notification: Notification) {
    Logging.watchConnectivity.info("Reachability state: \(WCSession.default.isReachable)")

    var isReachable = false
    if WCSession.default.activationState == .activated {
      isReachable = WCSession.default.isReachable
    }
    model.watchIsReachable = isReachable

    if isReachable {
      WCSession.default.sendMessage(["request": "auth-credentials"]) { response in
        DispatchQueue.main.async {
          if let email = response["email"] as? String,
             let password = response["password"] as? String {
            if !email.isEmpty {
              self.model.email = email
            }
            if !password.isEmpty {
              self.model.password = password
            }
          }
        }
      }
    }
  }
}

struct LoginTextFieldStyle: TextFieldStyle {
  let shape = RoundedRectangle(cornerRadius: 4)
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(12)
      .background(.gray.opacity(0.05))
      .clipShape(shape)
      .overlay(
        shape
          .stroke(.gray.opacity(0.2), lineWidth: 1)
      )
  }
}

struct LoginButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding()
      .background(.tint)
      .foregroundColor(.white)
      .clipShape(Capsule())
  }
}

struct LoginView2: View {
  @ObservedObject fileprivate var model: ViewModel
  let didLogin: () -> Void

  var body: some View {
    VStack {
      TextField("Email", text: $model.email)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .multilineTextAlignment(.leading)
        .font(.body)
      SecureField("Password", text: $model.password)
        .textContentType(.password)
        .multilineTextAlignment(.leading)
      Button("Log in", action: didLogin)
        .disabled(model.email.isEmpty || model.password.isEmpty)
        .frame(maxWidth: .infinity)
        .buttonStyle(LoginButtonStyle())
      Spacer(minLength: 32)
      Text("If you already logged in on your watch, open the ElectricSidecar app on your watch to use your existing login credentials.")

      if model.watchIsReachable {
        Image(systemName: "applewatch.radiowaves.left.and.right")
      } else {
        Image(systemName: "applewatch.slash")
      }
    }
    .padding()
    .textFieldStyle(LoginTextFieldStyle())
  }
}

// MARK: - Previews

struct LoginView2_Previews: PreviewProvider {
  static var previews: some View {
    ContainerView()
  }

  struct ContainerView : View {
    @State var email: String = ""
    @State var password: String = ""

    var body: some View {
      LoginView2(model: ViewModel(email: "foo", password: "bar")) {
        print("Did login")
      }
    }
  }
}
