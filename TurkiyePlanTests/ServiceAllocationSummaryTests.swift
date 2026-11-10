import Foundation
import XCTest
@testable import TurkiyePlan
final class ServiceAllocationSummaryTests: XCTestCase {
 func testServiceTotalsReconcileToFullAllocationAndIncludeEveryService() throws {
  let decoder = JSONDecoder()
  let g = try decoder.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography")))
  let s = try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("demo-scenario")))
  let services = try decoder.decode([Service].self, from: Data(contentsOf: TestResources.url("services")))
  let result = try AllocationEngine().calculate(s, geography: g, services: services)
  let summary = ServiceAllocationSummarizer().summarize(result, services: services)
  XCTAssertEqual(summary.count, services.count)
  XCTAssertEqual(summary.reduce(Int64(0)) { $0 + $1.allocatedCents }, s.budgetCents - result.unallocatedCents)
  XCTAssertEqual(summary.map(\.id), services.map(\.id))
 }
}
