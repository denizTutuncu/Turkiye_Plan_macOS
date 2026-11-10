# Türkiye Kamu Planı • SwiftData edition

Native macOS 26.6+ app, Swift 6.2+, SwiftUI views hosted by AppKit view controllers. SwiftData persistence, MVVM, protocol-based controllers, injected data sources and tab routing. No third-party runtime dependencies.

## Open the integrated project
Unzip and open **TurkiyePlan.xcodeproj**. Choose the shared **TurkiyePlan** scheme, select **My Mac**, and Run. Use Product → Test to run the existing test targets with the added tests.

This is your supplied Xcode template with sources integrated. Your app/test target IDs, signing team, bundle identifiers, asset catalog and macOS 26.6 deployment target are preserved. The original modern `project.xcproj` format is preserved; use the Xcode version that created your template or a newer version supporting that format.

Starter Item, ContentView and TurkiyePlanApp files were replaced. The only @main is in Core/AppComposition.swift. The app's five main folders are already members of the synchronized app source folder, and test fixtures are included in the test target.

Swift language mode is set to Swift 6. MainActor is explicit at UI/persistence boundaries, rather than a project-wide default. Sandbox user-selected file access is Read/Write and outgoing client connections are enabled for optional APIs. API endpoints remain unset. Shared launch/test scheme uses Debug; archives use Release. See Documentation/XCODE-INTEGRATION.md for the integration record.

### Data loading order
For each persisted dataset:
1. Read saved SwiftData data.
2. Only when that dataset is absent, try its configured HTTPS API.
3. If no API is configured, or the API fails validation/network loading, use the bundled JSON seed.
4. Validate the complete workspace and persist the imported datasets before presenting them.

No API endpoint is configured by default. A cold first launch seeds the local store from `Resources/geography.json` and `Resources/empty-scenario.json`. Later launches read the database without contacting an API or reseeding. The bundled data is immutable seed data, not Swift constants. Counts are derived from records, not hardcoded.

An existing unreadable or invalid database is an error, not an empty store: it is preserved and never automatically deleted/replaced. There is no background refresh or cloud sync.

## Local persistence and imports
- The database lives in Application Support under the app's bundle identifier; its exact path appears in **Veri ve Kaynaklar**. Sandbox apps resolve Application Support inside their app container.
- Source province/district IDs are persisted with uniqueness constraints and an inverse province–district relationship.
- Source revision/metadata and a versioned active scenario snapshot are persisted with the geography.
- Successful imports and **Kaydet / Uygula** actions commit to SwiftData explicitly. Unapplied form text is a draft and is not autosaved.
- Validation and persistence must both succeed before new state is published to the UI.
- JSON export is a separate portable backup operation. Imported source files are not modified.
- **Coğrafya JSON içe aktar** validates current scenario references before replacing geography. A change that would orphan scenario records is rejected, not silently pruned.
- **Senaryo JSON içe aktar** replaces the active scenario after validation and local save. There is one active workspace in this version; no saved-scenario browser/history yet.

For a numerical example, import `Resources/demo-scenario.json`. It is explicitly synthetic and will become the active persisted scenario. Import `Resources/empty-scenario.json` to start a new empty plan.

## Architecture
The five main source folders remain Core, Navigation, Resources, UI and Utils. Supporting folders are Tests and Documentation.

| Layer | Responsibility |
|---|---|
| Core/AppComposition | Creates the container, repositories, validator, controllers, view model and router at the app level |
| Core/Persistence | Versioned SwiftData schema, storage protocol, DTO/entity mapping and explicit transactions |
| Core/LocalFirstWorkspaceLoader | Local → remote → bundled selection, validation and bootstrap save |
| Core/Repositories | Independent file and API adapters returning Codable/Sendable domain values |
| Core/AllocationEngine | Pure allocation calculation |
| UI | PlanningController protocol / ConcretePlanningController; view model; editable screens |
| Navigation | TabRouting / ConcreteTabRouter; PlanningViewControlling / ConcretePlanningViewController |

SwiftData ModelContext and @Model objects stay behind the persistence protocol. Views/view models receive value models and never fetch directly with @Query. The container is owned once at the composition root; no container is constructed by a view or controller. Contexts are main-actor isolated, short-lived and explicitly saved with rollback on error. This keeps actor ownership simple for the current small dataset. For large bulk imports, move the persistence implementation behind a ModelActor and async protocol while retaining the value-model boundary.

Geography is relational. The editable plan is a versioned Codable snapshot stored in SwiftData (external binary storage allowed). This deliberately supports atomic import/export for one active plan; it is not row-level queryable finance or observation storage. Normalize these records in a future version if cross-scenario SQL-style analysis or history becomes necessary.

## Configure a future API
Edit `Resources/app-config.json` before building:
- `geographyAPIURL`: null or your HTTPS endpoint returning Geography v1.
- `scenarioAPIURL`: null or your HTTPS endpoint returning the current Scenario DTO.
- `requestTimeoutSeconds`: injected request timeout.

