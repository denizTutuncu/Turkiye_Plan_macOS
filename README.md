# Türkiye Plan

Türkiye Plan is a native macOS app for exploring how public funding could improve services across Türkiye. It models district-level needs, delivery costs and funding allocations for healthcare, education, sports, childcare, senior care, electricity, water and sewage, and recycling.

Users can choose a budget, adjust poverty weighting, inspect individual allocations and compare funding with modeled service requirements. Calculations are shown alongside their inputs and assumptions.

## Run

1. Open `TurkiyePlan.xcodeproj` in Xcode with support for its `project.xcproj` format.
2. Select the **TurkiyePlan** scheme and **My Mac** destination.
3. Configure signing for your development team and run.

The deployment target is macOS 26.6. The app uses SwiftUI, AppKit, Combine and SwiftData, with no third-party runtime dependencies.

## Screens

| Screen | Purpose |
| --- | --- |
| Overview | Data quality, saved scenarios, side-by-side comparisons, geography counts, budget totals and allocations by service |
| Provinces and Districts | District selection, population observations, service inputs, poverty profiles and regional indicators |
| Allocation Math | Funding presets, financial envelope, budget, poverty weight, formulas and searchable allocation results |
| Implementation Plan | Unfunded requirements and estimated capital and operating coverage |
| Data and Sources | Storage details, source attribution, JSON imports and exports |

Result lists display 100 records at a time, with an action to show more. All valid records participate in calculations and exports. Province and district search is available in Allocation Math and Implementation Plan. Each screen keeps its own query and filters the full result set before pagination, without changing the budget or calculation scope. Clearing the query restores all results; changing it resets the visible limit to 100 matching rows. Search supports Turkish and ASCII spelling variants and combined names such as `İzmir Urla`.

## Languages

The globe menu and Settings provide English, Türkçe, Español, Italiano, 简体中文, हिन्दी, العربية, Français, বাংলা, Português, Русский and اردو.

The language preference is saved locally. The default follows supported system language preferences, with English as the fallback. Arabic and Urdu use right-to-left SwiftUI layouts. Numbers, currency and dates follow the selected locale; currency remains TRY.

Translations are maintained in `TurkiyePlan/Resources/Localizable.xcstrings`. Bundled scenario captions, finance preset names, finance titles and explanatory notes are translated for display. Province and district names and custom scenario names remain unchanged. Source evidence has localized summaries with expandable original text; editable source and method fields retain their original content. Native macOS dialogs follow macOS application language settings.

## Data and scenarios

The bundled geography contains 81 provinces and 973 districts. Counts are derived from the loaded records. Geography attribution, revision and licensing are included in the resources; source IDs are not official TÜİK/UAVT codes.

The resources include source-attributed 2025 population observations and published central-government budget figures. Nationwide demonstration scenarios contain 7,784 district–service records across eight services. Service demand, existing coverage, targets, costs and SEGE-informed district poverty profiles in these demonstrations are explicitly labeled assumptions, not verified district measurements.

Population observations are separate from service needs. A known population does not establish healthcare demand, existing coverage or delivery costs. Unknown observations use `null`, rather than a measured zero. Positive poverty weighting requires known, comparable rates for participating records, using the same poverty definition and reference year.

| Resource | Contents |
| --- | --- |
| `geography.json` | Provinces, districts and geography provenance |
| `services.json` | Service definitions and units |
| `indicators.json` | Regional indicator definitions and units |
| `record-template.json` | Inputs for a new service draft |
| `empty-scenario.json` | Bundled initial nationwide demonstration and population observations |
| `demo-scenario.json` | Synthetic demonstration scenario |
| `services-2025-complete-scenario.json` | Nationwide service planning scenario |
| `finance-presets-2025.json` | Reported and illustrative funding presets |
| `finance-source-2025.json` | Budget source figures and conversion units |
| `poverty-profiles-2025.json` | District poverty proxies and methodology |
| `Localizable.xcstrings` | Interface translations |
| `app-config.json` | Optional API URLs and request timeout |

A fresh workspace loads bundled geography and the nationwide demonstration in `empty-scenario.json`. Use **Import scenario JSON** to load a planning scenario. Use the dedicated poverty-profile import to update profiles while retaining service and finance inputs.

## Data quality and allocation explanations

The data-quality dashboard appears in Overview and Data and Sources. It shows district population coverage, source-reported and estimated poverty profiles, unknown poverty profiles, and data coverage by service. Service coverage includes modeled districts, missing districts, records with a source and records matching the plan price year.

A citation does not establish independent verification. Service records have no field-level verification status and remain unverified inputs; the demo flag is displayed separately. Missing records are not treated as zero need.

Each allocation in Allocation Math has an expandable calculation breakdown: the target service gap, investment and operating costs, operating horizon, delivery-cost adjustment, effective poverty rate, poverty weight, fiscal capacity, score share, final funding and remaining target gap. Sources and reference years are shown with the inputs. The initial score share is distinguished from the final allocation after caps and redistribution.

## Saved scenarios and comparison

In Overview, enter a name and save a snapshot of the active plan. Each snapshot captures its scenario, geography, service and indicator definitions, creation time and calculation method. Files are written atomically to `SavedScenarios` beside the active database. These files persist across launches and are separate from active-scenario JSON exports.

Select A and B from saved snapshots or the active plan. Comparisons show budget and allocation totals side by side, plus changes in funding, estimated additional service units and remaining target gaps by service and district. Changes are calculated as **B − A**. District comparisons support province/district search and pagination.

