import Foundation
import Combine
import SwiftUI

/// UI languages are independent of geography IDs, JSON field names and currency.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
 case system, en, tr, es, it, simplifiedChinese = "zh-Hans", hi, ar, fr, bn, pt, ru, ur
 var id: String { rawValue }
 var nativeName: String {
  switch self {
  case .system: return L10n.text("language.system")
  case .en: return "English"
  case .tr: return "Türkçe"
  case .es: return "Español"
  case .it: return "Italiano"
  case .simplifiedChinese: return "简体中文"
  case .hi: return "हिन्दी"
  case .ar: return "العربية"
  case .fr: return "Français"
  case .bn: return "বাংলা"
  case .pt: return "Português"
  case .ru: return "Русский"
  case .ur: return "اردو"
  }
 }
 static func resolve(_ preferences: [String]) -> AppLanguage {
  for preference in preferences {
   let code = preference.replacingOccurrences(of: "_", with: "-")
   if code.hasPrefix("zh-Hans") || code == "zh" || code.hasPrefix("zh-CN") || code.hasPrefix("zh-SG") { return .simplifiedChinese }
   if let language = AppLanguage(rawValue: code.components(separatedBy: "-")[0]), language != .system { return language }
  }
  return .en
 }
}

nonisolated enum L10n {
 static let preferenceKey = "TurkiyePlan.interfaceLanguage"
 static var language: AppLanguage {
  let chosen = AppLanguage(rawValue: UserDefaults.standard.string(forKey: preferenceKey) ?? "system") ?? .system
  return chosen == .system ? AppLanguage.resolve(Locale.preferredLanguages) : chosen
 }
 static var locale: Locale { Locale(identifier: language.rawValue) }
 static var isRightToLeft: Bool { language == .ar || language == .ur }
 static func bundle(for language: AppLanguage) -> Bundle? {
  let code = language == .system ? AppLanguage.resolve(Locale.preferredLanguages).rawValue : language.rawValue
  // Xcode compiles the string catalog into standard .lproj bundles.
  guard let path = Bundle.main.path(forResource: code, ofType: "lproj") else { return nil }
  return Bundle(path: path)
 }
 static let tables: [String: [String: String]] = {
  var result: [String: [String: String]] = [:]
  for language in AppLanguage.allCases where language != .system {
   guard let bundle = bundle(for: language), let url = bundle.url(forResource: "Localizable", withExtension: "strings"),
         let data = try? Data(contentsOf: url),
         let table = (try? PropertyListSerialization.propertyList(from: data, format: nil)) as? [String: String] else { continue }
   result[language.rawValue] = table
  }
  return result
 }()
 static func text(_ key: String, language: AppLanguage? = nil) -> String {
  let chosen = language ?? self.language
  let selected = chosen == .system ? AppLanguage.resolve(Locale.preferredLanguages) : chosen
  return tables[selected.rawValue]?[key] ?? tables["en"]?[key] ?? key
 }
 /// Numbered, whole-message placeholders let each language reorder arguments.
 static func format(_ key: String, _ arguments: String..., language: AppLanguage? = nil) -> String {
  let template = text(key, language: language)
  let regex = try! NSRegularExpression(pattern: "\\{([0-9]+)\\}")
  let source = template as NSString
  var result = template
  for match in regex.matches(in: template, range: NSRange(location: 0, length: source.length)).reversed() {
   guard let index = Int(source.substring(with: match.range(at: 1))), arguments.indices.contains(index), let range = Range(match.range, in: result) else { continue }
   result.replaceSubrange(range, with: arguments[index])
  }
  return result
 }
 /// Legacy domain errors remain language-neutral in storage and translate on display.
 /// Longest matches prevent shorter labels from changing a complete message first.
 static func message(_ source: String, language: AppLanguage? = nil) -> String {
  let dictionary = tables[(language ?? self.language).rawValue] ?? tables["en"] ?? [:]
  if let exact = dictionary[source] { return exact }
  let keys = dictionary.keys.filter { $0.count > 3 && source.contains($0) }.sorted { $0.count > $1.count }
  guard !keys.isEmpty else { return source }
  let pattern = keys.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
  guard let regex = try? NSRegularExpression(pattern: pattern) else { return source }
  var result = source
  // Match original text only; never translate a replacement or an inserted argument again.
  for match in regex.matches(in: source, range: NSRange(source.startIndex..., in: source)).reversed() {
   guard let originalRange = Range(match.range, in: source), let range = Range(match.range, in: result) else { continue }
   let key = String(source[originalRange])
   result.replaceSubrange(range, with: dictionary[key] ?? key)
  }
  return result
 }

}

@MainActor final class LocalizationSettings: ObservableObject {
 static let shared = LocalizationSettings()
 @Published var language: AppLanguage {
  didSet { UserDefaults.standard.set(language.rawValue, forKey: L10n.preferenceKey) }
 }
 private init() { language = AppLanguage(rawValue: UserDefaults.standard.string(forKey: L10n.preferenceKey) ?? "system") ?? .system }
}

struct LanguageMenu: View {
 @ObservedObject private var settings = LocalizationSettings.shared
 var body: some View {
  Menu {
   ForEach(AppLanguage.allCases) { language in
    Button {
     settings.language = language
    } label: {
     if settings.language == language { Label(language.nativeName, systemImage: "checkmark") }
     else { Text(language.nativeName) }
    }
   }
  } label: { Label(L10n.text("language.title"), systemImage: "globe") }
   .fixedSize().accessibilityIdentifier("languageMenu")
   .help(L10n.text("language.help"))
 }
}

/// Updating language refreshes text and locale without rebuilding editors or losing draft input.
struct LocalizedPlanningRoot: View {
 @ObservedObject private var settings = LocalizationSettings.shared
 let viewModel: PlanningViewModel
 let tab: AppTab
 var body: some View {
  let _ = settings.language
  PlanningScreen(vm: viewModel, tab: tab)
   .environment(\.locale, L10n.locale)
   .environment(\.layoutDirection, L10n.isRightToLeft ? .rightToLeft : .leftToRight)
 }
}

extension Service {
 var localizedName: String { L10n.text(name) }
 var localizedUnit: String { L10n.text(unit) }
}
extension IndicatorDefinition {
 var localizedName: String { L10n.text(name) }
 var localizedUnit: String { L10n.text(unit) }
}

struct LocalizedSettingsView: View {
 @ObservedObject private var settings = LocalizationSettings.shared
 var body: some View {
  let _ = settings.language
  VStack(alignment: .leading, spacing: 16) {
   Text(L10n.text("Türkiye Kamu Planı • yerel SwiftData deposu"))
   LanguageMenu()
  }.padding().environment(\.locale, L10n.locale)
   .environment(\.layoutDirection, L10n.isRightToLeft ? .rightToLeft : .leftToRight)
 }
}
