import SwiftUI

struct LoginView: View {
  @State private var email: String
  @State private var password: String
  let didLogin: (String, String) -> Void

  init(email: String, password: String, didLogin: @escaping (String, String) -> Void) {
    self.email = email
    self.password = password
    self.didLogin = didLogin
  }

  var body: some View {
    VStack {
      TextField("Email", text: $email)
        .textContentType(.emailAddress)
        .textInputAutocapitalization(.never)
        .multilineTextAlignment(.center)
      SecureField("Password", text: $password)
        .textContentType(.password)
        .multilineTextAlignment(.center)
      Button("Log in") {
        didLogin(email, password)
      }
      .disabled(email.isEmpty || password.isEmpty)
    }
    .padding()
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

    ContainerView()
      .previewDevice(PreviewDevice(rawValue: "iPhone 14 Pro"))
      .previewDisplayName("iPhone 14 Pro")
  }

  struct ContainerView : View {
    var body: some View {
      LoginView(email: "", password: "") { email, password in
        print("Did login")
      }
    }
  }
}
