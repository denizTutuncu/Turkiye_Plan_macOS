import Foundation
import SwiftData
@MainActor final class SwiftDataPlanningPersistence: PlanningPersistence {
 let location: URL
 private let container: ModelContainer
 private typealias StoredProvince = PlanningSchemaV1.StoredProvince
 private typealias StoredDistrict = PlanningSchemaV1.StoredDistrict
 private typealias Metadata = PlanningSchemaV1.StoredGeographyMetadata
 private typealias StoredScenario = PlanningSchemaV1.StoredScenario

 init(container: ModelContainer, location: URL) { self.container = container; self.location = location }
 static func make(at location: URL) throws -> SwiftDataPlanningPersistence {
  try FileManager.default.createDirectory(at: location.deletingLastPathComponent(), withIntermediateDirectories: true)
  let schema = Schema(PlanningSchemaV1.models)
  let configuration = ModelConfiguration("Planning", schema: schema, url: location, cloudKitDatabase: .none)
  let container = try ModelContainer(for: schema, migrationPlan: PlanningMigrationPlan.self, configurations: [configuration])
  return SwiftDataPlanningPersistence(container: container, location: location)
 }
 static func makeInMemory() throws -> SwiftDataPlanningPersistence {
  let schema = Schema(PlanningSchemaV1.models)
  let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
  let container = try ModelContainer(for: schema, migrationPlan: PlanningMigrationPlan.self, configurations: [configuration])
  return SwiftDataPlanningPersistence(container: container, location: FileManager.default.temporaryDirectory.appendingPathComponent("TurkiyePlan-UITests.store"))
 }
 private func context() -> ModelContext {
  let context = ModelContext(container)
  context.autosaveEnabled = false
  return context
 }
 func readGeography() throws -> Geography? {
  let context = context()
  let metadata = try context.fetch(FetchDescriptor<Metadata>())
  let provinces = try context.fetch(FetchDescriptor<StoredProvince>(sortBy: [SortDescriptor(\.id)]))
  let districts = try context.fetch(FetchDescriptor<StoredDistrict>(sortBy: [SortDescriptor(\.id)]))
  if metadata.isEmpty && provinces.isEmpty && districts.isEmpty { return nil }
  guard metadata.count == 1, let meta = metadata.first, meta.key == "geography", !provinces.isEmpty, !districts.isEmpty else {
   throw PlanningError.invalid("Yerel coğrafya deposu eksik. Mevcut depo korunuyor; otomatik olarak üzerine yazılmayacak.")
  }
  let values = try districts.map { stored -> District in
   guard let parent = stored.province else { throw PlanningError.invalid("Yerel ilçenin il ilişkisi eksik: " + stored.id) }
   return District(id: stored.id, provinceID: parent.id, name: stored.name)
  }
  return Geography(schemaVersion: meta.schemaVersion, source: try JSONDecoder().decode(DataSource.self, from: meta.sourceJSON), provinces: provinces.map { Province(id: $0.id, name: $0.name) }, districts: values)
 }
 func readScenario() throws -> Scenario? {
  let context = context()
  let records = try context.fetch(FetchDescriptor<StoredScenario>())
  guard !records.isEmpty else { return nil }
  guard records.count == 1, let stored = records.first, stored.key == "active", stored.payloadVersion == 1 else {
   throw PlanningError.invalid("Yerel senaryo sürümü desteklenmiyor. Depo korunuyor.")
  }
  return try JSONDecoder().decode(Scenario.self, from: stored.payload)
 }
 func save(geography: Geography?, scenario: Scenario?) throws {
  // Encode first; no context mutations occur if encoding fails.
  let sourceData = try geography.map { try JSONEncoder().encode($0.source) }
  let scenarioData = try scenario.map { try JSONEncoder().encode($0) }
  let context = context()
  do {
   if let geography, let sourceData {
    try GeographyValidation().validate(geography)
    // Bootstrap/import is an atomic replacement, never an append of duplicate IDs.
    // Use fresh objects only for genuinely new identities; update existing objects in place.
    let existingProvinces = try context.fetch(FetchDescriptor<StoredProvince>())
    let existingDistricts = try context.fetch(FetchDescriptor<StoredDistrict>())
    var provinceMap = Dictionary(uniqueKeysWithValues: existingProvinces.map { ($0.id, $0) })
    let districtMap = Dictionary(uniqueKeysWithValues: existingDistricts.map { ($0.id, $0) })
    for province in geography.provinces {
     if let stored = provinceMap[province.id] { stored.name = province.name }
     else { let stored = StoredProvince(id: province.id, name: province.name); context.insert(stored); provinceMap[province.id] = stored }
    }
    for district in geography.districts {
     guard let parent = provinceMap[district.provinceID] else { throw PlanningError.invalid("İl ilişkisi çözülemedi.") }
     if let stored = districtMap[district.id] { stored.name = district.name; stored.province = parent }
     else { context.insert(StoredDistrict(id: district.id, name: district.name, province: parent)) }
    }
    let incomingDistricts = Set(geography.districts.map(\.id))
    let incomingProvinces = Set(geography.provinces.map(\.id))
    for district in existingDistricts where !incomingDistricts.contains(district.id) { context.delete(district) }
    for province in existingProvinces where !incomingProvinces.contains(province.id) { context.delete(province) }
    let metadata = try context.fetch(FetchDescriptor<Metadata>())
    if let stored = metadata.first { stored.schemaVersion = geography.schemaVersion; stored.sourceJSON = sourceData; stored.importedAt = Date() }
    else { context.insert(Metadata(key: "geography", schemaVersion: geography.schemaVersion, sourceJSON: sourceData)) }
   }
   if let scenarioData {
    let records = try context.fetch(FetchDescriptor<StoredScenario>())
    if let stored = records.first { stored.payload = scenarioData; stored.payloadVersion = 1; stored.updatedAt = Date() }
    else { context.insert(StoredScenario(key: "active", payload: scenarioData)) }
   }
   if context.hasChanges { try context.save() }
  } catch {
   context.rollback()
   throw error
  }
 }
}
