import Foundation
func money(_ cents: Int64) -> String { (Double(cents) / 100).formatted(.currency(code: "TRY").precision(.fractionLength(2))) }
func number(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...2))) }
