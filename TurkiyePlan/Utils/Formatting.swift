import Foundation
func money(_ cents: Int64) -> String { (Double(cents) / 100).formatted(.currency(code: "TRY").locale(L10n.locale).precision(.fractionLength(2))) }
func number(_ value: Double) -> String { value.formatted(.number.locale(L10n.locale).precision(.fractionLength(0...2))) }
