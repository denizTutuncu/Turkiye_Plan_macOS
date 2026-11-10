import Foundation
import XCTest
@testable import TurkiyePlan
final class FinancePresetTests: XCTestCase {
 private func presets() throws -> [FinancePreset] { try JSONDecoder().decode([FinancePreset].self, from: Data(contentsOf: TestResources.url("finance-presets-2025"))) }
 func testReportedOutturnShowsDeficitRatherThanSurplus() throws {
  let value = try XCTUnwrap(presets().first { $0.id == "reported-2025" })
  XCTAssertEqual(value.finances.availableCents, 0)
  XCTAssertEqual(value.finances.fundingGapCents, 179_913_000_000_000)
  XCTAssertEqual(value.finances.provenance?.status, "reported")
  XCTAssertGreaterThan(value.finances.ownRevenueCents, 900_000_000_000_000)
 }
 func testIllustrativeEnvelopeReconcilesAndIsLabelled() throws {
  let value = try XCTUnwrap(presets().first { $0.id == "illustrative-2025" })
  let f = value.finances
  XCTAssertEqual(f.availableCents, 58_856_023_000_000)
  XCTAssertEqual(value.planningBudgetCents, f.availableCents)
  XCTAssertEqual(f.committedSpendingCents + f.debtServiceCents + f.reserveCents + f.availableCents, f.ownRevenueCents + f.externalTransfersCents)
  XCTAssertEqual(f.provenance?.status, "illustrative")
 }
 func testBothNationalEnvelopesPassValidationAtNationalScale() throws {
  let decoder = JSONDecoder()
  let geography = try decoder.decode(Geography.self, from: Data(contentsOf: TestResources.url("geography")))
  let services = try decoder.decode([Service].self, from: Data(contentsOf: TestResources.url("services")))
  let indicators = try decoder.decode([IndicatorDefinition].self, from: Data(contentsOf: TestResources.url("indicators")))
  let original = try decoder.decode(Scenario.self, from: Data(contentsOf: TestResources.url("population-observations")))
  for preset in try presets() {
   var scenario = original; scenario.finances = preset.finances; scenario.budgetCents = preset.planningBudgetCents
   let result = try PlanningValidation(services: services, indicators: indicators, calculator: AllocationEngine()).validate(scenario, geography: geography)
   XCTAssertEqual(result.unallocatedCents, preset.planningBudgetCents)
  }
 }
 func testLegacyEnvelopeWithoutProvenanceStillDecodes() throws {
  let json = #"{"ownRevenueCents":100,"externalTransfersCents":0,"committedSpendingCents":20,"debtServiceCents":5,"reserveCents":5}"#
  let f = try JSONDecoder().decode(FinancialEnvelope.self, from: Data(json.utf8))
  XCTAssertNil(f.provenance); XCTAssertEqual(f.availableCents, 70)
 }
}
