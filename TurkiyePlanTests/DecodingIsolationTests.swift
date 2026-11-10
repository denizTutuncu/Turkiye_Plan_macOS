import Foundation
import XCTest
@testable import TurkiyePlan
// Compile-time regression: Codable conformances must be usable with Sendable generics.
private nonisolated func requireDecodingAcrossActors<Value: Decodable & Sendable>(_ type: Value.Type) {}
final class DecodingIsolationTests: XCTestCase {
 func testDomainTypesSupportNonisolatedDecoding() {
  requireDecodingAcrossActors(Geography.self)
  requireDecodingAcrossActors(Scenario.self)
  requireDecodingAcrossActors(Province.self)
  requireDecodingAcrossActors(District.self)
 }
}
