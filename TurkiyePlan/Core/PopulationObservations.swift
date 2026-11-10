import Foundation
nonisolated struct PopulationObservations {
 func latest(in values: [IndicatorObservation], geographyID: String) -> IndicatorObservation? {
  values.filter { row in
   guard row.geographyID == geographyID, row.indicatorID == "population", let value = row.value else { return false }
   return value.isFinite && value >= 0 && value < Double(Int.max) && value.rounded() == value
  }.max { $0.referenceYear < $1.referenceYear }
 }
 func mergeMissing(seed: [IndicatorObservation], into scenario: Scenario, geography: Geography) -> (scenario: Scenario, added: Int) {
  let ids = Set(geography.provinces.map(\.id) + geography.districts.map(\.id))
  var result = scenario; var values = scenario.observations ?? []
  var keys = Set(values.map(\.id)); var added = 0
  for observation in seed where observation.indicatorID == "population" && ids.contains(observation.geographyID) {
   if keys.insert(observation.id).inserted { values.append(observation); added += 1 }
  }
  result.observations = values
  return (result, added)
 }
}
