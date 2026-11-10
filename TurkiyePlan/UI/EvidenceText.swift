import SwiftUI

/// Generated citation details retain the original reference and identifiers.
nonisolated enum EvidenceLocalization {
 static func summaryKey(for text: String) -> String? {
  if text.hasPrefix("ILLUSTRATIVE SERVICE INPUTS, NOT MEASURED DISTRICT DATA.") { return "evidence.serviceAssumptions" }
  if text.hasPrefix("TÜİK ADNKS ") { return "evidence.population" }
  if text.hasPrefix("ILLUSTRATIVE SCENARIO PROXY") { return "evidence.povertyProxy" }
  return nil
 }
}

struct EvidenceText: View {
 @ObservedObject private var localization = LocalizationSettings.shared
 let original: String
 var body: some View {
  VStack(alignment: .leading, spacing: 5) {
   if L10n.tables["tr"]?[original] != nil {
    Text(L10n.text(original)).textSelection(.enabled)
    if L10n.text(original) != original { originalDisclosure }
   } else if let key = EvidenceLocalization.summaryKey(for: original) {
    Text(L10n.text(key)).foregroundStyle(.secondary)
    originalDisclosure
   } else { originalDisclosure }
  }
 }
 private var originalDisclosure: some View {
  DisclosureGroup(L10n.text("evidence.original")) {
   Text(verbatim: original).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
  }
 }
}