Numeric deltas are withheld when price years, geography revisions or district relationships, service units, record coverage, operating horizons or applicable poverty definitions are incompatible. Absolute scenario summaries remain visible. Units are summed within a service, never across different services. Saving and comparing do not replace the active plan. Corrupt snapshot files produce an error and are preserved.

## Allocation calculation

```text
Gap = max(0, ceil(eligible × target coverage) − served)

Requirement = gap
            × (capital unit cost + annual operating unit cost × years)
            × delivery cost index

Priority score = requirement
               × (1 + poverty weight × poverty rate)
               ÷ fiscal capacity index

Allocation = remaining budget × score ÷ total active scores
```

Allocations are capped at each record's requirement. Excess shares are redistributed among records with unmet requirements. Remaining whole kuruş are assigned in stable identity order. Funding left after all modeled requirements are met remains unallocated.

Estimated additional service units equal `gap × allocation ÷ requirement` for records with a positive requirement. These are continuous planning estimates, not project approvals or procurement commitments.

Financial inputs and final allocations use integer kuruş amounts. Weights and intermediate requirements use floating-point calculations. Costs must share a common price year and include the selected operating horizon.

When a financial envelope is present, it limits the plan budget:

```text
Available funding = max(0,
    revenue + external transfers
    − committed spending − debt service − reserve)
```

The funding deficit is displayed separately. Internal transfers must not be counted twice. Published budget figures and illustrative reallocations are labeled separately; an illustrative envelope is not verified available funding.

Applying a budget or poverty weight validates, recalculates and saves the scenario. Searching and showing more rows affect presentation only.

## Local storage and JSON

SwiftData stores geography and the active scenario in Application Support under the app's bundle identifier. Named scenario snapshots are stored separately as local JSON files. **Data and Sources** displays the database location.

For geography and scenario data, loading follows this order:

1. Use saved SwiftData data when present.
2. If the dataset is absent, try its configured HTTPS endpoint.
3. If no endpoint is configured or the remote response fails, use bundled JSON.
4. Validate the complete workspace and save imported datasets locally.

An unreadable or invalid local database produces an error and is preserved. There is no background refresh or cloud synchronization.

Imports and **Save / Apply** actions save explicitly. Unapplied form changes remain drafts. Validation and persistence must succeed before the displayed plan changes. Geography imports are rejected if they would leave scenario references unresolved.

Scenario and result exports create portable JSON files. Local saving does not modify imported source files or automatically export a backup.

## API configuration

`TurkiyePlan/Resources/app-config.json` contains:

```json
{
  "geographyAPIURL": null,
  "requestTimeoutSeconds": 12,
  "scenarioAPIURL": null
}
```

Both endpoints are disabled by default. Configured endpoints must use HTTPS and return JSON matching the app's `Geography` and `Scenario` models. A provider with a different response structure requires an adapter behind the repository protocol.

Endpoints are consulted only when the corresponding local dataset is absent. Changing a URL does not refresh or replace saved data. Service definitions, indicator definitions, finance presets and the record template load from bundled JSON. The HTTP loader does not implement provider authentication or scheduled refresh.

## Architecture

The app follows MVVM with protocol-based controllers and injected dependencies. `Core/AppComposition.swift` is the application entry point and creates the repositories, persistence container, validator, controllers, view model and router.

| Directory | Responsibility |
| --- | --- |
| `Core` | Domain models, allocation engine, data quality, scenario comparison, validation, repositories, workspace loading and persistence |
| `Navigation` | Tab routing and AppKit view-controller protocols and implementations |
| `Resources` | JSON datasets, configuration, translations and source licenses |
| `UI` | SwiftUI screens, editors, planning view model and planning controller |
| `Utils` | Formatting, localization, region search and deferred selection updates |
| `TurkiyePlanTests` | Unit tests and fixtures |
| `TurkiyePlanUITests` | UI tests |
| `Documentation` | Data contracts, methodology and implementation details |

SwiftUI views are hosted by AppKit view controllers. Views and view models work with value models; SwiftData entities and contexts remain behind the persistence protocol. Geography is relational, while the active scenario is stored as a Codable snapshot. UI and persistence operations use the main actor; the allocation engine operates on domain values.

Native tab and region-selection callbacks use deferred, coalesced updates to avoid publishing selection state during view reconciliation.

## Tests

Run **Product → Test** in Xcode for allocation, validation, persistence, loading, population, poverty, search, presentation, localization, data quality, scenario comparisons, snapshot storage and UI coverage. The UI smoke test uses an in-memory workspace and explicitly selects Turkish.

Check translation coverage and placeholders from the repository root:

```bash
python3 Documentation/verify-localizations.py
```

## Model scope

The app distributes a specified budget against recorded needs. It does not forecast household purchasing power, economic growth, public revenue, debt sustainability or annual cash flow. Savings and social benefits are not added as budget revenue.

Project approval, responsible agencies, site selection, permits, procurement, staffing, maintenance and delivery schedules require separate planning. Results depend on the quality and completeness of the supplied observations and assumptions.

## Documentation

- [Planning review](Documentation/PLANNING-REVIEW.md)
- [Data contract](Documentation/DATA-CONTRACT.md)
- [Finance data](Documentation/FINANCE-2025.md)
- [Poverty methodology](Documentation/POVERTY-MODEL.md)
- [Local persistence](Documentation/PERSISTENCE.md)
- [Localization](Documentation/LOCALIZATION.md)
