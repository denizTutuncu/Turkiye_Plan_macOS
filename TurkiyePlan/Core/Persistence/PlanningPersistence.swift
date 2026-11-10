import Foundation
// Domain values cross this boundary. SwiftData objects never reach view models.
@MainActor protocol PlanningPersistence: AnyObject {
 var location: URL { get }
 func readGeography() throws -> Geography?
 func readScenario() throws -> Scenario?
 /// A nil argument means leave that dataset untouched. Writes commit together.
 func save(geography: Geography?, scenario: Scenario?) throws
}
nonisolated enum LoadOrigin: String, Sendable {
 case database = "Yerel SwiftData"
 case api = "Uzak API"
 case bundled = "Uygulamayla gelen JSON"
}
nonisolated struct LoadedWorkspace: Sendable {
 let geography: Geography
 let scenario: Scenario
 let geographyOrigin: LoadOrigin
 let scenarioOrigin: LoadOrigin
 let notices: [String]
}
@MainActor protocol WorkspaceLoading {
 func load() async throws -> LoadedWorkspace
}
