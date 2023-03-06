import WatchKit
import XCTest

private func sanitizedDeviceName() -> String {
  return WKInterfaceDevice.current().name
    .replacing(/Clone \d+ of\ /, with: "")
    .trimmingCharacters(in: .whitespaces)
}

final class AppUITests: XCTestCase {

  var testEnvironment: String = "Undefined"
  var snapshotDirectory: String!
  var app: XCUIApplication!
  override func setUpWithError() throws {
    continueAfterFailure = true

    testEnvironment = sanitizedDeviceName()
    snapshotDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_PATH"] ?? ""
    if snapshotDirectory.isEmpty {
      snapshotDirectory = ProcessInfo.processInfo.environment["TMPDIR"]
    }

    assert(snapshotDirectory != nil)

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
    try writeSnapshot(sanitizedSnapshot(rootView.screenshot().image))
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
    try writeSnapshot(sanitizedSnapshot(rootView.screenshot().image))
  }

  func testAllErrors() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "error-view"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(sanitizedSnapshot(rootView.screenshot().image))
  }

  func testVehicleDetailsView() throws {
    app.launchEnvironment = [
      "TESTING": "1",
      "test-case": "vehicle-details-view"
    ]
    app.launch()

    let rootView = app.otherElements.containing(.any, identifier: "root-view").firstMatch
    XCTAssertTrue(rootView.exists)
    try writeSnapshot(sanitizedSnapshot(rootView.screenshot().image))
  }

  private func writeSnapshot(
    _ image: UIImage,
    named name: String? = nil,
    file: StaticString = #file,
    testName: String = #function
  ) throws {
    let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
    let fileName = fileUrl.deletingPathExtension().lastPathComponent

    let snapshotDirectoryUrl = snapshotDirectory.map { URL(fileURLWithPath: $0, isDirectory: true) }!
      .appendingPathComponent(fileName)

    let sanitizedTestName = sanitizePathComponent(testName).replacing(/^test/, with: "")
    let identifier: String
    if let name {
      identifier = "\(sanitizedTestName).\(sanitizePathComponent(name))"
    } else {
      identifier = sanitizedTestName
    }

    let snapshotFileUrl = snapshotDirectoryUrl
      .appendingPathComponent(identifier)
      .appendingPathExtension("png")
    let fileManager = FileManager.default
    try fileManager.createDirectory(at: snapshotDirectoryUrl, withIntermediateDirectories: true)

    try image.pngData()!.write(to: snapshotFileUrl)

    if ProcessInfo.processInfo.environment.keys.contains("__XCODE_BUILT_PRODUCTS_DIR_PATHS") {
      XCTContext.runActivity(named: "Attached Recorded Snapshot") { activity in
        let attachment = XCTAttachment(contentsOfFile: snapshotFileUrl)
        activity.add(attachment)
      }
    }
  }

  private func sanitizePathComponent(_ string: String) -> String {
    return string
      .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
      .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
  }

  private func sanitizedSnapshot(_ image: UIImage) throws -> UIImage {
    UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
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
