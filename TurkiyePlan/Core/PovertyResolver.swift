import Foundation
nonisolated struct PovertyResolver {
 func validate(_ profiles: [PovertyProfile], geography: Geography) throws {
  let ids = Set(geography.provinces.map(\.id) + geography.districts.map(\.id))
  guard Set(profiles.map(\.geographyID)).count == profiles.count else { throw PlanningError.invalid("Yinelenen yoksulluk profili kimliği.") }
  for p in profiles {
   guard ids.contains(p.geographyID), ["observed", "estimated", "missing"].contains(p.status), (1...9999).contains(p.referenceYear), !p.definitionID.isEmpty else { throw PlanningError.invalid("Yoksulluk profilinin kimliği, durumu, tanımı veya yılı geçersiz: " + p.geographyID) }
   if p.status == "missing" { guard p.rate == nil else { throw PlanningError.invalid("Veri yok durumunda oran null olmalı.") }; continue }
   guard let rate = p.rate, rate.isFinite, (0...1).contains(rate), !p.sourceURL.isEmpty, !p.method.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw PlanningError.invalid("Yoksulluk oranı 0–1 arasında olmalı; kaynak ve yöntem gerekli: " + p.geographyID) }
  }
 }
 func rate(for record: NeedRecord, profiles: [String: PovertyProfile], hasProfileDataset: Bool) -> Double? {
  if hasProfileDataset { return profiles[record.districtID]?.rate }
  // Legacy zero was an unknown placeholder, not a measured zero. Positive legacy inputs remain compatible.
  guard let legacy = record.povertyRate, legacy > 0 else { return nil }
  return legacy
 }
}
