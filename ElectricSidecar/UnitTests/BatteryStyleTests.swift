import XCTest

final class BatteryStyleTests: XCTestCase {

  func testNil() throws {
    XCTAssertEqual(BatteryStyle.batteryColor(for: nil), .gray)
  }

  func testFull() throws {
    XCTAssertEqual(BatteryStyle.batteryColor(for: 100), .green)
  }

  func testThreeQuarters() throws {
    XCTAssertEqual(BatteryStyle.batteryColor(for: 75), .green)
  }

  func testHalf() throws {
    XCTAssertEqual(BatteryStyle.batteryColor(for: 50), .yellow)
  }

  func testOneQuarter() throws {
    XCTAssertEqual(BatteryStyle.batteryColor(for: 25), .orange)
  }

  func testEmpty() throws {
    XCTAssertEqual(BatteryStyle.batteryColor(for: 0), .red)
  }
}
