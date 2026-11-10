import Foundation
nonisolated struct RegionSearch {
 func normalize(_ text: String) -> String {
  text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "tr_TR"))
   .replacingOccurrences(of: "ı", with: "i").lowercased()
 }
 func tokens(_ query: String) -> [String] {
  normalize(query).components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
 }
 func matches(_ text: String, query: String) -> Bool { matchesNormalized(normalize(text), tokens: tokens(query)) }
 func matchesNormalized(_ text: String, tokens: [String]) -> Bool { tokens.allSatisfy { text.contains($0) } }
}
