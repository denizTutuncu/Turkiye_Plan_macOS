import Foundation
nonisolated struct ServiceAllocationSummary: Identifiable, Sendable {
 let id: String
 let name: String
 let allocatedCents: Int64
}
nonisolated struct ServiceAllocationSummarizer {
 func summarize(_ result: AllocationResult, services: [Service]) -> [ServiceAllocationSummary] {
  var totals: [String: Int64] = [:]
  for row in result.rows { totals[row.serviceID, default: 0] += row.allocatedCents }
  return services.map { ServiceAllocationSummary(id: $0.id, name: $0.name, allocatedCents: totals[$0.id, default: 0]) }
 }
}
