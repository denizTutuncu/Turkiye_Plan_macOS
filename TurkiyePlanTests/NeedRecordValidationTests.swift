import Foundation
import XCTest
@testable import TurkiyePlan
final class NeedRecordValidationTests: XCTestCase {
 private func record() throws -> NeedRecord {
  let value = try JSONDecoder().decode(Scenario.self, from: Data(contentsOf: TestResources.url("demo-scenario")))
  return try XCTUnwrap(value.records.first)
 }
 func testBlankSourceReportsMissingSourceRatherThanGenericFailure() throws {
  var value = try record(); value.source = "  "
  let issues = NeedRecordValidation().issues(value, priceYear: value.referenceYear)
  XCTAssertTrue(issues.contains { $0.contains("Kaynak / veri seti / yöntem") })
  XCTAssertFalse(issues.contains { $0.contains("planın fiyat yılı") })
 }
 func testPriceYearMismatchNamesBothYears() throws {
  let value = try record()
  let issues = NeedRecordValidation().issues(value, priceYear: value.referenceYear + 1)
  XCTAssertTrue(issues.contains { $0.contains(String(value.referenceYear)) && $0.contains(String(value.referenceYear + 1)) })
 }
 func testInvalidServiceCountsAreSpecificAndValidRecordPasses() throws {
  var value = try record()
  XCTAssertTrue(NeedRecordValidation().issues(value, priceYear: value.referenceYear).isEmpty)
  value.served = value.eligible + 1
  XCTAssertTrue(NeedRecordValidation().issues(value, priceYear: value.referenceYear).contains { $0.contains("Yeterli hizmet alan") })
 }
}
