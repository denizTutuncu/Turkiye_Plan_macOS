# Persistence and fallback contract

## Choice
SwiftData is used because this is a new modern macOS app. Core Data would be reasonable for an existing Core Data codebase or requirements needing its lower-level controls. Neither technology replaces repository boundaries or dataset validation.

Apple references:
- https://developer.apple.com/documentation/swiftdata/modelcontainer
- https://developer.apple.com/documentation/swiftdata/modelconfiguration
- https://developer.apple.com/documentation/swiftdata/modelcontext
- https://developer.apple.com/videos/play/wwdc2023/10196/

## Persisted schema v1
| Entity | Identity | Purpose |
|---|---|---|
| StoredProvince | unique source id | Name and cascade relationship to districts |
| StoredDistrict | unique source id | Name and inverse province reference |
| StoredGeographyMetadata | unique geography key | Source provenance, DTO schema version, import timestamp |
| StoredScenario | unique active key | Payload version, Codable scenario snapshot, update timestamp |

The snapshot includes service need records, optional regional observations and financial assumptions. Derived allocations are recalculated after load; result export includes algorithm version and assumptions. SwiftData entities stay private to the persistence layer; Codable domain models remain independent of storage technology.

## Loading truth table
| Local dataset | Remote configuration/result | Action |
|---|---|---|
| Present and valid | Any | Use local; do not contact remote or read that bundled seed |
| Absent | Valid API result | Validate and persist API data |
| Absent | No endpoint | Validate and persist bundled seed |
| Absent | Timeout/HTTP/decode/validation failure | Record notice, validate and persist bundled seed |
| Read/open/schema error | Any | Report error; preserve database; no destructive fallback |
| Save failure | Any | Report failure; rollback transaction; do not present changes as saved |

Geography and scenario fallback are independent. The final scenario is validated against the selected geography before any bootstrap write. A configured remote scenario that fails this validation falls back to the empty bundled scenario. Local scenarios are never silently replaced to accommodate a changed remote geography.

## Unit of work
Every persistence write creates a fresh main-actor ModelContext with autosave disabled. Encoding is performed before mutations. Geography is updated in place by stable ID; missing imported IDs are removed only during an explicit geography replacement. Province links, metadata and optional scenario commit in one save; rollback handles thrown errors.

The loader skips writes when both datasets exist. There is no automatic seed on every launch, no cache TTL and no remote refresh that could overwrite local edits. Import is explicit. CloudKit is disabled in ModelConfiguration.

The persistence protocol supports alternative stores without changing view models. For future high-volume ingestion, use a dedicated ModelActor and async persistence protocol rather than sending @Model objects across actors. For multi-user syncing, first define conflict resolution and server/source ownership; enabling CloudKit alone is not an equivalent policy.
