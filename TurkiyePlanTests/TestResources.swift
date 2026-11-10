import Foundation
import XCTest
private final class TestResourcesAnchor: NSObject {}
enum TestResources {
 static func url(_ name: String) throws -> URL {
  let bundle = Bundle(for: TestResourcesAnchor.self)
  if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures") { return url }
  if let url = bundle.url(forResource: name, withExtension: "json") { return url }
  throw NSError(domain: "TurkiyePlanTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled test fixture: " + name])
 }
}
