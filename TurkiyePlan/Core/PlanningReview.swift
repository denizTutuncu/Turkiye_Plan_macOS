import Foundation

nonisolated struct ServiceDataQuality: Identifiable, Sendable {
 let id: String
 let modeledDistricts: Int
 let missingDistricts: Int
 let sourcedRecords: Int
 let priceAlignedRecords: Int
}
nonisolated struct DataQualityReport: Sendable {
 let districtCount: Int
 let populationDistricts: Int
 let observedPovertyDistricts: Int
 let estimatedPovertyDistricts: Int
 let missingPovertyDistricts: Int
 let services: [ServiceDataQuality]
 static func make(scenario: Scenario, geography: Geography, services: [Service]) -> Self {
  let districts = Set(geography.districts.map(\.id))
  let populationGroups = Dictionary(grouping: scenario.observations ?? [], by: \.geographyID)
  let population = Set(districts.filter { id in
   guard let observation = PopulationObservations().latest(in: populationGroups[id] ?? [], geographyID: id) else { return false }
   return !observation.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  })
  let profiles = (scenario.povertyProfiles ?? []).filter { districts.contains($0.geographyID) && $0.rate != nil }
  let observed = Set(profiles.filter { $0.status == "observed" }.map(\.geographyID)).count
  let estimated = Set(profiles.filter { $0.status == "estimated" }.map(\.geographyID)).count
  let groups = Dictionary(grouping: scenario.records, by: \.serviceID)
  return Self(districtCount: districts.count, populationDistricts: population.count,
   observedPovertyDistricts: observed, estimatedPovertyDistricts: estimated,
   missingPovertyDistricts: districts.count - observed - estimated,
   services: services.map { service in
    let rows = groups[service.id] ?? []
    let count = Set(rows.map(\.districtID)).intersection(districts).count
    return ServiceDataQuality(id: service.id, modeledDistricts: count, missingDistricts: districts.count - count,
     sourcedRecords: rows.filter { !$0.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count,
     priceAlignedRecords: rows.filter { $0.referenceYear == scenario.priceYear }.count)
   })
 }
}

nonisolated struct AllocationExplanation: Sendable {
 let record: NeedRecord
 let effectivePovertyRate: Double?
 let scoreShare: Double
 let fundingCoverage: Double
 let remainingGap: Double
}

/// Captures all inputs and definitions needed to reproduce a named plan.
nonisolated struct SavedPlanningScenario: Codable, Identifiable, Sendable {
 static let algorithmID = "capped-cost-need-v1"
 let id: UUID
 let name: String
 let savedAt: Date
 let algorithm: String
 let geography: Geography
 let scenario: Scenario
 let services: [Service]
 let indicators: [IndicatorDefinition]
 func calculate() throws -> AllocationResult {
  guard algorithm == Self.algorithmID else { throw PlanningError.invalid("review.algorithm") }
  return try PlanningValidation(services: services, indicators: indicators, calculator: AllocationEngine()).validate(scenario, geography: geography)
 }
}

nonisolated struct ComparedAllocation: Identifiable, Sendable {
 let id: String
 let districtID: String
 let serviceID: String
 let left: Allocation
 let right: Allocation
 var deltaCents: Int64 { right.allocatedCents - left.allocatedCents }
}
nonisolated struct ComparedService: Identifiable, Sendable {
 let id: String
 let leftCents: Int64
 let rightCents: Int64
 let leftAdditionalUnits: Double
 let rightAdditionalUnits: Double
 let leftRemainingGap: Double
 let rightRemainingGap: Double
}
nonisolated struct ScenarioComparison: Sendable {
 let left: SavedPlanningScenario
 let right: SavedPlanningScenario
 let leftResult: AllocationResult
 let rightResult: AllocationResult
 /// A reason blocks numeric deltas; absolute scenario summaries remain available.
 let incompatibility: String?
 let services: [ComparedService]
 let rows: [ComparedAllocation]
 static func make(left: SavedPlanningScenario, right: SavedPlanningScenario) throws -> Self {
  let a = try left.calculate(); let b = try right.calculate()
  var reason: String?
  if left.scenario.priceYear != right.scenario.priceYear { reason = "review.priceMismatch" }
  let leftDistricts = Set(left.geography.districts.map { $0.id + ":" + $0.provinceID })
  let rightDistricts = Set(right.geography.districts.map { $0.id + ":" + $0.provinceID })
  if leftDistricts != rightDistricts || left.geography.source.revision != right.geography.source.revision { reason = "review.geographyMismatch" }
  let unitsA = Dictionary(uniqueKeysWithValues: left.services.map { ($0.id, $0.unit) })
  let unitsB = Dictionary(uniqueKeysWithValues: right.services.map { ($0.id, $0.unit) })
  if unitsA != unitsB { reason = "review.unitMismatch" }
  let recordsA = Dictionary(uniqueKeysWithValues: left.scenario.records.map { ($0.districtID + ":" + $0.serviceID, $0) })
  let recordsB = Dictionary(uniqueKeysWithValues: right.scenario.records.map { ($0.districtID + ":" + $0.serviceID, $0) })
  if Set(recordsA.keys) != Set(recordsB.keys) { reason = "review.recordMismatch" }
  if recordsA.contains(where: { key, value in recordsB[key].map { $0.horizonYears != value.horizonYears } ?? false }) { reason = "review.horizonMismatch" }
  // Comparisons must not silently mix regional/national poverty definitions.
  if left.scenario.povertyWeight > 0 && right.scenario.povertyWeight > 0 {
   let activeA = Set(left.scenario.records.filter { $0.requirementCents > 0 }.map(\.districtID))
   let activeB = Set(right.scenario.records.filter { $0.requirementCents > 0 }.map(\.districtID))
   let basesA = Set((left.scenario.povertyProfiles ?? []).filter { activeA.contains($0.geographyID) }.map { $0.definitionID + ":" + String($0.referenceYear) })
   let basesB = Set((right.scenario.povertyProfiles ?? []).filter { activeB.contains($0.geographyID) }.map { $0.definitionID + ":" + String($0.referenceYear) })
   if basesA != basesB || (left.scenario.povertyProfiles == nil && !activeA.isEmpty) || (right.scenario.povertyProfiles == nil && !activeB.isEmpty) { reason = "review.povertyMismatch" }
  }
  guard reason == nil else { return Self(left: left, right: right, leftResult: a, rightResult: b, incompatibility: reason, services: [], rows: []) }
  let byID = Dictionary(uniqueKeysWithValues: b.rows.map { ($0.id, $0) })
  let rows = a.rows.compactMap { row -> ComparedAllocation? in
   guard let other = byID[row.id], let record = recordsA[row.id] else { return nil }
   return ComparedAllocation(id: row.id, districtID: record.districtID, serviceID: row.serviceID, left: row, right: other)
  }
  let groupedA = Dictionary(grouping: a.rows, by: \.serviceID)
  let groupedB = Dictionary(grouping: b.rows, by: \.serviceID)
  let services = left.services.map { service in
   let x = groupedA[service.id] ?? []; let y = groupedB[service.id] ?? []
   return ComparedService(id: service.id,
    leftCents: x.reduce(0) { $0 + $1.allocatedCents }, rightCents: y.reduce(0) { $0 + $1.allocatedCents },
    leftAdditionalUnits: x.reduce(0) { $0 + $1.estimatedUnits }, rightAdditionalUnits: y.reduce(0) { $0 + $1.estimatedUnits },
    leftRemainingGap: x.reduce(0) { $0 + max(0, $1.gap - $1.estimatedUnits) }, rightRemainingGap: y.reduce(0) { $0 + max(0, $1.gap - $1.estimatedUnits) })
  }
  return Self(left: left, right: right, leftResult: a, rightResult: b, incompatibility: nil, services: services, rows: rows)
 }
}
