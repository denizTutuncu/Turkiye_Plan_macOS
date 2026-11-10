import SwiftUI

struct DataQualityDashboard: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 var body: some View {
  GroupBox(L10n.text("review.quality")) {
   if let quality = vm.dataQuality {
    VStack(alignment: .leading, spacing: 12) {
     Text(L10n.text("review.qualityNote")).font(.caption).foregroundStyle(.secondary)
     ReviewValue(key: "review.populationCoverage", value: String(quality.populationDistricts) + " / " + String(quality.districtCount))
     HStack {
      ReviewValue(key: "review.observedPoverty", value: String(quality.observedPovertyDistricts))
      ReviewValue(key: "review.estimatedPoverty", value: String(quality.estimatedPovertyDistricts))
      ReviewValue(key: "review.missingPoverty", value: String(quality.missingPovertyDistricts))
     }
     DisclosureGroup(L10n.text("review.serviceQuality")) {
      ForEach(quality.services) { row in
       VStack(alignment: .leading, spacing: 6) {
        Text(vm.services.first { $0.id == row.id }?.localizedName ?? row.id).bold()
        HStack {
         ReviewValue(key: "review.modeled", value: String(row.modeledDistricts))
         ReviewValue(key: "review.missing", value: String(row.missingDistricts))
         ReviewValue(key: "review.sourced", value: String(row.sourcedRecords))
         ReviewValue(key: "review.aligned", value: String(row.priceAlignedRecords))
        }
       }.padding(.vertical, 6)
      }
     }
     if let finance = vm.scenario?.finances?.provenance {
      Text(L10n.text(finance.status == "reported" ? "YAYIMLANAN GERÇEKLEŞME • merkezi yönetim bütçesi" : "VARSAYIM / KULLANICI GİRDİSİ • doğrulanmış serbest ödenek değildir")).font(.caption).foregroundStyle(.secondary)
      Text(String(finance.referenceYear) + " • " + finance.sourceURL).font(.caption).textSelection(.enabled)
     }
     Text(L10n.text(vm.scenario?.isDemo == true ? "review.estimateInputs" : "review.unverifiedInputs")).font(.caption).foregroundStyle(.orange)
    }.padding().frame(maxWidth: .infinity, alignment: .leading)
   }
  }
 }
}

struct ReviewValue: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let key: String
 let value: String
 var body: some View {
  VStack(alignment: .leading, spacing: 3) {
   Text(L10n.text(key)).font(.caption).foregroundStyle(.secondary)
   Text(value).monospacedDigit().textSelection(.enabled)
  }.frame(maxWidth: .infinity, alignment: .leading)
 }
}

struct AllocationBreakdown: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 let row: Allocation
 var body: some View {
  DisclosureGroup(L10n.text("review.explain")) {
   if let explanation = vm.explanation(for: row) {
    let r = explanation.record
    VStack(alignment: .leading, spacing: 12) {
     Text(L10n.text("review.gapStep")).bold()
     Text("max(0, ceil(" + number(Double(r.eligible)) + " × " + number(r.targetCoverage) + ") − " + number(Double(r.served)) + ") = " + number(row.gap)).monospaced()
     Text(L10n.text("review.costStep")).bold()
     HStack {
      ReviewValue(key: "Birim yatırım maliyeti", value: money(r.capitalUnitCents))
      ReviewValue(key: "Birim yıllık işletme maliyeti", value: money(r.annualUnitCents))
      ReviewValue(key: "İşletme süresi (yıl)", value: String(r.horizonYears))
     }
     HStack {
      ReviewValue(key: "Hizmet maliyeti endeksi (>0)", value: number(r.deliveryCostIndex))
      ReviewValue(key: "review.requirementRounded", value: money(row.requirementCents))
     }
     Text(L10n.text("review.priorityStep")).bold()
     HStack {
      ReviewValue(key: "Yoksulluk oranı", value: explanation.effectivePovertyRate.map { number($0 * 100) + "%" } ?? L10n.text("Bilinmiyor"))
      ReviewValue(key: "Yoksulluk ağırlığı", value: number(vm.scenario?.povertyWeight ?? 0))
      ReviewValue(key: "Mali kapasite endeksi (>0)", value: number(r.fiscalCapacityIndex))
      ReviewValue(key: "Puan: ", value: number(row.score))
     }
     Text(L10n.text("review.distributionStep")).bold()
     HStack {
      ReviewValue(key: "review.scoreShare", value: number(explanation.scoreShare * 100) + "%")
      ReviewValue(key: "Tahsis: ", value: money(row.allocatedCents))
      ReviewValue(key: "review.fundedPercent", value: row.requirementCents > 0 ? number(explanation.fundingCoverage * 100) + "%" : L10n.text("review.noPositiveRequirement"))
      ReviewValue(key: "review.remainingUnits", value: number(explanation.remainingGap))
     }
     Text(L10n.text("review.capNote")).font(.caption).foregroundStyle(.secondary)
     Text(L10n.text("review.estimatedUnitsNote")).font(.caption).foregroundStyle(.secondary)
     HStack {
      ReviewValue(key: "Maliyetlerin fiyat yılı", value: String(r.referenceYear))
      ReviewValue(key: "Durum", value: L10n.text(vm.scenario?.isDemo == true ? "review.estimateInputs" : "review.unverifiedInputs"))
     }
     EvidenceText(original: r.source).font(.caption)
     if let profile = vm.povertyProfile(for: r.districtID) {
      Text(L10n.text(profile.status) + " • " + String(profile.referenceYear) + " • " + profile.definitionID).font(.caption)
      Text(profile.sourceURL).font(.caption).textSelection(.enabled)
      EvidenceText(original: profile.method).font(.caption)
     }
    }.padding(.top, 8)
   }
  }.accessibilityIdentifier("allocationBreakdown-" + row.id)
 }
}

