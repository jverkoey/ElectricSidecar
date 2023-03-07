import Foundation

private let fm = FileManager.default

/// A wrapper around NSFileCoordinator that adds Swift Codable support.
final class CodableCacheCoordinator {
  private let fileCoordinator = NSFileCoordinator(filePresenter: nil)

  func decode<T: Decodable>(url: URL, timeout: TimeInterval? = nil) throws -> T? {
    do {
      var result: T?
      var errorToThrow: Error?
      fileCoordinator.coordinate(readingItemAt: url, error: nil) { url in
        guard fm.fileExists(atPath: url.path) else {
          result = nil
          return
        }
        if let timeout = timeout {
          guard fileModificationDate(url: url)! > Date(timeIntervalSinceNow: -timeout) else {
            result = nil
            return
          }
        }
        do {
          let data = try Data(contentsOf: url)
          let jsonDecoder = JSONDecoder()
          result = try jsonDecoder.decode(T.self, from: data)
        } catch {
          errorToThrow = error
        }
      }
      if let errorToThrow = errorToThrow {
        throw errorToThrow
      }
      return result
    }
  }

  func encode<T: Encodable>(url: URL, object: T) throws {
    var errorToThrow: Error?
    fileCoordinator.coordinate(writingItemAt: url, error: nil) { url in
      do {
        // Cache the response for next time.
        let jsonEncoder = JSONEncoder()
        let data = try jsonEncoder.encode(object)
        try data.write(to: url)
      } catch {
        errorToThrow = error
      }
    }
    if let errorToThrow = errorToThrow {
      throw errorToThrow
    }
  }

  func fileModificationDate(url: URL) -> Date? {
    do {
      let attr = try FileManager.default.attributesOfItem(atPath: url.path)
      return attr[FileAttributeKey.modificationDate] as? Date
    } catch {
      return nil
    }
  }
}
