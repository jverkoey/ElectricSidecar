import XCTest

class UITestCase: XCTestCase {

  var snapshotDirectory: String!
  var app: XCUIApplication!
  override func setUpWithError() throws {
    continueAfterFailure = true

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

  func writeSnapshot(
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
}

private final class FailedToGetCurrentGraphicsContext: Error {
}

private final class FailedToGetGetImageFromCurrentContext: Error {
}