struct ScenarioLibraryView: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 @ObservedObject var vm: PlanningViewModel
 @State private var name = ""
 var body: some View {
  GroupBox(L10n.text("review.scenarios")) {
   VStack(alignment: .leading, spacing: 14) {
    Text(L10n.text("review.snapshotNote")).font(.caption).foregroundStyle(.secondary)
    HStack {
     TextField(L10n.text("review.scenarioName"), text: $name).textFieldStyle(.roundedBorder)
     Button(L10n.text("review.saveSnapshot")) { Task { await vm.saveNamedScenario(name) } }
      .disabled(vm.scenario == nil || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSavingSnapshot)
      .accessibilityIdentifier("saveNamedScenario")
     if vm.isSavingSnapshot { ProgressView().controlSize(.small) }
    }
    if let notice = vm.snapshotNotice { Text(L10n.text(notice)).font(.caption).foregroundStyle(.secondary) }
    if let error = vm.snapshotError { Text(L10n.message(error)).foregroundStyle(.red).textSelection(.enabled) }
    if vm.savedScenarios.isEmpty { Text(L10n.text("review.noSnapshots")).foregroundStyle(.secondary) }
    else {
     DisclosureGroup(L10n.text("review.compare")) {
      VStack(alignment: .leading, spacing: 14) {
       HStack {
        scenarioPicker(left: true)
        scenarioPicker(left: false)
       }
       Text(L10n.text("review.deltaDirection")).font(.caption).foregroundStyle(.secondary)
       if let error = vm.comparisonError { Text(L10n.message(error)).foregroundStyle(.red) }
       if let comparison = vm.scenarioComparison {
        HStack(alignment: .top) {
         ScenarioSummaryColumn(snapshot: comparison.left, result: comparison.leftResult)
         ScenarioSummaryColumn(snapshot: comparison.right, result: comparison.rightResult)
        }
        if let reason = comparison.incompatibility { Text(L10n.text(reason)).foregroundStyle(.orange) }
        else { ScenarioComparisonResults(comparison: comparison) }
       }
      }.padding(.top, 10)
     }
    }
   }.padding().frame(maxWidth: .infinity, alignment: .leading)
  }
 }
 private func scenarioPicker(left: Bool) -> some View {
  Picker(L10n.text(left ? "review.left" : "review.right"), selection: Binding(
   get: { left ? vm.comparisonLeftID : vm.comparisonRightID },
   set: { vm.requestComparisonSelection($0, left: left) })) {
    Text(L10n.text("review.current")).tag("current")
    ForEach(vm.savedScenarios) { snapshot in
     Text(snapshot.name + " • " + snapshot.savedAt.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened).locale(L10n.locale)))
      .tag(snapshot.id.uuidString)
    }
   }
 }
}

struct ScenarioSummaryColumn: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let snapshot: SavedPlanningScenario
 let result: AllocationResult
 var body: some View {
  VStack(alignment: .leading, spacing: 8) {
   Text(L10n.text(snapshot.name)).font(.headline)
   if snapshot.scenario.isDemo { Text(L10n.text("SENTETİK DEMO")).font(.caption).foregroundStyle(.orange) }
   ReviewValue(key: "Plan bütçesi", value: money(snapshot.scenario.budgetCents))
   ReviewValue(key: "Dağıtılan", value: money(snapshot.scenario.budgetCents - result.unallocatedCents))
   ReviewValue(key: "Dağıtılmayan", value: money(result.unallocatedCents))
   ReviewValue(key: "Maliyetlerin fiyat yılı", value: String(snapshot.scenario.priceYear))
   ReviewValue(key: "Yoksulluk ağırlığı", value: number(snapshot.scenario.povertyWeight))
  }.padding().frame(maxWidth: .infinity, alignment: .leading).background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
 }
}

