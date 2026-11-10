import Foundation
import SwiftData
// Start with an explicit version so later schema changes have a migration path.
enum PlanningSchemaV1: VersionedSchema {
 static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
 static var models: [any PersistentModel.Type] { [StoredProvince.self, StoredDistrict.self, StoredGeographyMetadata.self, StoredScenario.self] }

 @Model final class StoredProvince {
  @Attribute(.unique) var id: String
  var name: String
  @Relationship(deleteRule: .cascade, inverse: \StoredDistrict.province) var districts: [StoredDistrict] = []
  init(id: String, name: String) { self.id = id; self.name = name }
 }
 @Model final class StoredDistrict {
  @Attribute(.unique) var id: String
  var name: String
  var province: StoredProvince?
  init(id: String, name: String, province: StoredProvince) { self.id = id; self.name = name; self.province = province }
 }
 @Model final class StoredGeographyMetadata {
  @Attribute(.unique) var key: String
  var schemaVersion: Int
  var sourceJSON: Data
  var importedAt: Date
  init(key: String, schemaVersion: Int, sourceJSON: Data) { self.key = key; self.schemaVersion = schemaVersion; self.sourceJSON = sourceJSON; self.importedAt = Date() }
 }
 @Model final class StoredScenario {
  @Attribute(.unique) var key: String
  var payloadVersion: Int
  @Attribute(.externalStorage) var payload: Data
  var updatedAt: Date
  init(key: String, payload: Data) { self.key = key; self.payloadVersion = 1; self.payload = payload; self.updatedAt = Date() }
 }
}
enum PlanningMigrationPlan: SchemaMigrationPlan {
 static var schemas: [any VersionedSchema.Type] { [PlanningSchemaV1.self] }
 static var stages: [MigrationStage] { [] }
}
