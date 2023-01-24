import XCTest

@testable import PorscheConnect

final class StatusFormatterTests: XCTestCase {

  var formatter: StatusFormatter!
  override func setUp() {
    formatter = StatusFormatter()
  }

  override func tearDown() {
    formatter = nil
  }

  // MARK: - Defaults

  func testDefaultLocaleIsCurrent() {
    XCTAssertEqual(formatter.locale, .current)
  }

  // MARK: - Specific locales

  func testAmericanEnglishFormatting() {
    formatter.locale = Locale(identifier: "en_US")
    XCTAssertEqual(formatter.batteryLevel(from: templateStatus), "12%")
    XCTAssertEqual(formatter.mileage(from: templateStatus), "1,364 mi")
    XCTAssertEqual(formatter.electricalRange(from: templateStatus), "183 mi")
  }

  func testCanadianEnglishFormatting() {
    formatter.locale = Locale(identifier: "en_CA")
    XCTAssertEqual(formatter.batteryLevel(from: templateStatus), "12%")
    XCTAssertEqual(formatter.mileage(from: templateStatus), "2,195 km")
    XCTAssertEqual(formatter.electricalRange(from: templateStatus), "294 km")
  }

  func testUnitedKingdomEnglishFormatting() {
    formatter.locale = Locale(identifier: "en_GB")
    XCTAssertEqual(formatter.batteryLevel(from: templateStatus), "12%")
    XCTAssertEqual(formatter.mileage(from: templateStatus), "1,364 mi")
    XCTAssertEqual(formatter.electricalRange(from: templateStatus), "183 mi")
  }

  func testChineseFormatting() {
    formatter.locale = Locale(identifier: "zh_CN")
    XCTAssertEqual(formatter.batteryLevel(from: templateStatus), "12%")
    XCTAssertEqual(formatter.mileage(from: templateStatus), "2,195公里")
    XCTAssertEqual(formatter.electricalRange(from: templateStatus), "294公里")
  }

  func testGermanFormatting() {
    formatter.locale = Locale(identifier: "de_DE")
    XCTAssertEqual(formatter.batteryLevel(from: templateStatus), "12 %")
    XCTAssertEqual(formatter.mileage(from: templateStatus), "2.195 km")
    XCTAssertEqual(formatter.electricalRange(from: templateStatus), "294 km")
  }
}

private let templateStatus = Status(
  vin: "abc123",
  batteryLevel: GenericValue(
    value: 12,
    unit: "PERCENT",
    unitTranslationKey: "GRAY_SLICE_UNIT_PERCENT",
    unitTranslationKeyV2: "TC.UNIT.PERCENT"),
  mileage: Distance(
    value: 2195,
    unit: .kilometers,
    originalValue: 2195,
    originalUnit: .kilometers,
    valueInKilometers: 2195,
    unitTranslationKey: "GRAY_SLICE_UNIT_KILOMETER",
    unitTranslationKeyV2: "TC.UNIT.KILOMETER"),
  overallLockStatus: "CLOSED_LOCKED",
  serviceIntervals: ServiceIntervals(
    oilService: ServiceIntervals.OilService(),
    inspection: ServiceIntervals.Inspection(
      distance: Distance(
        value: -27842,
        unit: .kilometers,
        originalValue: -27842,
        originalUnit: .kilometers,
        valueInKilometers: -27842,
        unitTranslationKey: "GRAY_SLICE_UNIT_KILOMETER",
        unitTranslationKeyV2: "TC.UNIT.KILOMETER"
      ),
      time: GenericValue(
        value: -710,
        unit: "DAYS",
        unitTranslationKey: "GRAY_SLICE_UNIT_DAY",
        unitTranslationKeyV2: "TC.UNIT.DAYS"
      )
    )
  ),
  remainingRanges: RemainingRanges(
    conventionalRange: RemainingRanges.Range(
      distance: nil,
      engineType: "UNSUPPORTED",
      isPrimary: false
    ),
    electricalRange: RemainingRanges.Range(
      distance: Distance(
        value: 294,
        unit: .kilometers,
        originalValue: 294,
        originalUnit: .kilometers,
        valueInKilometers: 294,
        unitTranslationKey: "GRAY_SLICE_UNIT_KILOMETER",
        unitTranslationKeyV2: "TC.UNIT.KILOMETER"
      ),
      engineType: "ELECTRIC",
      isPrimary: true
    )
  )
)
