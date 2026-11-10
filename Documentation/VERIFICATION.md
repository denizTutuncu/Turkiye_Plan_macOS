# Verification • 2025 finance update

Checks performed:
- 26 Swift files passed tree-sitter grammar parsing. This is not native compiler type checking, concurrency checking or SwiftData macro expansion.
- All JSON resources parse.
- All four population/finance scenario files cover every app geography ID, have no invented service allocation records, match the 2025 finance reference year and pass independent numerical range/budget checks.
- Reported data reconcile to a 1,799,130,000,000 TRY deficit; the illustrative assumptions reconcile to 588,560,230,000 TRY available in that model.
- Original uploaded target IDs, bundle identifiers, signing teams and deployment target are preserved.
- Shared scheme XML parses; exactly one app @main is present.
- National-scale, old-payload decoding and financial balance regression tests are included.

Not performed: native Xcode build, SwiftData migration execution, XCTest/UI-test execution or visual UI verification. Run Product → Test and Product → Run on the Mac. The original project format is retained.

Save validation correction: shared field-specific record validation now drives both the form and engine. Blank/whitespace sources, incompatible price years and invalid counts have specific messages; invalid forms disable Save with visible reasons. Regression test sources are included but have not been executed on macOS.

Presentation correction: detail screens now render bounded lazy pages while retaining full-data calculations. Service aggregates are calculated once per allocation update and displayed as labelled SwiftUI bars. Tab selection is synchronized in both directions with AppKit; hosting uses a constrained child view. Service summary regression test source is included. Native compilation, visual verification and navigation tests are still outstanding in Xcode.

Poverty update: all 973 SEGE ranks mapped to app district IDs; all province rollups populated as estimates. Independent neutral-versus-weighted allocation check changed 7784 service rows and conserved the budget within need caps. Syntax/JSON checks passed. Native Swift compilation, regression tests and UI checks remain unexecuted here.

View-update publication correction: source-level inspection identified synchronous native-tab publication and routing from @Published willSet. These callbacks now defer/coalesce; native list/picker selection bindings use the same guarded boundary. Async unit-test source checks no-inline execution, latest-event wins and independent selection channels. The runtime warning cannot be confirmed resolved without a native macOS run and diagnostic stack.

## Twelve-language localization update

Added a complete 354-key / 12-language string catalog, persistent in-app language selection, locale formatting, right-to-left SwiftUI layouts, deferred AppKit tab-title updates, and localization XCTest coverage. Existing UI smoke tests explicitly select Turkish. Static catalog/placeholder and Swift grammar checks pass; all 18 existing JSON resource files are byte-identical to the supplied archive. Native build, catalog compilation, tests and visual layout verification require Xcode on a Mac and were not executed here.