struct ScenarioComparisonResults: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let comparison: ScenarioComparison
 @State private var query = ""
 @State private var visibleLimit = 100
 var body: some View {
  let provinces = Dictionary(uniqueKeysWithValues: comparison.left.geography.provinces.map { ($0.id, $0.name) })
  let names = Dictionary(uniqueKeysWithValues: comparison.left.geography.districts.map { ($0.id, (provinces[$0.provinceID] ?? "") + " / " + $0.name) })
  let search = RegionSearch()
  let normalized = names.mapValues { search.normalize($0) }
  let terms = search.tokens(query)
  let matching = comparison.rows.filter { search.matchesNormalized(normalized[$0.districtID] ?? $0.districtID, tokens: terms) }
  VStack(alignment: .leading, spacing: 14) {
   Text(L10n.text("review.serviceComparison")).font(.headline)
   ForEach(comparison.services) { service in
    GroupBox(comparison.left.services.first { $0.id == service.id }?.localizedName ?? service.id) {
     VStack(alignment: .leading, spacing: 8) {
      ComparisonValueRow(key: "Tahsis: ", left: money(service.leftCents), right: money(service.rightCents), delta: money(service.rightCents - service.leftCents))
      ComparisonValueRow(key: "review.additionalUnits", left: number(service.leftAdditionalUnits), right: number(service.rightAdditionalUnits), delta: number(service.rightAdditionalUnits - service.leftAdditionalUnits))
      ComparisonValueRow(key: "review.remainingUnits", left: number(service.leftRemainingGap), right: number(service.rightRemainingGap), delta: number(service.rightRemainingGap - service.leftRemainingGap))
      Text(comparison.left.services.first { $0.id == service.id }?.localizedUnit ?? service.id).font(.caption).foregroundStyle(.secondary)
     }.padding(8)
    }
   }
   Text(L10n.text("review.unitNote")).font(.caption).foregroundStyle(.secondary)
   DisclosureGroup(L10n.text("review.districtComparison")) {
    VStack(alignment: .leading, spacing: 12) {
     RegionResultsSearch(query: $query, fieldIdentifier: "comparisonRegionSearch")
     Text(L10n.format("search.count", String(min(visibleLimit, matching.count)), String(matching.count), String(comparison.rows.count))).font(.caption)
     if matching.isEmpty { Text(L10n.text("Eşleşen kayıt yok")) }
     ForEach(Array(matching.prefix(visibleLimit))) { row in
      VStack(alignment: .leading, spacing: 5) {
       Text((names[row.districtID] ?? row.districtID) + " • " + (comparison.left.services.first { $0.id == row.serviceID }?.localizedName ?? row.serviceID)).bold()
       ComparisonValueRow(key: "Tahsis: ", left: money(row.left.allocatedCents), right: money(row.right.allocatedCents), delta: money(row.deltaCents))
       ComparisonValueRow(key: "Karşılanmayan finansman: ", left: money(row.left.requirementCents - row.left.allocatedCents), right: money(row.right.requirementCents - row.right.allocatedCents), delta: money((row.right.requirementCents - row.right.allocatedCents) - (row.left.requirementCents - row.left.allocatedCents)))
       ComparisonValueRow(key: "review.remainingUnits", left: number(max(0, row.left.gap - row.left.estimatedUnits)), right: number(max(0, row.right.gap - row.right.estimatedUnits)), delta: number(max(0, row.right.gap - row.right.estimatedUnits) - max(0, row.left.gap - row.left.estimatedUnits)))
      }.padding(.vertical, 6)
     }
     if visibleLimit < matching.count { Button(L10n.text("Sonraki 100 kaydı göster")) { visibleLimit += 100 } }
    }.padding(.top, 8)
   }
  }.onChange(of: query) { _, _ in visibleLimit = 100 }
   .onChange(of: comparison.left.id) { _, _ in visibleLimit = 100 }
   .onChange(of: comparison.right.id) { _, _ in visibleLimit = 100 }
 }
}

struct ComparisonValueRow: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let key: String
 let left: String
 let right: String
 let delta: String
 var body: some View {
  HStack(alignment: .top) {
   Text(L10n.text(key)).frame(maxWidth: .infinity, alignment: .leading)
   ReviewValue(key: "review.left", value: left)
   ReviewValue(key: "review.right", value: right)
   ReviewValue(key: "review.delta", value: delta)
  }
 }
}
