import XCTest
@testable import TurkiyePlan

final class PlanningReviewTests: XCTestCase {
 private func fixture(budget: Int64 = 10000, priceYear: Int = 2025) -> SavedPlanningScenario {
  let geography = Geography(schemaVersion: 1, source: DataSource(title: "Test", url: "https://example.com", snapshot: "2025", verification: "test", revision: "test-1"),
   provinces: [Province(id: "P", name: "İzmir")], districts: [District(id: "D1", provinceID: "P", name: "Urla"), District(id: "D2", provinceID: "P", name: "Karşıyaka")])
  let record = NeedRecord(districtID: "D1", serviceID: "health", population: 100, eligible: 10, served: 0, targetCoverage: 1,
   capitalUnitCents: 10000, annualUnitCents: 0, horizonYears: 1, povertyRate: nil, deliveryCostIndex: 1, fiscalCapacityIndex: 1, source: "TEST ASSUMPTION", referenceYear: priceYear)
  let scenario = Scenario(name: "Test plan", isDemo: true, priceYear: priceYear, budgetCents: budget, povertyWeight: 0, records: [record], observations: [], povertyProfiles: [])
  return SavedPlanningScenario(id: UUID(), name: "Saved test", savedAt: Date(timeIntervalSince1970: 0), algorithm: SavedPlanningScenario.algorithmID,
   geography: geography, scenario: scenario, services: [Service(id: "health", name: "Sağlık", unit: "people")], indicators: [IndicatorDefinition(id: "population", name: "Population", unit: "kişi")])
 }
 private func replacing(_ original: SavedPlanningScenario, scenario: Scenario, services: [Service]? = nil) -> SavedPlanningScenario {
  SavedPlanningScenario(id: UUID(), name: original.name, savedAt: original.savedAt, algorithm: original.algorithm, geography: original.geography,
   scenario: scenario, services: services ?? original.services, indicators: original.indicators)
 }
 func testSnapshotCalculationFromDetachedTask() async throws {
  let snapshot = fixture()
  let result = try await Task.detached { try snapshot.calculate() }.value
  XCTAssertEqual(result.rows.first?.allocatedCents, 10000)
 }
 func testMissingIsNotZeroAndCitationsAreNotVerification() {
  let original = fixture(); var scenario = original.scenario
  scenario.observations = [IndicatorObservation(geographyID: "D1", indicatorID: "population", referenceYear: 2025, value: 0, source: "test"), IndicatorObservation(geographyID: "D2", indicatorID: "population", referenceYear: 2025, value: nil, source: "test")]
  scenario.povertyProfiles = [PovertyProfile(geographyID: "D1", rate: 0, status: "observed", referenceYear: 2025, definitionID: "test", sourceURL: "test", method: "test")]
  let quality = DataQualityReport.make(scenario: scenario, geography: original.geography, services: original.services)
  XCTAssertEqual(quality.populationDistricts, 1)
  XCTAssertEqual(quality.observedPovertyDistricts, 1)
  XCTAssertEqual(quality.missingPovertyDistricts, 1)
  XCTAssertEqual(quality.services.first?.modeledDistricts, 1)
  XCTAssertEqual(quality.services.first?.missingDistricts, 1)
  XCTAssertEqual(quality.services.first?.sourcedRecords, 1)
 }
 func testComparisonRecalculatesAndReportsDirectionAndGaps() throws {
  let left = fixture(budget: 10000); let right = fixture(budget: 20000)
  let comparison = try ScenarioComparison.make(left: left, right: right)
  XCTAssertNil(comparison.incompatibility)
  XCTAssertEqual(comparison.rows.first?.deltaCents, 10000)
  let service = try XCTUnwrap(comparison.services.first)
  XCTAssertEqual(service.leftCents, 10000)
  XCTAssertEqual(service.rightCents, 20000)
  XCTAssertEqual(service.leftAdditionalUnits, 1, accuracy: 0.0001)
  XCTAssertEqual(service.rightAdditionalUnits, 2, accuracy: 0.0001)
  XCTAssertEqual(service.leftRemainingGap, 9, accuracy: 0.0001)
  XCTAssertEqual(service.rightRemainingGap, 8, accuracy: 0.0001)
  XCTAssertEqual(left.scenario.budgetCents, 10000)
 }
 func testIncompatibleBasesHideDeltasRatherThanInventingZeroRecords() throws {
  let base = fixture()
  let price = try ScenarioComparison.make(left: base, right: fixture(priceYear: 2026))
  XCTAssertEqual(price.incompatibility, "review.priceMismatch"); XCTAssertTrue(price.rows.isEmpty)
  var longer = base.scenario; longer.records[0].horizonYears = 2
  XCTAssertEqual(try ScenarioComparison.make(left: base, right: replacing(base, scenario: longer)).incompatibility, "review.horizonMismatch")
  var empty = base.scenario; empty.records = []
  let coverage = try ScenarioComparison.make(left: base, right: replacing(base, scenario: empty))
  XCTAssertEqual(coverage.incompatibility, "review.recordMismatch"); XCTAssertTrue(coverage.rows.isEmpty)
  XCTAssertEqual(try ScenarioComparison.make(left: base, right: replacing(base, scenario: base.scenario, services: [Service(id: "health", name: "Health", unit: "places")])).incompatibility, "review.unitMismatch")
 }
 func testSavedFilesSurviveReopeningAndCorruptionIsPreserved() async throws {
  let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: directory) }
  let firstStore = JSONScenarioSnapshotStore(directory: directory)
  let snapshot = fixture()
  try await firstStore.save(snapshot)
  let reopened = JSONScenarioSnapshotStore(directory: directory)
  let loaded = try await reopened.load()
  XCTAssertEqual(loaded.count, 1)
  XCTAssertEqual(loaded.first?.id, snapshot.id)
  XCTAssertEqual(try loaded.first?.calculate().rows.first?.allocatedCents, 10000)
  let badFile = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
  let invalid = Data("invalid-json".utf8); try invalid.write(to: badFile)
  do { _ = try await reopened.load(); XCTFail("Corruption must not become an empty library") } catch { }
  XCTAssertEqual(try Data(contentsOf: badFile), invalid)
  XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent(snapshot.id.uuidString).appendingPathExtension("json").path))
 }
}
