import XCTest

final class WidgetUITests: UITestCase {
  func testVehicleCharge() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "vehicle-charge-widget"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(rootView.screenshot().image)
  }

  func testVehicleRange() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "vehicle-range-widget"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(rootView.screenshot().image)
  }
}
