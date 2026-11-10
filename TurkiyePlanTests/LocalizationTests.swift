import XCTest
@testable import TurkiyePlan

final class LocalizationTests: XCTestCase {
 func testSystemLanguageResolution() {
  XCTAssertEqual(AppLanguage.resolve(["es-MX"]), .es)
  XCTAssertEqual(AppLanguage.resolve(["pt-BR"]), .pt)
  XCTAssertEqual(AppLanguage.resolve(["zh-Hans-CN"]), .simplifiedChinese)
  XCTAssertEqual(AppLanguage.resolve(["ur-PK"]), .ur)
  XCTAssertEqual(AppLanguage.resolve(["de-DE", "tr-TR"]), .tr)
  XCTAssertEqual(AppLanguage.resolve(["de-DE"]), .en)
 }
 func testAllTwelveCompiledCatalogsHaveIdenticalKeysAndPlaceholders() throws {
  let languages = AppLanguage.allCases.filter { $0 != .system }
  XCTAssertEqual(languages.count, 12)
  let reference = try XCTUnwrap(L10n.tables["en"], "Xcode must compile Localizable.xcstrings into the app bundle")
  let regex = try NSRegularExpression(pattern: "\\{[0-9]+\\}")
  func placeholders(_ string: String) -> [String] {
   regex.matches(in: string, range: NSRange(string.startIndex..., in: string))
    .map { (string as NSString).substring(with: $0.range) }.sorted()
  }
  for language in languages {
   let table = try XCTUnwrap(L10n.tables[language.rawValue], language.rawValue)
   XCTAssertEqual(Set(table.keys), Set(reference.keys), language.rawValue)
   for (key, value) in table {
    XCTAssertFalse(value.isEmpty, key)
    XCTAssertEqual(placeholders(value), placeholders(reference[key] ?? ""), language.rawValue + ": " + key)
   }
  }
 }
 func testTurkishDoesNotFallBackToEnglishAndUnknownNamesStayVerbatim() {
  XCTAssertEqual(L10n.text("Genel Bakış", language: .tr), "Genel Bakış")
  XCTAssertEqual(L10n.text("Genel Bakış", language: .en), "Overview")
  XCTAssertEqual(L10n.text("Custom source • İzmir / Urla 2025", language: .fr), "Custom source • İzmir / Urla 2025")
 }
 func testFormattingAndDiagnosticArgumentsRemainVerbatim() {
  XCTAssertEqual(L10n.format("district.count", "973", language: .en), "Districts: 973")
  XCTAssertEqual(L10n.format("search.count", "100", "500", "7784", language: .en), "Showing: 100 / 500 matches • 7784 total records")
  XCTAssertEqual(L10n.message("Bilinmeyen ilçe kimliği: TUR035017", language: .en), "Unknown district ID: TUR035017")
  XCTAssertEqual(L10n.format("district.count", "{1}", language: .en), "Districts: {1}")
 }
 func testSchemaStatusCodesAreIndependentOfLocalizedLabels() {
  XCTAssertNotEqual(L10n.text("estimated", language: .ar), "estimated")
  XCTAssertEqual(AppLanguage.tr.rawValue, "tr")
 }
}
