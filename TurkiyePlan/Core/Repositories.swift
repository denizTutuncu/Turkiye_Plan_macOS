import Foundation
protocol GeographyRepository: Sendable { nonisolated func load() async throws -> Geography }
protocol ScenarioRepository: Sendable { nonisolated func load() async throws -> Scenario }
nonisolated struct LocalGeographyRepository: GeographyRepository {
 let url: URL
 func load() async throws -> Geography { try JSONDecoder().decode(Geography.self, from: Data(contentsOf: url)) }
}
nonisolated struct LocalScenarioRepository: ScenarioRepository {
 let url: URL
 func load() async throws -> Scenario { try JSONDecoder().decode(Scenario.self, from: Data(contentsOf: url)) }
}
private nonisolated struct HTTPJSONLoader: Sendable {
 let timeoutSeconds: Double
 func load<Value: Decodable & Sendable>(_ type: Value.Type, from endpoint: URL) async throws -> Value {
  var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutSeconds)
  request.setValue("application/json", forHTTPHeaderField: "Accept")
  let (data, response) = try await URLSession.shared.data(for: request)
  guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else { throw PlanningError.invalid("API yanıtı başarısız.") }
  return try JSONDecoder().decode(Value.self, from: data)
 }
}
nonisolated struct APIGeographyRepository: GeographyRepository {
 let endpoint: URL
 let timeoutSeconds: Double
 func load() async throws -> Geography { try await HTTPJSONLoader(timeoutSeconds: timeoutSeconds).load(Geography.self, from: endpoint) }
}
nonisolated struct APIScenarioRepository: ScenarioRepository {
 let endpoint: URL
 let timeoutSeconds: Double
 func load() async throws -> Scenario { try await HTTPJSONLoader(timeoutSeconds: timeoutSeconds).load(Scenario.self, from: endpoint) }
}
protocol ScenarioStore: Sendable { nonisolated func read(_ url: URL) throws -> Scenario; nonisolated func write(_ value: Scenario, to url: URL) throws }
nonisolated struct JSONScenarioStore: ScenarioStore {
 func read(_ url: URL) throws -> Scenario { try JSONDecoder().decode(Scenario.self, from: Data(contentsOf: url)) }
 func write(_ value: Scenario, to url: URL) throws { let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; try encoder.encode(value).write(to: url, options: .atomic) }
}
protocol GeographyFileStore: Sendable { nonisolated func read(_ url: URL) throws -> Geography }
nonisolated struct JSONGeographyFileStore: GeographyFileStore {
 func read(_ url: URL) throws -> Geography { try JSONDecoder().decode(Geography.self, from: Data(contentsOf: url)) }
}
