# 2025 finance data and scenario presets

This update was applied to the user-uploaded TurkiyePlan(1).zip. It preserves that project's target IDs, assets, bundle identifiers, signing and deployment target. The population visibility correction is also included. No SwiftData schema reset is required: new optional provenance is encoded inside the existing scenario payload.

## Load it in the app
Open the included Xcode project and run the shared TurkiyePlan scheme on My Mac.

An existing local plan remains authoritative. In **Dağıtım Matematiği**, select the JSON dataset and press **2025 JSON verisini uygula**. This explicitly applies its financing fields and planning budget, preserving observations and service records. A plan with existing cost records in another price year is rejected rather than silently relabelled.

For an empty local population inventory, press **Paket nüfus verilerini ekle**. This adds missing population observations without deleting the saved plan or overwriting same-key observations. Fresh installs load the reported fiscal baseline and factual population inventory from empty-scenario.json.

Alternatively, use Veri ve Kaynaklar → Senaryo JSON içe aktar to select either full scenario JSON. This replaces the active scenario, so export your current plan first if needed.

## Runtime JSON resources
| File | Purpose |
|---|---|
| finance-source-2025.json | Source figures in million TRY, source URL/page/column and explicit illustrative basis-point parameters |
| finance-presets-2025.json | Injected finance envelopes and their provenance for the dropdown |
| finance-2025-reported-scenario.json | Full factual population scenario with the reported fiscal baseline |
| finance-2025-illustrative-scenario.json | Same population evidence plus the optional funding what-if |
| empty-scenario.json / demo-scenario.json | Reported baseline for first launch / compatible explicit import; isDemo is false |

All monetary data are in JSON, injected at the application composition root. The UI does not embed national revenue or spending constants.

## Reported reference
SBB January 2026 report, page 1, **2025 Yıllık Gerç.** column, unit **million TL**:

| Published measure | Million TRY | Envelope mapping |
|---|---:|---|
| Budget revenue | 12,835,477 | ownRevenueCents; UI labels it Bütçe gelirleri for this scope |
| Non-interest spending | 12,580,225 | committedSpendingCents as a historical baseline, not a future legal commitment register |
| Interest spending | 2,054,382 | debtServiceCents; interest only, excluding principal repayments |
| Total spending | 14,634,607 | Control: non-interest + interest |
| Budget deficit | 1,799,130 | Negative residual shown separately |

Source: https://www.sbb.gov.tr/wp-content/uploads/2026/02/2026-Yili-Ocak-Ayi-MYB-Gerceklesmeleri.pdf

Cross-check release: https://kmyd.hmb.gov.tr/duyuru/2025-aralik-merkezi-yonetim-butce-gerceklesmeleri

The source publishes rounded million-TRY amounts. Multiplying by 100,000,000 converts that unit to kuruş without creating additional measurement precision. These are published annual outturn figures, not a claim that later revised final accounts were checked.

This is **central government**, not the consolidated revenue of every municipality, social security institution and public enterprise. No amounts are invented for individual provinces or districts, and no national amount is presented as money collected by a particular district.

## Why the reported preset has no available surplus
Revenue − non-interest spending − interest = **−1,799,130 million TRY**. The UI shows the funding gap and clamps available incremental funding at zero. A primary surplus alone is not treated as an available surplus after interest.

`externalTransfersCents=0` means no additional transfer is added on top of already-total budget revenue. `reserveCents=0` means no additional analytical reserve deduction is imposed. Neither is a claim that the state received no transfers of any kind or held no reserve assets.

## Optional illustrative financing
The what-if uses data parameters stored in finance-source-2025.json and provenance.assumptions:
- 20% of historical non-interest spending is considered open to reprioritisation.
- 1% of revenue is set aside as an extra analytical reserve.
- Historical revenue and interest are otherwise retained.

Calculation in TRY:
- Reprioritisation amount: 2,516,045,000,000.
- Retained non-interest spending: 10,064,180,000,000.
- Extra reserve: 128,354,770,000.
- Available model envelope: **588,560,230,000**.

This is a policy simulation, not an approved saving, extra revenue, recommendation to cut services, or verified freely spendable appropriation. The affected programmes, legal constraints, delivery effects and public-service consequences have not been analysed. It must not finance the same baseline expenditure twice. It is marked isDemo=true in the full illustrative scenario and provenance.status=illustrative in the envelope.

No district health needs, coverage or unit costs are estimated in this update. The illustrative envelope can remain unallocated until the user supplies those records. One annual funding envelope does not automatically fund recurring commitments in later years.

## Implementation corrections
- The financial component limit now accepts national-scale values; the previous 9-trillion-TRY per-component ceiling rejected 2025 national revenue. New bound: 90 trillion TRY per component, with safe Int64 arithmetic within validated ranges.
- Finances retain a signed raw balance and separate funding gap instead of hiding the deficit in max(0, ...).
- Field labels remain visible when a number is entered; formatted TRY equivalents appear below kuruş inputs.
- Finance, budget and weight fields refresh on view-model changes, fixing values that stayed at zero after an asynchronous load/import.
- Manual edits change provenance.status to user_edited and clear stored percentage assumptions that may no longer describe the amounts.
- Existing Codable scenarios without provenance still decode. SwiftData @Model entities are unchanged.
- Data types remain explicitly nonisolated; UI and persistence retain @MainActor. Swift language mode and default isolation are set consistently.

Unit-test source covers national-scale validation, the reported deficit, what-if reconciliation and old-envelope decoding. Native Xcode compilation/tests have not run here.
