import XCTest

final class AuthUIFlowTests: XCTestCase {

  override func setUpWithError() throws {
    continueAfterFailure = true
  }

  var app: XCUIApplication!
  override func setUp() {
    super.setUp()

    app = XCUIApplication()
    app.launchEnvironment = ["TESTING": "1"]
    app.launch()
  }

  func testLoginButtonEnablesOnceUsernameAndPasswordAreEntered() throws {
    XCTAssertFalse(app.buttons["Log in"].isEnabled)

    app.textFields["Email"].tap()
    app.textViews.firstMatch.typeText("test@gmail.com")
    app.buttons["Done"].tap()

    XCTAssertFalse(app.buttons["Log in"].isEnabled)

    app.secureTextFields["Password"].tap()
    app.textViews.firstMatch.typeText("abc")
    app.buttons["Done"].tap()

    XCTAssertTrue(app.buttons["Log in"].isEnabled)
  }
}
