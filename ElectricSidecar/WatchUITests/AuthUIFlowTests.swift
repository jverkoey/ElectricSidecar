import XCTest
import SnapshotTesting

final class AuthUIFlowTests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  var app: XCUIApplication!
  override func setUp() {
    super.setUp()

    isRecording = true

    app = XCUIApplication()
    app.launchEnvironment = ["TESTING": "1"]
    app.launch()
  }

  func testLoginButtonEnablesOnceUsernameAndPasswordAreEntered() throws {
    let screenshot: UIImage = app.screenshot().image
    assertSnapshot(matching: screenshot, as: .image)

    XCTAssertFalse(app.buttons["Log in"].isEnabled)

    app.textFields["Email"].tap()
    app.keys["t"].tap()
    app.keys["more"].tap()
    app.keys["@"].tap()
    app.keys["more"].tap()
    app.keys["g"].tap()
    app.keys["more"].tap()
    app.keys["."].tap()
    app.keys["more"].tap()
    app.keys["c"].tap()
    app.keys["o"].tap()
    app.buttons["Done"].tap()

    XCTAssertFalse(app.buttons["Log in"].isEnabled)

    app.secureTextFields["Password"].tap()
    app.keys["a"].tap()
    app.keys["b"].tap()
    app.keys["c"].tap()
    app.buttons["Done"].tap()

    XCTAssertTrue(app.buttons["Log in"].isEnabled)
    app.buttons["Log in"].tap()
  }
}

