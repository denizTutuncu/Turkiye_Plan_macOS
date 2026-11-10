import Foundation
import XCTest
@testable import TurkiyePlan
final class PopulationObservationsTests: XCTestCase {
 func testOfficialCoverageAndMergePreserveExistingPlan() throws {
  let decoder = JSONDecoder()
  let geography = try decoder.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography")))
  let seed = try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("population-observations")))
  let plan = try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("demo-scenario")))
  let helper = PopulationObservations()
  let merged = helper.mergeMissing(seed: seed.observations ?? [], into: plan, geography: geography)
  XCTAssertEqual(merged.scenario.budgetCents, plan.budgetCents)
  XCTAssertEqual(merged.scenario.records, plan.records)
  XCTAssertEqual(merged.added, geography.provinces.count + geography.districts.count)
  for district in geography.districts { XCTAssertNotNil(helper.latest(in: merged.scenario.observations ?? [], geographyID: district.id)) }
  let again = helper.mergeMissing(seed: seed.observations ?? [], into: merged.scenario, geography: geography)
  XCTAssertEqual(again.added, 0)
 }
 func testMergeNeverOverwritesSameYearLocalObservation() throws {
  let decoder = JSONDecoder()
  let geography = try decoder.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography")))
  var seed = try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("population-observations")))
  var local = seed
  local.observations![0].value = 123
  seed.observations![0].value = 456
  let merged = PopulationObservations().mergeMissing(seed: seed.observations ?? [], into: local, geography: geography)
  XCTAssertEqual(merged.added, 0); XCTAssertEqual(merged.scenario.observations?.first?.value, 123)
 }
}
