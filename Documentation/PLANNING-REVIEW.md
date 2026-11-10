# Planning review

## Data quality

Overview and Data and Sources display cached quality summaries. The report uses the current geography as the district denominator and reports missing district–service records explicitly. Population coverage requires a valid latest population observation and a nonblank source. Zero is a valid observation; null is unknown. Poverty counts distinguish source-reported observed profiles, estimates and missing district profiles. Citations and user-entered observed labels are not independently verified by the app.

Service inputs do not have per-field verification metadata. The dashboard reports source presence and price-year alignment, not verified service observations. Demo status is scenario-wide and does not prove the origin of an individual field. Source prose and methods remain verbatim.

## Allocation explanation

Each Allocation Math row expands to show the eligible/served/target gap calculation, investment cost, annual operation cost, horizon, delivery-cost index, rounded requirement, effective poverty rate, poverty weight, fiscal capacity, priority score, initial score share, final allocation, funded percentage and remaining target gap. Source, price year and district poverty methodology are included.

The score uses the engine's unrounded requirement. Funding requirements round up to whole kuruş. Initial score shares are not final allocation shares because caps, redistribution and deterministic kuruş rounding apply. Unknown poverty with zero weight is displayed as unknown. Remaining gap is a planning estimate, not observed delivery.

## Scenario snapshots

The app composition root injects `ScenarioSnapshotStoring`. Production uses the `JSONScenarioSnapshotStore` actor; UI tests use an in-memory actor. Named snapshots capture the scenario, geography, services, indicators, date, UUID and algorithm identifier. Each snapshot is an atomic UUID-named JSON file under Application Support/<bundle identifier>/SavedScenarios, adjacent to the active SwiftData store. The active SwiftData schema is unchanged.

Saving validates a captured value before writing. The UI publishes the saved entry only after the write succeeds. Save attempts are serialized while in progress. Reopening reads existing snapshot files. Corruption is reported and files are retained; it never triggers a reset. There is no snapshot overwrite or active-plan replacement operation.

## Comparison

A and B can independently select a named snapshot or the live active plan. Calculations use the captured definitions and geography. Changes are B minus A. Absolute budget summaries are shown for both plans. Numeric deltas require compatible price years, district IDs and parent relationships, geography source revisions, service IDs and units, district–service record sets, operating horizons and applicable poverty definitions/years. An unsupported algorithm is rejected.

A record absent from one plan is not manufactured as a zero. Different services are never combined into a single service-unit total. Each service reports funding, estimated additional units and remaining target gap. District results are searchable before pagination. Search and comparison selection do not persist or modify active plan inputs.

Snapshots are separate files and are not included in the active scenario's JSON export. Back up the SavedScenarios directory to retain the named library.

## Validation

PlanningReviewTests covers missing versus zero observations, source presence, allocation and remaining-gap deltas, incompatible price years, horizons, record sets and units, disk reopening and corruption preservation. XCTest and native UI behavior require Xcode on a Mac. Source grammar, catalog coverage and JSON integrity can be checked without Xcode.
