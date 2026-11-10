import Foundation
import XCTest
import SwiftData
@testable import TurkiyePlan

@MainActor final class LocalFirstPersistenceTests: XCTestCase {
 private func fixture() throws -> (Geography, Scenario, PlanningValidation) {
  let decoder = JSONDecoder()
  let g = try decoder.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography")))
  let s = try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("demo-scenario")))
  let services = try decoder.decode([Service].self, from: Data(contentsOf: TestResources.url("services")))
  let indicators = try decoder.decode([IndicatorDefinition].self, from: Data(contentsOf: TestResources.url("indicators")))
  return (g, s, PlanningValidation(services: services, indicators: indicators, calculator: AllocationEngine()))
 }
 func testLocalDataSkipsRemoteAndBundle() async throws {
  let (g, s, validator) = try fixture(); let store = MemoryPersistence(geography: g, scenario: s)
  let remote = GeographyStub(value: g); let bundle = GeographyStub(value: g); let scenario = ScenarioStub(value: s)
  let loader = LocalFirstWorkspaceLoader(persistence: store, remote: remote, remoteScenario: scenario, bundledGeography: bundle, bundledScenario: scenario, validator: validator)
  let loaded = try await loader.load()
  XCTAssertEqual(loaded.geographyOrigin, .database); XCTAssertEqual(loaded.scenarioOrigin, .database)
  XCTAssertEqual(remote.calls, 0); XCTAssertEqual(bundle.calls, 0); XCTAssertEqual(scenario.calls, 0); XCTAssertEqual(store.writes, 0)
 }
 func testRemoteSeedPersistsAndNextLaunchUsesLocal() async throws {
  let (g, s, validator) = try fixture(); let store = MemoryPersistence()
  let remote = GeographyStub(value: g); let remoteScenario = ScenarioStub(value: s); let bundle = GeographyStub(value: g); let scenario = ScenarioStub(value: s)
  let loader = LocalFirstWorkspaceLoader(persistence: store, remote: remote, remoteScenario: remoteScenario, bundledGeography: bundle, bundledScenario: scenario, validator: validator)
  let loaded = try await loader.load(); XCTAssertEqual(loaded.geographyOrigin, .api); XCTAssertEqual(loaded.scenarioOrigin, .api)
  XCTAssertEqual(store.writes, 1); XCTAssertEqual(bundle.calls, 0); XCTAssertEqual(scenario.calls, 0)
  let next = try await loader.load(); XCTAssertEqual(next.geographyOrigin, .database); XCTAssertEqual(next.scenarioOrigin, .database)
  XCTAssertEqual(remote.calls, 1); XCTAssertEqual(remoteScenario.calls, 1); XCTAssertEqual(store.writes, 1)
 }
 func testRemoteFailuresFallBackToBundledAndAreReported() async throws {
  let (g, s, validator) = try fixture(); let store = MemoryPersistence()
  let remote = GeographyStub(value: g, shouldFail: true); let scenarioRemote = ScenarioStub(value: s, shouldFail: true)
  let loader = LocalFirstWorkspaceLoader(persistence: store, remote: remote, remoteScenario: scenarioRemote, bundledGeography: GeographyStub(value: g), bundledScenario: ScenarioStub(value: s), validator: validator)
  let loaded = try await loader.load(); XCTAssertEqual(loaded.geographyOrigin, .bundled); XCTAssertEqual(loaded.scenarioOrigin, .bundled)
  XCTAssertEqual(loaded.notices.count, 2); XCTAssertEqual(store.writes, 1)
 }
 func testInvalidRemoteGeographyFallsBackBeforeSaving() async throws {
  let (g, s, validator) = try fixture(); let store = MemoryPersistence()
  let invalid = Geography(schemaVersion: g.schemaVersion, source: g.source, provinces: g.provinces, districts: g.districts + [g.districts[0]])
  let loader = LocalFirstWorkspaceLoader(persistence: store, remote: GeographyStub(value: invalid), bundledGeography: GeographyStub(value: g), bundledScenario: ScenarioStub(value: s), validator: validator)
  let loaded = try await loader.load(); XCTAssertEqual(loaded.geographyOrigin, .bundled)
  XCTAssertEqual(try XCTUnwrap(store.geography).districts.count, g.districts.count)
 }
 func testReadErrorDoesNotTriggerFallbackOrOverwrite() async throws {
  let (g, s, validator) = try fixture(); let store = MemoryPersistence(geography: g, scenario: s); store.failRead = true
  let remote = GeographyStub(value: g)
  let loader = LocalFirstWorkspaceLoader(persistence: store, remote: remote, bundledGeography: remote, bundledScenario: ScenarioStub(value: s), validator: validator)
  do { _ = try await loader.load(); XCTFail("Expected local read error") } catch { }
  XCTAssertEqual(remote.calls, 0); XCTAssertEqual(store.writes, 0)
 }
 func testFailedSaveDoesNotPublishChangedScenario() async throws {
  let (g, s, validator) = try fixture(); let store = MemoryPersistence(geography: g, scenario: s)
  let loader = LocalFirstWorkspaceLoader(persistence: store, remote: nil, bundledGeography: GeographyStub(value: g), bundledScenario: ScenarioStub(value: s), validator: validator)
  let controller = ConcretePlanningController(loader: loader, persistence: store, validator: validator, fileStore: JSONScenarioStore(), geographyFileStore: JSONGeographyFileStore())
  let template = try JSONDecoder().decode(NeedRecord.self, from: Data(contentsOf: TestResources.url("record-template")))
  let vm = PlanningViewModel(controller: controller, services: validator.services, indicators: validator.indicators, recordTemplate: template)
  await vm.load(); store.failWrite = true
  vm.updateBudget(s.budgetCents + 100)
  XCTAssertEqual(vm.scenario?.budgetCents, s.budgetCents); XCTAssertNotNil(vm.error); XCTAssertEqual(store.scenario?.budgetCents, s.budgetCents)
 }
 func testSwiftDataRoundTripAndIdempotentSeed() throws {
  let (g, s, _) = try fixture()
  let schema = Schema(PlanningSchemaV1.models)
  let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
  let container = try ModelContainer(for: schema, migrationPlan: PlanningMigrationPlan.self, configurations: [configuration])
  let store = SwiftDataPlanningPersistence(container: container, location: URL(fileURLWithPath: "/in-memory/Planning.store"))
  XCTAssertNil(try store.readGeography()); XCTAssertNil(try store.readScenario())
  try store.save(geography: g, scenario: s); try store.save(geography: g, scenario: s)
  let loaded = try XCTUnwrap(store.readGeography())
  XCTAssertEqual(loaded.provinces.count, g.provinces.count); XCTAssertEqual(loaded.districts.count, g.districts.count)
  XCTAssertEqual(Set(loaded.districts.map(\.id)), Set(g.districts.map(\.id)))
  XCTAssertEqual(loaded.source.revision, g.source.revision)
  XCTAssertEqual(try store.readScenario()?.budgetCents, s.budgetCents)
 }
 func testOnDiskPersistenceAcrossContainers() throws {
  let (g, s, _) = try fixture(); let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: directory) }
  let url = directory.appendingPathComponent("Planning.store")
  do { let store = try SwiftDataPlanningPersistence.make(at: url); try store.save(geography: g, scenario: s) }
  let reopened = try SwiftDataPlanningPersistence.make(at: url)
  XCTAssertEqual(try reopened.readGeography()?.districts.count, g.districts.count)
  XCTAssertEqual(try reopened.readScenario()?.name, s.name)
 }
}

