import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = scene as? UIWindowScene else {
      return
    }

    let window = UIWindow(windowScene: windowScene)
    self.window = window

    if AUTH_MODEL.email.isEmpty || AUTH_MODEL.password.isEmpty {
      let loginViewController = LoginViewController(email: AUTH_MODEL.email, password: AUTH_MODEL.password)
      loginViewController.delegate = self
      let navigation = UINavigationController(rootViewController: loginViewController)
      window.rootViewController = navigation
    } else {
      login()
    }

    window.makeKeyAndVisible()
  }
}

extension SceneDelegate: LoginViewControllerDelegate {
  func login() {
    guard let store = AUTH_MODEL.store else {
      return
    }
    let garageView = GarageView(store: store)
    let hostingController = UIHostingController(rootView: garageView)
    self.window?.rootViewController = hostingController

    Task {
      do {
        try await store.load()
      } catch {
        DispatchQueue.main.async {
          AUTH_MODEL.authenticationFailed()

          let loginViewController = LoginViewController(email: AUTH_MODEL.email, password: AUTH_MODEL.password)
          loginViewController.error = error
          loginViewController.delegate = self
          let navigation = UINavigationController(rootViewController: loginViewController)
          self.window?.rootViewController = navigation
        }
      }
    }
  }

  func loginViewController(_ loginViewController: LoginViewController, didLoginWithEmail email: String, password: String) {
    AUTH_MODEL.email = email
    AUTH_MODEL.password = password

    login()
  }
}
