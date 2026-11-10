import Foundation
import XCTest
@testable import TurkiyePlan
final class PovertyWeightTests: XCTestCase {
 func fixture() throws -> (Geography, Scenario, [Service], [PovertyProfile]) {
  let d = JSONDecoder()
  return (try d.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography"))), try d.decode(Scenario.self, from: Data(contentsOf: TestResources.url("demo-scenario"))), try d.decode([Service].self, from: Data(contentsOf: TestResources.url("services"))), try d.decode(PovertyDataset.self, from: Data(contentsOf: TestResources.url("poverty-profiles-2025"))).profiles)
 }
 func testWeightChangesDistrictAllocationsAndConservesBudget() throws {
  var (g, s, services, profiles) = try fixture(); s.povertyProfiles = profiles; s.povertyWeight = 0
  let a = try AllocationEngine().calculate(s, geography: g, services: services)
  s.povertyWeight = 1
  let b = try AllocationEngine().calculate(s, geography: g, services: services)
  XCTAssertNotEqual(a.rows.map(\.allocatedCents), b.rows.map(\.allocatedCents))
  XCTAssertEqual(b.rows.reduce(Int64(0)) { $0 + $1.allocatedCents } + b.unallocatedCents, s.budgetCents)
 }
 func testDistrictProfileOverridesRepeatedServiceField() throws {
  var (g, s, services, profiles) = try fixture(); s.povertyProfiles = profiles; s.povertyWeight = 1
  let a = try AllocationEngine().calculate(s, geography: g, services: services)
  for i in s.records.indices { s.records[i].povertyRate = 0.99 }
  let b = try AllocationEngine().calculate(s, geography: g, services: services)
  XCTAssertEqual(a.rows.map(\.allocatedCents), b.rows.map(\.allocatedCents))
 }
 func testUnknownIsNotZeroAndDisallowsPositiveWeight() throws {
  var (g, s, services, profiles) = try fixture()
  for i in profiles.indices where profiles[i].geographyID == s.records[0].districtID { profiles[i].rate = nil; profiles[i].status = "missing" }
  s.povertyProfiles = profiles; s.povertyWeight = 1
  XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
  s.povertyWeight = 0
  XCTAssertNoThrow(try AllocationEngine().calculate(s, geography: g, services: services))
 }
 func testDefinitionMismatchCannotBeWeightedTogether() throws {
  var (g, s, services, profiles) = try fixture()
  for i in profiles.indices where profiles[i].geographyID == s.records[0].districtID { profiles[i].definitionID = "different_threshold" }
  s.povertyProfiles = profiles; s.povertyWeight = 1
  XCTAssertThrowsError(try AllocationEngine().calculate(s, geography: g, services: services))
 }
}
