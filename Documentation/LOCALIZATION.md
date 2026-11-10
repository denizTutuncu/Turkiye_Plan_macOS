# Localization

The app supports English (en), Turkish (tr), Spanish (es), Italian (it), Simplified Chinese (zh-Hans), Hindi (hi), Arabic (ar), French (fr), Bengali (bn), Portuguese (pt) and Urdu (ur). The globe menu appears in every screen header and in Settings. The default follows supported system language preferences, falling back to English. An explicit choice is saved in UserDefaults and applies on subsequent launches.

## Resources and architecture

- `TurkiyePlan/Resources/Localizable.xcstrings` is the sole translation catalog: 385 entries, each with all 12 translations. Xcode compiles it into standard localized `.strings` resources. Do not copy compiled `.lproj` output into source control.
- `Utils/Localization.swift` contains the supported-language model, lookup and whole-message formatting helpers, preference object, language menu and localized root wrapper.
- `L10n.text` resolves strings for the selected language. English is the fallback for missing translations; unknown custom labels remain verbatim. Turkish values equal to Turkish keys are valid and never mistaken for missing translations.
- `L10n.format` supports numbered `{0}`, `{1}` placeholders so translations can reorder arguments without changing code. Arguments are inserted once, never interpreted as format strings.
- Legacy validation and loading messages are translated on display using exact/longest matches against original text. Diagnostic identifiers remain unchanged. Future diagnostics should use stable semantic keys and whole-message placeholders.
- SwiftUI content receives the selected Locale and right-to-left layout for Arabic and Urdu. Views observe language changes without changing their identity, preserving editor drafts. AppKit tab labels and the window title refresh on the next main-queue turn.
- Native macOS menus and open/save panels use macOS's application/system language behavior; the in-app override controls our custom interface. Use macOS per-app language settings if the native panels must use the same language.

## Data boundaries

Province/district names, JSON keys, status codes (`observed`, `estimated`, `missing`), identifiers, budgets and calculations are not translated or rewritten. Catalog labels translate service/indicator names and units at display time. Known bundled scenario captions, finance preset names, finance titles and explanatory notes translate at display time, including copies already saved in the local workspace. Custom scenario names remain unchanged. EvidenceText shows localized explanations for known citation formats and an expandable Original source text section. Arbitrary imported prose is shown explicitly as original text, without rewriting stored citations, methods or editable source fields. No JSON dataset or SwiftData schema changed, and no reimport or migration is needed.

Currency remains TRY in every language. Amount/date formatting and typed numeric form controls use the selected locale. Raw text fields for IDs, whole-number budget kuruş, indicator decimal values and poverty rates keep their existing input contracts; the latter two explicitly request a decimal point. Changing language does not change the values.

## Editing translations

Open Localizable.xcstrings in Xcode. Add translations for every supported locale. Keep all `{n}` tokens, formula operators, identifiers, units and warning meanings intact. Add semantic keys for new text, call L10n.text/format from presentation code, and run `python3 Documentation/verify-localizations.py` plus Xcode tests.

## Verification

Static checks confirm key coverage, placeholder consistency, Swift grammar, unchanged JSON datasets, and untranslated schema status tags. XCTest coverage validates compiled catalog availability, fallback behavior, language resolution, placeholder substitution and diagnostic IDs. The existing UI smoke test pins Turkish to remain independent of developer language preferences.

No macOS SDK/Xcode is available in the editing environment: native compilation, catalog compilation, XCTest execution and visual RTL/long-text checks must be run on a Mac. Before release, review translation wording with native speakers and check all tabs at narrow window sizes, particularly Arabic/Urdu and long finance labels. On the Mac, build, open the globe menu, select each language, navigate all tabs, edit a draft then switch language, quit/relaunch to check the preference, and verify the same allocation totals.
