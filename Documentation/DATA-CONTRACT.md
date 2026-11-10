# Data contract and next ingestion stages

## Geography v1
`schemaVersion`, `source {title,url,snapshot,verification,revision}`, `provinces [{id,name}]`, `districts [{id,provinceID,name}]`.
IDs are opaque source strings. Never infer count, plate number or hierarchy by parsing an ID. Parent links are explicit. Replace the dataset at composition root; preserve mapping when migrating sources. The included snapshot is reference geography, not fiscal evidence.

## Scenario
`name`, `isDemo`, `priceYear`, `budgetCents`, `povertyWeight`, `records`, optional `finances`.

Record fields:
| Field | Meaning / range |
|---|---|
| districtID, serviceID | Existing IDs, unique pair |
| population | Nonnegative district population; not additive across services |
| eligible | Population needing this service, 0…population |
| served | Adequately served among eligible, 0…eligible |
| targetCoverage | Fraction, 0…1 |
| capitalUnitCents | Nonnegative cost per additional service unit |
| annualUnitCents | Nonnegative yearly operating cost per additional unit |
| horizonYears | Integer 1…50 |
| povertyRate | Fraction 0…1 |
| deliveryCostIndex | Positive multiplier; baseline 1 |
| fiscalCapacityIndex | Positive comparable fiscal capacity; baseline 1 |
| source | Nonempty provenance and methodology reference |
| referenceYear | Must match scenario priceYear |

The MVP represents demand in people/households/service places and uses integer eligible/served. Recycling's tonne unit can be modelled in whole tonnes; fractional measures need a future versioned quantity model. Do not insert land area or total tonnage into population fields to bypass this constraint.

Financial envelope: `ownRevenueCents`, `externalTransfersCents`, `committedSpendingCents`, `debtServiceCents`, `reserveCents`. Each nonnegative and <=9000000000000000 cents. Available = max(0, own revenue + external transfers − commitments − debt − reserve). This envelope must already be consolidated and put on the same horizon/price basis; it does not validate accounting provenance.

## Required official ingestion work
Request the following as separate long-format datasets, not extra columns with ambiguous units:
- Demographics by district, year, age group; population forecasts; disability/care needs and access barriers.
- Household income distribution, poverty definition, essential expenditure, employment and educational attainment.
- Consolidated fiscal receipts, transfers, commitments, debt and actual spending with institution and accounting basis.
- Service access/capacity, staff, utilisation, quality, waiting time, travel time and facility condition.
- Infrastructure asset inventories, water losses, outages, waste composition, recovery yields and lifecycle costs.

Each observation should carry geographyID, indicatorID, value or null, unit, reference period, price basis, source, revision, quality status and methodology. Null is unknown. Regional revenue collected is not regional GDP or household income. Internal transfers are eliminated on consolidation. Never backfill unknown financial data with synthetic values except in labelled demos.

The next version should introduce a separately validated ObservationRepository and typed indicator catalogue, followed by explicit transformations into NeedRecord. This avoids coupling arbitrary raw APIs to the allocation engine. District services shared across boundaries require catchment mapping rather than duplicated demand.

## Local persistence edition
Geography and Scenario DTOs retain their existing JSON shape. Geography API and scenario API endpoints are optional injected settings in Resources/app-config.json. Valid seeds/imports are stored in SwiftData. Province/district entities are relational; the active scenario is a versioned Codable snapshot. See PERSISTENCE.md for the exact loading and error contract.