No sample endpoint is presented as a functioning service. For a different API schema, add a DTO mapping adapter behind the existing repository protocol. Endpoints are used only for absent datasets; changing an endpoint does not overwrite existing local data. To update saved geography, use the explicit file import. Authentication, scheduled refresh and conflict resolution are future features.

## Included data
Bundled third-party reference geography: 81 provinces and 973 districts, snapshot 2026-06-19, Open Admin Data, CC BY 4.0. Attribution and source revision are included. This is not independently reconciled with the current official registry. IDs are source identifiers, not official administrative codes. Names preserve source spelling except dotted-i Unicode cleanup. Reconcile identifiers and spelling with official sources before using policy results.

There are no fabricated real-world financial or demographic observations. Service and indicator catalogues and the blank form template are injected JSON. The regional inventory supports province/district demographics, education, household income/costs, revenues, care and infrastructure indicators with source/year and null for unknown. It does not automatically transform raw observations into funding assumptions.

## Allocation
Gap = max(0, ceil(eligible × targetCoverage) − served).
Requirement = gap × (capital unit cost + annual operating unit cost × years) × delivery cost index.
Score = requirement × (1 + poverty weight × poverty rate) / fiscal capacity index.

Allocate proportionally, cap at each requirement and redistribute surplus. Remaining whole kuruş are assigned in stable identity order. Missing districts are excluded explicitly, not treated as zero need. Unneeded funding stays unallocated.

A financial envelope limits the budget to own revenue + external transfers − commitments − debt service − reserve. Inputs must be consolidated and expressed on the same horizon and constant-price basis. Costs include all operating years; there is no annual cash-flow forecast. Double is used for planning weights/requirements, while final budget allocations use Int64 kuruş with budget conservation; this is not a payments ledger.

Estimated service units are continuous planning estimates, not indivisible project approvals. No sector floors, procurement approvals, legal funding authorities or macroeconomic revenue forecasts are implied. The deployment view describes capital/operating coverage and missing delivery responsibilities.

## Build and verify
Open the included Xcode project and use Product → Test. No source copying, package generator or third-party dependencies are required. Test fixtures are read from the test bundle rather than the source checkout. The UI smoke test uses --ui-testing with a fresh in-memory database in Debug, so it cannot alter the normal saved workspace.

XCTest covers allocation invariants, fallback selection, validation, saved-data priority, save failure handling, in-memory SwiftData round trips and disk reopening. The unit and UI tests require macOS and were not executed in this Linux environment. Syntax parsing and dataset integrity checks were performed; native compiler type checking and UI verification remain outstanding. See `Documentation/VERIFICATION.md`.

## 2025 finance update
See Documentation/FINANCE-2025.md. In Dağıtım Matematiği, choose a JSON preset and click **2025 JSON verisini uygula**. The reported central-government baseline has a funding deficit and no unallocated surplus. A separately labelled what-if provides an illustrative envelope; it is not actual available money. The project includes both importable full scenarios and source/provenance JSON. Fields now update after data loading/import and show persistent labels. Your existing SwiftData plan is preserved until you explicitly apply a preset/import.

## Nationwide presentation correction
This complete project includes the populated nationwide Resources folder. Existing saved plans are retained. Result screens render the first 100 rows lazily with a button to reveal more; all 7,784 records still participate in calculation and JSON export. The overview uses eight cached service totals and labelled native SwiftUI bars instead of rebuilding Charts from thousands of records. Tab toolbar/manual/programmatic selection is synchronized, and child hosting has explicit constraints. The obsolete three-district note is removed. Stop the app, open this updated project, rebuild and run; no SwiftData reset or reimport is needed for an already-loaded scenario.

## Poverty model update
See Documentation/POVERTY-MODEL.md. Import poverty-profiles-2025.json through the dedicated Sources button to preserve current service/finance edits. The supplied SEGE-based district figures are illustrative proxies, not verified poverty measurements. Future observed rates can replace them in the same schema. Unknown is now null, not zero.

## Province/district search
Dağıtım Matematiği now has an İl / ilçe ara field immediately above the result list. It searches province/district names across the full allocation result before pagination. Turkish/ASCII spelling variants, case differences and combined queries such as İzmir Urla are supported. Changing the query resets the displayed limit to 100 matching rows; Sonraki 100 kaydı göster reveals more matching results. Clear removes the filter. No calculation, budget, source data, SwiftData record or JSON export scope is changed by searching. No resource reimport is required. Native UI verification remains to be performed on the Mac.

## View-update publication correction
Native tab selection previously wrote @Published state synchronously, and its Combine sink immediately routed native UI during the property's willSet notification. Both routing directions now pass through a coalesced next-main-queue boundary with stale-selection guards. Province/district/service framework selection setters also queue changes, rather than publishing while a native list/picker is reconciling. Data edits, calculations and persistence remain explicit and are not globally delayed. Search, poverty profiles and pagination are preserved. Native verification requires Xcode.
