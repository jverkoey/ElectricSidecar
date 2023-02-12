import SnapshotTesting
import XCTest

final class LoginViewUITests: XCTestCase {

  var testEnvironment: String = "Undefined"
  var app: XCUIApplication!
  override func setUpWithError() throws {
    continueAfterFailure = true

    testEnvironment = ProcessInfo.processInfo.environment["TEST_ENVIRONMENT"] ?? "Undefined"
    isRecording = ProcessInfo.processInfo.environment["IS_RECORDING"] == "true"

    app = XCUIApplication()
  }

  override func tearDownWithError() throws {
    app.terminate()
  }

  func testDefaultLoginView() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "login-view"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try assertSnapshot(matching: sanitizedSnapshot(rootView.screenshot().image), as: .image,
                       testName: "\(#function)_\(testEnvironment)")
  }

  func testLoginViewWithEmailAndPassword() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "login-view",
      "email": "test@gmail.com",
      "password": "abc",
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try assertSnapshot(matching: sanitizedSnapshot(rootView.screenshot().image), as: .image,
                       testName: "\(#function)_\(testEnvironment)")
  }

  private func sanitizedSnapshot(_ image: UIImage) throws -> UIImage {
    UIGraphicsBeginImageContext(image.size)
    image.draw(at: CGPoint.zero)
    guard let context = UIGraphicsGetCurrentContext() else {
      throw FailedToGetCurrentGraphicsContext()
    }
    let statusBarHeight = app.statusBars.firstMatch.frame.height
    let path = UIBezierPath(rect: CGRect(x: image.size.width - 70, y: 0, width: 70, height: statusBarHeight))
    context.addPath(path.cgPath)
    context.clip()
    UIColor.black.setFill()
    context.fill(CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
      throw FailedToGetGetImageFromCurrentContext()
    }
    UIGraphicsEndImageContext()
    return newImage
  }
}

private final class FailedToGetCurrentGraphicsContext: Error {
}

private final class FailedToGetGetImageFromCurrentContext: Error {
}
