import Foundation
nonisolated struct GeographyValidation: Sendable {
 nonisolated func validate(_ geography: Geography) throws {
  let provinces = Set(geography.provinces.map(\.id))
  let districts = Set(geography.districts.map(\.id))
  guard geography.schemaVersion == 1, !provinces.isEmpty, !districts.isEmpty,
   provinces.count == geography.provinces.count, districts.count == geography.districts.count,
   provinces.isDisjoint(with: districts),
   geography.provinces.allSatisfy({ !$0.id.isEmpty && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
   geography.districts.allSatisfy({ provinces.contains($0.provinceID) && !$0.id.isEmpty && !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
   throw PlanningError.invalid("Coğrafya şeması, kimlikleri veya il–ilçe ilişkileri geçersiz.")
  }
 }
}
protocol ScenarioValidating: Sendable {
 nonisolated func validate(_ scenario: Scenario, geography: Geography) throws -> AllocationResult
}
nonisolated struct PlanningValidation: ScenarioValidating {
 let services: [Service]
 let indicators: [IndicatorDefinition]
 let calculator: any AllocationCalculating
 nonisolated func validate(_ value: Scenario, geography: Geography) throws -> AllocationResult {
  try GeographyValidation().validate(geography)
  if let metadata = value.finances?.provenance {
   guard metadata.referenceYear == value.priceYear, ["reported", "illustrative", "user_edited"].contains(metadata.status) else {
    throw PlanningError.invalid("Finansman yılı planın fiyat yılıyla aynı olmalı; durum reported, illustrative veya user_edited olmalı.")
   }
  }
  guard !value.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
   (value.observations ?? []).allSatisfy({ observation in
    guard let definition = indicators.first(where: { $0.id == observation.indicatorID }), (1...9999).contains(observation.referenceYear) else { return false }
    if definition.unit == "oran 0–1", let observed = observation.value { return (0...1).contains(observed) }
    return true
   }) else { throw PlanningError.invalid("Senaryo adı, gösterge kimliği, oranı veya yılı geçersiz.") }
  return try calculator.calculate(value, geography: geography, services: services)
 }
}
