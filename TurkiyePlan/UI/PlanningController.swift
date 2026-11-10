import Foundation
@MainActor protocol PlanningController {
 var storageLocation: URL { get }
 func readPovertyDataset(_ url: URL) throws -> PovertyDataset
 func bundledPopulation() async throws -> [IndicatorObservation]
 func load() async throws -> LoadedWorkspace
 func calculate(_ scenario: Scenario, geography: Geography) throws -> AllocationResult
 func readGeography(_ url: URL) throws -> Geography
 func persist(_ geography: Geography, scenario: Scenario) throws
 func persist(_ scenario: Scenario) throws
 func read(_ url: URL) throws -> Scenario
 func save(_ scenario: Scenario, to url: URL) throws
 func export(_ result: AllocationReport, to url: URL) throws
}
@MainActor final class ConcretePlanningController: PlanningController {
 private let observationSeed: (any ScenarioRepository)?
 private let loader: any WorkspaceLoading
 private let persistence: any PlanningPersistence
 private let validator: any ScenarioValidating
 private let geographyFileStore: any GeographyFileStore
 private let fileStore: any ScenarioStore
 var storageLocation: URL { persistence.location }
 init(loader: any WorkspaceLoading, persistence: any PlanningPersistence, validator: any ScenarioValidating, fileStore: any ScenarioStore, geographyFileStore: any GeographyFileStore, observationSeed: (any ScenarioRepository)? = nil) {
  self.observationSeed = observationSeed; self.loader = loader; self.persistence = persistence; self.validator = validator; self.fileStore = fileStore; self.geographyFileStore = geographyFileStore
 }
 func readPovertyDataset(_ url: URL) throws -> PovertyDataset { try JSONDecoder().decode(PovertyDataset.self, from: Data(contentsOf: url)) }
 func bundledPopulation() async throws -> [IndicatorObservation] {
  guard let observationSeed else { throw PlanningError.invalid("Paket nüfus verisi yapılandırılmadı.") }
  return try await observationSeed.load().observations ?? []
 }
 func load() async throws -> LoadedWorkspace { try await loader.load() }
 func calculate(_ scenario: Scenario, geography: Geography) throws -> AllocationResult { try validator.validate(scenario, geography: geography) }
 func readGeography(_ url: URL) throws -> Geography { try geographyFileStore.read(url) }
 func persist(_ geography: Geography, scenario: Scenario) throws {
  _ = try validator.validate(scenario, geography: geography)
  try persistence.save(geography: geography, scenario: scenario)
 }
 func persist(_ scenario: Scenario) throws {
  guard let geography = try persistence.readGeography() else { throw PlanningError.invalid("Yerel coğrafya yüklenmeden senaryo kaydedilemez.") }
  _ = try validator.validate(scenario, geography: geography)
  try persistence.save(geography: nil, scenario: scenario)
 }
 func read(_ url: URL) throws -> Scenario { try fileStore.read(url) }
 func save(_ scenario: Scenario, to url: URL) throws { try fileStore.write(scenario, to: url) }
 func export(_ result: AllocationReport, to url: URL) throws { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try encoder.encode(result).write(to: url, options: .atomic) }
}
