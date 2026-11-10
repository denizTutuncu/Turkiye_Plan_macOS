import Foundation
import Combine
@MainActor final class PlanningViewModel: ObservableObject {
 @Published private(set) var dataQuality: DataQualityReport?
 @Published private(set) var savedScenarios: [SavedPlanningScenario] = []
 @Published private(set) var scenarioComparison: ScenarioComparison?
 @Published private(set) var comparisonLeftID = "current"
 @Published private(set) var comparisonRightID = "current"
 @Published private(set) var isSavingSnapshot = false
 @Published private(set) var snapshotNotice: String?
 @Published private(set) var snapshotError: String?
 @Published private(set) var comparisonError: String?
 private let snapshotStore: (any ScenarioSnapshotStoring)?
 private var recordIndex: [String: NeedRecord] = [:]
 private var povertyIndex: [String: PovertyProfile] = [:]
 private var totalScore = 0.0
 @Published var geography: Geography?
 @Published var scenario: Scenario?
 @Published private(set) var serviceTotals: [ServiceAllocationSummary] = []
 @Published var allocationSearch = ""
 @Published var deploymentSearch = ""
 private var districtSearchNames: [String: String] = [:]
 private var districtNames: [String: String] = [:]
 @Published var result: AllocationResult?
 @Published var dataNotice: String?
 @Published var isLoadingPopulation = false
 @Published var error: String?
 @Published var loadDescription = "Yerel depo bekleniyor…"
 @Published var loadNotices: [String] = []
 @Published var lastSavedAt: Date?
 var storageLocation: URL { controller.storageLocation }
 @Published var search = ""
 @Published var selectedProvinceID: String?
 @Published var selectedDistrictID: String?
 @Published var selectedServiceID: String
 @Published var selectedTab = AppTab.overview
 let financePresets: [FinancePreset]
 let services: [Service]
 let indicators: [IndicatorDefinition]
 private let deferredSelections = DeferredUIUpdates()
 private let recordTemplate: NeedRecord
 private let controller: any PlanningController
 init(controller: any PlanningController, services: [Service], indicators: [IndicatorDefinition], recordTemplate: NeedRecord, financePresets: [FinancePreset] = [], snapshotStore: (any ScenarioSnapshotStoring)? = nil) { self.snapshotStore = snapshotStore; self.financePresets = financePresets; self.controller = controller; self.services = services; self.indicators = indicators; self.recordTemplate = recordTemplate; selectedServiceID = services.first?.id ?? "" }
 func requestProvinceSelection(_ id: String?) {
  deferredSelections.enqueue(key: "province") { [weak self] in
   guard let self else { return }
   if let id, self.geography?.provinces.contains(where: { $0.id == id }) != true { return }
   if self.selectedProvinceID != id { self.selectedProvinceID = id }
  }
 }
 func requestDistrictSelection(_ id: String?) {
  deferredSelections.enqueue(key: "district") { [weak self] in
   guard let self else { return }
   if let id, self.geography?.districts.contains(where: { $0.id == id }) != true { return }
   if self.selectedDistrictID != id { self.selectedDistrictID = id }
  }
 }
 func requestServiceSelection(_ id: String) {
  deferredSelections.enqueue(key: "service") { [weak self] in
   guard let self, self.services.contains(where: { $0.id == id }) else { return }
   if self.selectedServiceID != id { self.selectedServiceID = id }
  }
 }
 func load() async {
  do {
   let workspace = try await controller.load()
   let calculated = try controller.calculate(workspace.scenario, geography: workspace.geography)
   geography = workspace.geography; scenario = workspace.scenario; result = calculated; rebuildPresentation(calculated)
   loadDescription = "Coğrafya: " + workspace.geographyOrigin.rawValue + " • Senaryo: " + workspace.scenarioOrigin.rawValue
   loadNotices = workspace.notices; error = nil
   await loadSavedScenarios()
  } catch { self.error = error.localizedDescription }
 }
 func setScenario(_ value: Scenario) throws {
  guard let g = geography else { throw PlanningError.invalid("Coğrafya henüz yüklenmedi.") }
  let calculated = try controller.calculate(value, geography: g)
  // Commit succeeds before UI state changes. Failed saves leave the previous plan visible.
  try controller.persist(value)
  scenario = value; result = calculated; rebuildPresentation(calculated); lastSavedAt = Date(); error = nil
 }
 func importGeography(_ url: URL) {
  do {
   guard let current = scenario else { throw PlanningError.invalid("Önce çalışma alanı yüklenmeli.") }
   let incoming = try controller.readGeography(url)
   let calculated = try controller.calculate(current, geography: incoming)
   try controller.persist(incoming, scenario: current)
   geography = incoming; result = calculated; rebuildPresentation(calculated); lastSavedAt = Date(); selectedProvinceID = nil; selectedDistrictID = nil
   loadDescription = "Coğrafya: içe aktarıldı ve yerel SwiftData deposuna kaydedildi"; error = nil
  } catch { self.error = error.localizedDescription }
 }
 func importScenario(_ url: URL) { do { try setScenario(controller.read(url)) } catch { self.error = error.localizedDescription } }
 func saveScenario(_ url: URL) { do { if let scenario { try controller.save(scenario, to: url) } } catch { self.error = error.localizedDescription } }
 func exportResult(_ url: URL) { do { if let result, let scenario, let geography { try controller.export(AllocationReport(algorithmVersion: "capped-cost-need-v1", createdAt: Date(), geographySource: geography.source, scenario: scenario, services: services, indicators: indicators, result: result), to: url) } } catch { self.error = error.localizedDescription } }
 func updateBudget(_ cents: Int64) { guard var s = scenario else { return }; s.budgetCents = cents; do { try setScenario(s) } catch { self.error = error.localizedDescription } }
 func applyFinancePreset(_ preset: FinancePreset) {
  guard var value = scenario else { return }
  if let year = preset.finances.provenance?.referenceYear, year != value.priceYear {
   guard value.records.isEmpty else { error = "Mevcut maliyet kayıtlarının yılı farklı. Önce fiyat bazını uyumlu hale getirin veya ayrı senaryo içe aktarın."; return }
   value.priceYear = year
  }
  value.finances = preset.finances; value.budgetCents = preset.planningBudgetCents
  value.isDemo = value.isDemo || preset.finances.provenance?.status == "illustrative"
  if value.records.isEmpty { value.name = preset.name }
  do { try setScenario(value); dataNotice = "2025 finansman JSON verisi uygulandı. Nüfus ve mevcut hizmet kayıtları korundu." }
  catch { self.error = error.localizedDescription }
 }
 func updateFinances(_ finances: FinancialEnvelope) {
  guard var s = scenario else { return }; s.finances = finances
  do { try setScenario(s) } catch { self.error = error.localizedDescription }
 }
 func updateWeight(_ weight: Double) { guard var s = scenario else { return }; s.povertyWeight = weight; do { try setScenario(s) } catch { self.error = error.localizedDescription } }
 func upsert(_ record: NeedRecord) {
  guard var s = scenario else { return }
  s.records.removeAll { $0.districtID == record.districtID && $0.serviceID == record.serviceID }; s.records.append(record)
  do { try setScenario(s) } catch { self.error = error.localizedDescription }
 }
 func saveObservation(_ observation: IndicatorObservation) {
  guard var s = scenario, indicators.contains(where: { $0.id == observation.indicatorID }), !observation.source.isEmpty,
   observation.value == nil || (observation.value!.isFinite && observation.value! >= 0) else { error = "Gösterge, kaynak veya değer geçersiz."; return }
  var values = s.observations ?? []; values.removeAll { $0.id == observation.id }; values.append(observation); s.observations = values
  do { try setScenario(s) } catch { self.error = error.localizedDescription }
 }
 func removeSelectedRecord() {
  guard var s = scenario, let id = selectedDistrictID else { return }
  s.records.removeAll { $0.districtID == id && $0.serviceID == selectedServiceID }
  do { try setScenario(s) } catch { self.error = error.localizedDescription }
 }
 var districts: [District] {
  (geography?.districts ?? []).filter { (selectedProvinceID == nil || $0.provinceID == selectedProvinceID) && (search.isEmpty || $0.name.range(of: search, options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR")) != nil) }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
 }
 func povertyProfile(for id: String) -> PovertyProfile? { scenario?.povertyProfiles?.first { $0.geographyID == id } }
 var povertyDistrictCount: Int { (geography?.districts ?? []).filter { povertyProfile(for: $0.id)?.rate != nil }.count }
 func importPovertyDataset(_ url: URL) {
  do {
   let dataset = try controller.readPovertyDataset(url)
   guard dataset.schemaVersion == 1, var value = scenario, let geography else { throw PlanningError.invalid("Yoksulluk veri şeması veya çalışma alanı geçersiz.") }
   try PovertyResolver().validate(dataset.profiles, geography: geography)
   var profiles = Dictionary(uniqueKeysWithValues: (value.povertyProfiles ?? []).map { ($0.geographyID, $0) })
   for profile in dataset.profiles {
    if profiles[profile.geographyID]?.status == "observed" && profile.status != "observed" { continue }
    profiles[profile.geographyID] = profile
   }
   value.povertyProfiles = profiles.values.sorted { $0.geographyID < $1.geographyID }
   if dataset.profiles.contains(where: { $0.status == "estimated" }) { value.isDemo = true }
   try setScenario(value); dataNotice = "Yoksulluk profilleri kaydedildi. Etki için ağırlığı seçip Ağırlığı uygula düğmesine basın."
  } catch { self.error = error.localizedDescription }
 }
 func updatePovertyProfile(_ profile: PovertyProfile) {
  guard var value = scenario else { return }
  var profiles = value.povertyProfiles ?? []; profiles.removeAll { $0.geographyID == profile.geographyID }; profiles.append(profile)
  value.povertyProfiles = profiles
  if profile.status == "estimated" { value.isDemo = true }
  do { try setScenario(value) } catch { self.error = error.localizedDescription }
 }
 func populationObservation(for id: String) -> IndicatorObservation? {
  PopulationObservations().latest(in: scenario?.observations ?? [], geographyID: id)
 }
 var populationDistrictCount: Int {
  (geography?.districts ?? []).filter { populationObservation(for: $0.id) != nil }.count
 }
 func loadBundledPopulation() async {
  guard !isLoadingPopulation, let current = scenario, let geography else { return }
  isLoadingPopulation = true
  defer { isLoadingPopulation = false }
  do {
   let seed = try await controller.bundledPopulation()
   // Use the latest state after awaiting; do not discard edits made during loading.
   let active = scenario ?? current
   let merged = PopulationObservations().mergeMissing(seed: seed, into: active, geography: geography)
   if merged.added > 0 { try setScenario(merged.scenario) }
   dataNotice = "Paket nüfus verisi: " + String(merged.added) + " yeni gözlem eklendi. Mevcut kayıtlar korundu."
  } catch { self.error = error.localizedDescription }
 }
 func newRecord(districtID: String, serviceID: String) -> NeedRecord {
  var value = recordTemplate; value.districtID = districtID; value.serviceID = serviceID; value.referenceYear = scenario?.priceYear ?? 0
  if let observed = populationObservation(for: districtID)?.value { value.population = Int(observed) }
  return value
 }
 var currentRecord: NeedRecord? { scenario?.records.first { $0.districtID == selectedDistrictID && $0.serviceID == selectedServiceID } }
 var selectedDistrict: District? { geography?.districts.first { $0.id == selectedDistrictID } }
 private func rebuildPresentation(_ result: AllocationResult) {
  if let scenario, let geography {
   dataQuality = DataQualityReport.make(scenario: scenario, geography: geography, services: services)
   recordIndex = Dictionary(uniqueKeysWithValues: scenario.records.map { ($0.districtID + ":" + $0.serviceID, $0) })
   povertyIndex = Dictionary(uniqueKeysWithValues: (scenario.povertyProfiles ?? []).map { ($0.geographyID, $0) })
  }
  totalScore = result.rows.reduce(0) { $0 + $1.score }
  refreshComparison()
  serviceTotals = ServiceAllocationSummarizer().summarize(result, services: services)
  let provinces = Dictionary(uniqueKeysWithValues: (geography?.provinces ?? []).map { ($0.id, $0.name) })
  districtNames = Dictionary(uniqueKeysWithValues: (geography?.districts ?? []).map { ($0.id, (provinces[$0.provinceID] ?? "") + " / " + $0.name) })
  let search = RegionSearch()
  districtSearchNames = districtNames.mapValues { search.normalize($0) }
 }
 var filteredAllocationRows: [Allocation] { filteredRows(matching: allocationSearch) }
 var filteredDeploymentRows: [Allocation] { filteredRows(matching: deploymentSearch) }
 private func filteredRows(matching query: String) -> [Allocation] {
  let rows = result?.rows ?? []
  let search = RegionSearch(); let terms = search.tokens(query)
  guard !terms.isEmpty else { return rows }
  return rows.filter { row in
   let id = row.id.components(separatedBy: ":")[0]
   return search.matchesNormalized(districtSearchNames[id] ?? search.normalize(id), tokens: terms)
  }
 }
 func districtName(_ allocation: Allocation) -> String {
  let id = allocation.id.components(separatedBy: ":")[0]
  return districtNames[id] ?? id
 }
 func explanation(for row: Allocation) -> AllocationExplanation? {
  guard let record = recordIndex[row.id] else { return nil }
  let rate = PovertyResolver().rate(for: record, profiles: povertyIndex, hasProfileDataset: scenario?.povertyProfiles != nil)
  return AllocationExplanation(record: record, effectivePovertyRate: rate,
   scoreShare: totalScore > 0 ? row.score / totalScore : 0,
   fundingCoverage: row.requirementCents > 0 ? Double(row.allocatedCents) / Double(row.requirementCents) : 0,
   remainingGap: max(0, row.gap - row.estimatedUnits))
 }
 func currentSnapshot(name: String? = nil) -> SavedPlanningScenario? {
  guard let scenario, let geography else { return nil }
  return SavedPlanningScenario(id: UUID(), name: name ?? scenario.name, savedAt: Date(), algorithm: SavedPlanningScenario.algorithmID,
   geography: geography, scenario: scenario, services: services, indicators: indicators)
 }
 private func loadSavedScenarios() async {
  guard let snapshotStore else { return }
  do {
   savedScenarios = try await snapshotStore.load()
   if let first = savedScenarios.first { comparisonRightID = first.id.uuidString }
   snapshotError = nil; refreshComparison()
  } catch { snapshotError = error.localizedDescription }
 }
 func saveNamedScenario(_ name: String) async {
  guard !isSavingSnapshot, let snapshotStore else { return }
  snapshotNotice = nil
  let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
  guard !trimmed.isEmpty, trimmed.count <= 120 else { snapshotError = "review.nameRequired"; return }
  guard let snapshot = currentSnapshot(name: trimmed) else { return }
  isSavingSnapshot = true; defer { isSavingSnapshot = false }
  do {
   _ = try snapshot.calculate()
   try await snapshotStore.save(snapshot)
   savedScenarios.insert(snapshot, at: 0); comparisonRightID = snapshot.id.uuidString
   snapshotError = nil; snapshotNotice = "review.saved"; refreshComparison()
  } catch { snapshotError = error.localizedDescription }
 }
 func requestComparisonSelection(_ id: String, left: Bool) {
  deferredSelections.enqueue(key: left ? "comparison.left" : "comparison.right") { [weak self] in
   guard let self, id == "current" || self.savedScenarios.contains(where: { $0.id.uuidString == id }) else { return }
   if left { self.comparisonLeftID = id } else { self.comparisonRightID = id }
   self.refreshComparison()
  }
 }
 private func refreshComparison() {
  guard !savedScenarios.isEmpty, let current = currentSnapshot() else { scenarioComparison = nil; return }
  let left = comparisonLeftID == "current" ? current : savedScenarios.first { $0.id.uuidString == comparisonLeftID }
  let right = comparisonRightID == "current" ? current : savedScenarios.first { $0.id.uuidString == comparisonRightID }
  guard let left, let right else { scenarioComparison = nil; return }
  do { scenarioComparison = try ScenarioComparison.make(left: left, right: right); comparisonError = nil }
  catch { scenarioComparison = nil; comparisonError = error.localizedDescription }
 }

}
