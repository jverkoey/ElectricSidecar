import XCTest

final class AppUITests: UITestCase {

  func testDefaultLoginView() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "login-view"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(rootView.screenshot().image)
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
    try writeSnapshot(rootView.screenshot().image)
  }

  func testAllErrors() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "error-view"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(rootView.screenshot().image)
  }

  func testVehicleDetailsView() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "vehicle-details-view"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(rootView.screenshot().image)
  }

  func testVehicleClosedStatusView() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "vehicle-closed-status"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(rootView.screenshot().image)
  }
}
