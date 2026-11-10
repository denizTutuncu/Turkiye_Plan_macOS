import Foundation
import XCTest
@testable import TurkiyePlan
final class AllocationEngineTests: XCTestCase {
 func fixture() throws -> (Geography, Scenario, [Service]) {
  let decoder = JSONDecoder()
  return (try decoder.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography"))), try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("demo-scenario"))), try decoder.decode([Service].self, from: Data(contentsOf: TestResources.url("services"))))
 }
 func testBudgetConservationAndCaps() throws {
  let (g, s, services) = try fixture(); let result = try AllocationEngine().calculate(s, geography: g, services: services)
  XCTAssertEqual(result.rows.reduce(Int64(0)) { $0 + $1.allocatedCents } + result.unallocatedCents, s.budgetCents)
  XCTAssertTrue(result.rows.allSatisfy { $0.allocatedCents <= $0.requirementCents && $0.allocatedCents >= 0 })
  XCTAssertEqual(result.excludedDistrictCount, g.districts.count - Set(s.records.map(\.districtID)).count)
 }
 func testFullFundingLeavesSurplus() throws {
  var (g, s, services) = try fixture(); s.budgetCents = 9_000_000_000
  let result = try AllocationEngine().calculate(s, geography: g, services: services)
  XCTAssertTrue(result.rows.allSatisfy { $0.allocatedCents == $0.requirementCents }); XCTAssertGreaterThan(result.unallocatedCents, 0)
 }
 func testZeroBudgetAndMissingRecords() throws {
  var (g, s, services) = try fixture(); s.budgetCents = 0
  XCTAssertTrue(try AllocationEngine().calculate(s, geography: g, services: services).rows.allSatisfy { $0.allocatedCents == 0 })
  s.records = []; XCTAssertEqual(try AllocationEngine().calculate(s, geography: g, services: services).excludedDistrictCount, g.districts.count)
 }
 func testRejectsDuplicatesUnknownIDsAndMixedPrices() throws {
  let (g, original, services) = try fixture()
  var s = original; s.records.append(s.records[0]); XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
  s = original; s.records[0].districtID = "unknown"; XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
  s = original; s.records[0].referenceYear -= 1; XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
 }
 func testInvalidNumbersAndFinanceLimit() throws {
  var (g, s, services) = try fixture(); s.records[0].fiscalCapacityIndex = 0
  XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
  s.records[0].fiscalCapacityIndex = 1; s.finances = FinancialEnvelope(ownRevenueCents: 1, externalTransfersCents: 0, committedSpendingCents: 0, debtServiceCents: 0, reserveCents: 0)
  XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
 }
 func testOrderIndependentRemainderAndCappedRedistribution() throws {
  var (g, s, services) = try fixture(); s.budgetCents = 101
  let first = try AllocationEngine().calculate(s, geography: g, services: services)
  s.records.reverse(); let second = try AllocationEngine().calculate(s, geography: g, services: services)
  XCTAssertEqual(Dictionary(uniqueKeysWithValues: first.rows.map { ($0.id, $0.allocatedCents) }), Dictionary(uniqueKeysWithValues: second.rows.map { ($0.id, $0.allocatedCents) }))
  s.records[0].fiscalCapacityIndex = 0.001; s.budgetCents = 500_000_000
  let capped = try AllocationEngine().calculate(s, geography: g, services: services)
  XCTAssertEqual(capped.rows.reduce(Int64(0)) { $0 + $1.allocatedCents } + capped.unallocatedCents, s.budgetCents)
 }
 func testGeographyRelationships() throws {
  let (g, _, _) = try fixture()
  XCTAssertEqual(Set(g.districts.map(\.id)).count, g.districts.count)
  XCTAssertTrue(g.districts.allSatisfy { d in g.provinces.contains { $0.id == d.provinceID } })
 }
}
