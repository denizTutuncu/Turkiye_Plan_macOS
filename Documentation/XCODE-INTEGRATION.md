# Integration record • supplied Xcode template

The archive is already integrated. Open TurkiyePlan.xcodeproj, select the TurkiyePlan scheme / My Mac, and Run. There is no need to create another project or copy individual source files.

## Preserved
- Original modern project.xcproj format, project workspace, targets and blueprint IDs.
- Signing team and automatic signing.
- App and test bundle identifiers.
- macOS 26.6 deployment target.
- Asset catalog including AppIcon and AccentColor.
- App, unit-test and UI-test targets and their dependencies.

## Changed
- Replaced the three generated starter Swift files with Core, Navigation, Resources, UI and Utils.
- Set all targets to Swift 6 language mode.
- Explicitly set Default Actor Isolation to nonisolated for all targets. Domain models and source/calculation types also declare nonisolated; UI and persistence boundaries retain @MainActor.
- Changed sandbox user-selected file access to Read/Write for JSON imports and exports.
- Enabled outgoing client connections for future optional HTTPS APIs; both endpoint settings remain null.
- Added a shared scheme: Debug for launch/tests, Release for archive/profile.
- Replaced empty unit/UI sample tests with allocation, SwiftData, fallback and navigation tests.
- Bundled test fixtures under TurkiyePlanTests/Fixtures; no source-filesystem fixture access is needed.

The generated template's default SwiftData Item/container is replaced by PlanningSchemaV1 and the container created at the application composition root. No second SwiftUI modelContainer is needed, since views use the controller/repository boundary rather than @Query.

## Run and check
1. Use an Xcode version that supports your supplied project's project.xcproj format (the template records last upgrade 27.2).
2. Open TurkiyePlan.xcodeproj. Check the preserved signing team if Xcode requests signing setup.
3. Select the TurkiyePlan scheme and My Mac; Product → Run.
4. On first launch, bundled JSON seeds SwiftData because no endpoints are configured.
5. Import a demo or enter a sourced record, then apply changes. Quit and reopen to check persistence.
6. Product → Test runs unit tests plus a basic app-launch/region-navigation test.

The shared test scheme sets TURKIYEPLAN_IN_MEMORY_TESTS=1 for the unit-test host. The UI smoke test launches with --ui-testing. In Debug only, this selects an in-memory SwiftData container and skips configured remote repositories. Normal launch continues using the persistent application-support store. Both mechanisms select in-memory startup storage in Debug; tests do not reset normal user data.

Test targets are already part of the project. The shared scheme explicitly uses Debug so @testable import can access internal app types. JSON fixtures belong only to the unit-test target, while runtime JSON belongs only to the app target.

## Data configuration
Resources/app-config.json configures the two optional HTTPS endpoints and timeout. Local data has priority. Changing bundle seeds or API URLs does not replace existing saved data. Use explicit JSON import to update local geography or the active scenario.

The app shows its exact store location in Veri ve Kaynaklar. The bundle identifier remains unchanged, so that location stays stable across updates. CloudKit is explicitly disabled; no remote upload/synchronisation is implemented.

## Verification limitation
The source and project structure were checked in Linux. Xcode is unavailable here, so native compilation, SwiftData macro expansion, Product → Test and visual checks remain to be performed on your Mac. Grammar parsing is not a successful native build.
