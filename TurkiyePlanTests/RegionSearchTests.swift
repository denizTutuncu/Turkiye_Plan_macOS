import XCTest
@testable import TurkiyePlan
final class RegionSearchTests: XCTestCase {
 let search = RegionSearch()
 func testTurkishAndAsciiSpellings() {
  XCTAssertTrue(search.matches("İzmir / Karşıyaka", query: "IZMIR karsiyaka"))
  XCTAssertTrue(search.matches("Iğdır / Merkez", query: "ığdır"))
  XCTAssertTrue(search.matches("Şanlıurfa / Haliliye", query: "sanliurfa"))
  XCTAssertTrue(search.matches("İstanbul / Şişli", query: "sisli"))
 }
 func testCombinedNamesAndSeparators() {
  XCTAssertTrue(search.matches("İzmir / Urla", query: " izmir / urla "))
  XCTAssertFalse(search.matches("İzmir / Urla", query: "izmir bodrum"))
 }
 func testClearingOrWhitespaceMatchesAllAndOrderIsIndependent() {
  XCTAssertTrue(search.matches("İzmir / Urla", query: ""))
  XCTAssertTrue(search.matches("İzmir / Urla", query: "  "))
  XCTAssertTrue(search.matches("İzmir / Urla", query: "Urla İzmir"))
 }
}
