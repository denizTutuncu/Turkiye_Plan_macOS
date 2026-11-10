import Foundation

protocol ScenarioSnapshotStoring: Sendable {
 nonisolated func load() async throws -> [SavedPlanningScenario]
 nonisolated func save(_ snapshot: SavedPlanningScenario) async throws
}

/// Separate atomic files avoid changing the active SwiftData schema or workspace.
actor JSONScenarioSnapshotStore: ScenarioSnapshotStoring {
 private let directory: URL
 init(directory: URL) { self.directory = directory }
 func load() async throws -> [SavedPlanningScenario] {
  guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
  let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
  var snapshots: [SavedPlanningScenario] = []
  for url in files where url.pathExtension == "json" {
   let value = try JSONDecoder().decode(SavedPlanningScenario.self, from: Data(contentsOf: url))
   guard url.deletingPathExtension().lastPathComponent == value.id.uuidString,
    !snapshots.contains(where: { $0.id == value.id }) else { throw PlanningError.invalid("review.archiveInvalid") }
   snapshots.append(value)
  }
  return snapshots.sorted { $0.savedAt > $1.savedAt }
 }
 func save(_ snapshot: SavedPlanningScenario) async throws {
  guard !snapshot.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, snapshot.name.count <= 120 else { throw PlanningError.invalid("review.nameRequired") }
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  let destination = directory.appendingPathComponent(snapshot.id.uuidString).appendingPathExtension("json")
  guard !FileManager.default.fileExists(atPath: destination.path) else { throw PlanningError.invalid("review.archiveInvalid") }
  let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
  try encoder.encode(snapshot).write(to: destination, options: .atomic)
 }
}

actor InMemoryScenarioSnapshotStore: ScenarioSnapshotStoring {
 private var snapshots: [SavedPlanningScenario] = []
 func load() async throws -> [SavedPlanningScenario] { snapshots }
 func save(_ snapshot: SavedPlanningScenario) async throws { snapshots.insert(snapshot, at: 0) }
}
