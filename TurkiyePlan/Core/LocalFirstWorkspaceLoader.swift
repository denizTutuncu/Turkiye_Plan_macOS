import Foundation
@MainActor final class LocalFirstWorkspaceLoader: WorkspaceLoading {
 private let persistence: any PlanningPersistence
 private let remote: (any GeographyRepository)?
 private let remoteScenario: (any ScenarioRepository)?
 private let bundledGeography: any GeographyRepository
 private let bundledScenario: any ScenarioRepository
 private let validator: any ScenarioValidating
 init(persistence: any PlanningPersistence, remote: (any GeographyRepository)?, remoteScenario: (any ScenarioRepository)? = nil, bundledGeography: any GeographyRepository, bundledScenario: any ScenarioRepository, validator: any ScenarioValidating) {
  self.persistence = persistence; self.remote = remote; self.remoteScenario = remoteScenario; self.bundledGeography = bundledGeography; self.bundledScenario = bundledScenario; self.validator = validator
 }
 func load() async throws -> LoadedWorkspace {
  // An unavailable/corrupt store throws. Only a genuinely empty dataset triggers fallback.
  let localGeography = try persistence.readGeography()
  let localScenario = try persistence.readScenario()
  var notices: [String] = []
  let geography: Geography
  let geographyOrigin: LoadOrigin
  if let localGeography {
   try GeographyValidation().validate(localGeography)
   geography = localGeography; geographyOrigin = .database
  } else {
   var acceptedRemote: Geography?
   if let remote {
    do {
     let candidate = try await remote.load()
     try GeographyValidation().validate(candidate)
     acceptedRemote = candidate
    } catch {
     notices.append("Uzak coğrafya yüklenemedi veya doğrulanamadı; paket JSON kullanılacak. " + error.localizedDescription)
    }
   }
   if let acceptedRemote { geography = acceptedRemote; geographyOrigin = .api }
   else { geography = try await bundledGeography.load(); try GeographyValidation().validate(geography); geographyOrigin = .bundled }
  }
  var scenarioWasMigrated = false
  let scenario: Scenario
  let scenarioOrigin: LoadOrigin
  if var localScenario {
   if localScenario.povertyProfiles == nil, localScenario.povertyWeight > 0,
    localScenario.records.contains(where: { $0.requirementCents > 0 && ($0.povertyRate == nil || $0.povertyRate == 0) }) {
    localScenario.povertyWeight = 0; scenarioWasMigrated = true
    notices.append("Eski yoksulluk=0 yer tutucuları bilinmeyen veri olarak ele alındı. Plan korundu; yoksulluk ağırlığı 0 yapıldı. Profil JSON dosyasını yükledikten sonra ağırlığı yeniden uygulayın.")
   }
   scenario = localScenario; scenarioOrigin = .database
  }
  else {
   var acceptedRemote: Scenario?
   if let remoteScenario {
    do {
     let candidate = try await remoteScenario.load()
     _ = try validator.validate(candidate, geography: geography)
     acceptedRemote = candidate
    } catch { notices.append("Uzak senaryo yüklenemedi veya doğrulanamadı; başlangıç JSON kullanılacak. " + error.localizedDescription) }
   }
   if let acceptedRemote { scenario = acceptedRemote; scenarioOrigin = .api }
   else { scenario = try await bundledScenario.load(); scenarioOrigin = .bundled }
  }
  _ = try validator.validate(scenario, geography: geography)
  // Do not present a successful seed until both datasets have been durably committed.
  if localGeography == nil || localScenario == nil || scenarioWasMigrated {
   try persistence.save(geography: localGeography == nil ? geography : nil, scenario: localScenario == nil || scenarioWasMigrated ? scenario : nil)
  }
  return LoadedWorkspace(geography: geography, scenario: scenario, geographyOrigin: geographyOrigin, scenarioOrigin: scenarioOrigin, notices: notices)
 }
}