@MainActor private final class MemoryPersistence: PlanningPersistence {
 let location = URL(fileURLWithPath: "/test/Planning.store")
 var geography: Geography?; var scenario: Scenario?; var failRead = false; var failWrite = false; var writes = 0
 init(geography: Geography? = nil, scenario: Scenario? = nil) { self.geography = geography; self.scenario = scenario }
 func readGeography() throws -> Geography? { if failRead { throw PlanningError.invalid("Simulated local read failure") }; return geography }
 func readScenario() throws -> Scenario? { if failRead { throw PlanningError.invalid("Simulated local read failure") }; return scenario }
 func save(geography: Geography?, scenario: Scenario?) throws {
  if failWrite { throw PlanningError.invalid("Simulated disk failure") }
  if let geography { self.geography = geography }; if let scenario { self.scenario = scenario }; writes += 1
 }
}
@MainActor private final class GeographyStub: GeographyRepository {
 let value: Geography; let shouldFail: Bool; var calls = 0
 init(value: Geography, shouldFail: Bool = false) { self.value = value; self.shouldFail = shouldFail }
 func load() async throws -> Geography { calls += 1; if shouldFail { throw PlanningError.invalid("Simulated network failure") }; return value }
}
@MainActor private final class ScenarioStub: ScenarioRepository {
 let value: Scenario; let shouldFail: Bool; var calls = 0
 init(value: Scenario, shouldFail: Bool = false) { self.value = value; self.shouldFail = shouldFail }
 func load() async throws -> Scenario { calls += 1; if shouldFail { throw PlanningError.invalid("Simulated network failure") }; return value }
}
