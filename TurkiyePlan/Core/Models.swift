import Foundation
nonisolated struct Province: Codable, Identifiable, Sendable { let id: String; let name: String }
nonisolated struct District: Codable, Identifiable, Sendable { let id: String; let provinceID: String; let name: String }
nonisolated struct DataSource: Codable, Sendable { let title: String; let url: String; let snapshot: String; let verification: String; let revision: String }
nonisolated struct Geography: Codable, Sendable { let schemaVersion: Int; let source: DataSource; let provinces: [Province]; let districts: [District] }
nonisolated struct Service: Codable, Identifiable, Sendable { let id: String; let name: String; let unit: String }
nonisolated struct NeedRecord: Codable, Equatable, Sendable {
 var districtID: String; var serviceID: String; var population: Int; var eligible: Int; var served: Int
 var targetCoverage: Double; var capitalUnitCents: Int64; var annualUnitCents: Int64; var horizonYears: Int
 var povertyRate: Double?; var deliveryCostIndex: Double; var fiscalCapacityIndex: Double
 var source: String; var referenceYear: Int
 var gap: Double { max(0, ceil(Double(eligible) * targetCoverage) - Double(served)) }
 var requirementCents: Double { gap * (Double(capitalUnitCents) + Double(annualUnitCents) * Double(horizonYears)) * deliveryCostIndex }
}
nonisolated struct Scenario: Codable, Sendable {
 var name: String; var isDemo: Bool; var priceYear: Int; var budgetCents: Int64; var povertyWeight: Double; var records: [NeedRecord]; var finances: FinancialEnvelope?; var observations: [IndicatorObservation]?; var povertyProfiles: [PovertyProfile]? = nil
}
nonisolated struct Allocation: Identifiable, Codable, Sendable {
 let id: String; let serviceID: String; let gap: Double; let requirementCents: Int64; let score: Double; let allocatedCents: Int64; let estimatedUnits: Double
}
nonisolated struct AllocationResult: Codable, Sendable { let rows: [Allocation]; let unallocatedCents: Int64; let excludedDistrictCount: Int }
nonisolated enum PlanningError: LocalizedError {
 case invalid(String)
 var errorDescription: String? { switch self { case .invalid(let text): text } }
}

nonisolated struct FinancialEnvelope: Codable, Equatable, Sendable {
 var ownRevenueCents: Int64
 var externalTransfersCents: Int64
 var committedSpendingCents: Int64
 var debtServiceCents: Int64
 var reserveCents: Int64
 var provenance: FinanceProvenance? = nil
 static let maximumComponentCents: Int64 = 9_000_000_000_000_000
 var rawBalanceCents: Int64 { ownRevenueCents + externalTransfersCents - committedSpendingCents - debtServiceCents - reserveCents }
 var availableCents: Int64 { max(0, rawBalanceCents) }
 var fundingGapCents: Int64 { max(0, -rawBalanceCents) }
}

nonisolated struct AllocationReport: Codable, Sendable {
 let algorithmVersion: String
 let createdAt: Date
 let geographySource: DataSource
 let scenario: Scenario
 let services: [Service]
 let indicators: [IndicatorDefinition]
 let result: AllocationResult
}

nonisolated struct IndicatorDefinition: Codable, Identifiable, Sendable { let id: String; let name: String; let unit: String }
nonisolated struct IndicatorObservation: Codable, Identifiable, Equatable, Sendable {
 var geographyID: String
 var indicatorID: String
 var referenceYear: Int
 var value: Double?
 var source: String
 var id: String { geographyID + ":" + indicatorID + ":" + String(referenceYear) }
}

nonisolated struct FinanceProvenance: Codable, Equatable, Sendable {
 var title: String
 var sourceURL: String
 var referenceYear: Int
 var scope: String
 var status: String
 var notes: [String]
 var assumptions: [String: Double]? = nil
}
nonisolated struct FinancePreset: Codable, Identifiable, Sendable {
 let id: String
 let name: String
 let planningBudgetCents: Int64
 let finances: FinancialEnvelope
}

nonisolated struct PovertyProfile: Codable, Identifiable, Equatable, Sendable {
 var geographyID: String
 var rate: Double?
 var status: String
 var referenceYear: Int
 var definitionID: String
 var sourceURL: String
 var method: String
 var proxyYear: Int? = nil
 var incomeReferenceYear: Int? = nil
 var proxyRank: Int? = nil
 var proxyScore: Double? = nil
 var benchmarkSourceURL: String? = nil
 var id: String { geographyID }
}
nonisolated struct PovertyDataset: Codable, Sendable {
 let schemaVersion: Int
 let profiles: [PovertyProfile]
}
