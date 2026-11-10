import Foundation
protocol AllocationCalculating: Sendable { func calculate(_ scenario: Scenario, geography: Geography, services: [Service]) throws -> AllocationResult }
nonisolated struct AllocationEngine: AllocationCalculating {
 func calculate(_ s: Scenario, geography g: Geography, services: [Service]) throws -> AllocationResult {
  let districtIDs = Set(g.districts.map(\.id)); let serviceIDs = Set(services.map(\.id))
  guard g.schemaVersion == 1, Set(g.provinces.map(\.id)).count == g.provinces.count,
   districtIDs.count == g.districts.count, serviceIDs.count == services.count,
   g.districts.allSatisfy({ d in g.provinces.contains { $0.id == d.provinceID } }) else { throw PlanningError.invalid("Coğrafya kimlikleri veya şema geçersiz.") }
  guard (1...9999).contains(s.priceYear), s.budgetCents >= 0, s.budgetCents <= 9_000_000_000_000_000, s.povertyWeight.isFinite, (0...10).contains(s.povertyWeight) else { throw PlanningError.invalid("Bütçe veya ağırlık geçersiz.") }
  if let f = s.finances {
   let parts = [f.ownRevenueCents, f.externalTransfersCents, f.committedSpendingCents, f.debtServiceCents, f.reserveCents]
   guard parts.allSatisfy({ $0 >= 0 && $0 <= FinancialEnvelope.maximumComponentCents }), s.budgetCents <= f.availableCents else { throw PlanningError.invalid("Plan bütçesi kullanılabilir finansmanı aşıyor veya mali girdiler geçersiz.") }
  }
  let observationIDs = s.observations?.map(\.id) ?? []
  guard Set(observationIDs).count == observationIDs.count,
   (s.observations ?? []).allSatisfy({ o in (districtIDs.contains(o.geographyID) || g.provinces.contains { $0.id == o.geographyID }) && !o.source.isEmpty && (o.value == nil || (o.value!.isFinite && o.value! >= 0)) }) else { throw PlanningError.invalid("Bölgesel gösterge verisi geçersiz.") }
  var keys = Set<String>()
  for r in s.records {
   guard districtIDs.contains(r.districtID) else { throw PlanningError.invalid("Bilinmeyen ilçe kimliği: " + r.districtID) }
   guard serviceIDs.contains(r.serviceID) else { throw PlanningError.invalid("Bilinmeyen hizmet kimliği: " + r.serviceID) }
   guard keys.insert(r.districtID + ":" + r.serviceID).inserted else { throw PlanningError.invalid("Aynı ilçe ve hizmet için birden fazla kayıt var: " + r.districtID + " / " + r.serviceID) }
   let issues = NeedRecordValidation().issues(r, priceYear: s.priceYear)
   if !issues.isEmpty { throw PlanningError.invalid(r.districtID + ":\n" + issues.joined(separator: "\n")) }
  }
  // Cost-weighted need, adjusted for poverty and fiscal capacity. Caps prevent overfunding.
  let requirements = s.records.map { Int64($0.requirementCents.rounded(.up)) }
  let resolver = PovertyResolver()
  try resolver.validate(s.povertyProfiles ?? [], geography: g)
  let profileMap = Dictionary(uniqueKeysWithValues: (s.povertyProfiles ?? []).map { ($0.geographyID, $0) })
  if s.povertyWeight > 0 {
   let active = s.records.filter { $0.requirementCents > 0 }
   for record in active where resolver.rate(for: record, profiles: profileMap, hasProfileDataset: s.povertyProfiles != nil) == nil {
    throw PlanningError.invalid("Yoksulluk ağırlığı açık fakat ilçe oranı bilinmiyor: " + record.districtID + ". Yoksulluk profili yükleyin veya ağırlığı 0 yapın; bilinmeyen oran 0 kabul edilmez.")
   }
   let participating = active.compactMap { profileMap[$0.districtID] }
   guard Set(participating.map(\.definitionID)).count <= 1, Set(participating.map(\.referenceYear)).count <= 1 else { throw PlanningError.invalid("Ağırlıklandırmada aynı yoksulluk tanımı ve referans yılı kullanılmalı. Bölgesel ve ulusal eşikler karıştırılamaz.") }
  }
  let scores = s.records.map { record in
   let rate = resolver.rate(for: record, profiles: profileMap, hasProfileDataset: s.povertyProfiles != nil)
   return record.requirementCents * (1 + s.povertyWeight * (rate ?? 0)) / record.fiscalCapacityIndex
  }
  guard scores.indices.allSatisfy({ scores[$0].isFinite && (requirements[$0] == 0 || scores[$0] > 0) }) else { throw PlanningError.invalid("Hesap sınırı aşıldı.") }
  var amounts = Array(repeating: Int64(0), count: requirements.count); var remaining = s.budgetCents
  var active = requirements.indices.filter { requirements[$0] > 0 }
  while remaining > 0 && !active.isEmpty {
   let maxScore = active.map { scores[$0] }.max() ?? 1
   let total = active.reduce(0.0) { $0 + scores[$1] / maxScore }
   let capped = active.filter { Double(remaining) * (scores[$0] / maxScore) / total >= Double(requirements[$0] - amounts[$0]) }
   if !capped.isEmpty {
    for i in capped { let value = requirements[i] - amounts[i]; amounts[i] += value; remaining -= value }
    active.removeAll { capped.contains($0) }; continue
   }
   let base = remaining
   for i in active { let value = min(remaining, Int64((Double(base) * (scores[i] / maxScore) / total).rounded(.down))); amounts[i] += value; remaining -= value }
   // Stable cent remainder by identifier, independent of imported row ordering.
   for i in active.sorted(by: { (s.records[$0].districtID + s.records[$0].serviceID) < (s.records[$1].districtID + s.records[$1].serviceID) }) where remaining > 0 {
    if amounts[i] < requirements[i] { amounts[i] += 1; remaining -= 1 }
   }
   active.removeAll { amounts[$0] >= requirements[$0] }
  }
  let rows = s.records.indices.map { i in Allocation(id: s.records[i].districtID + ":" + s.records[i].serviceID, serviceID: s.records[i].serviceID, gap: s.records[i].gap, requirementCents: requirements[i], score: scores[i], allocatedCents: amounts[i], estimatedUnits: requirements[i] == 0 ? 0 : s.records[i].gap * Double(amounts[i]) / Double(requirements[i])) }
  return AllocationResult(rows: rows, unallocatedCents: remaining, excludedDistrictCount: districtIDs.subtracting(Set(s.records.map(\.districtID))).count)
 }
}
