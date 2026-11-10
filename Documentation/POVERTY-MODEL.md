# Poverty inputs and weighting

## What changed
- NeedRecord.povertyRate is optional. null means unknown; it is not a measured zero.
- Scenario.povertyProfiles is the single authority for geography-level poverty inputs. The same district rate is used by all services, eliminating conflicting repeated rates.
- Provinces have their own entries. In the supplied dataset these are population-weighted rollups of modeled districts, not official provincial estimates. Provincial values are never silently assigned to districts.
- Sources supports **Yoksulluk profili JSON içe aktar**. The district screen has an **İlçe yoksulluk profili** editor.
- Both observed and estimated values use the same schema; future replacements require no algorithm changes.
- A positive weight requires defined district rates for active needs. Missing rates do not silently receive a zero rate or lose funding. With missing inputs, set the weight to 0 or supply profiles.
- Participating profiles must share a definitionID and referenceYear. Regional-median relative poverty and national-median relative poverty cannot be mixed.

## Supplied scenario, not verified poverty rates
The Ministry of Industry and Technology's SEGE-2022 provides development scores/ranks for all 973 districts. Official explanatory page: https://www.sanayi.gov.tr/merkez-birimi/b94224510b7b/sege
Source report hosted by a public development agency: https://geka.gov.tr/uploads/supports_v/sege-2022.pdf

SEGE is a multidimensional development ranking, not a poverty headcount rate. I did not find a verified, comparable poverty headcount dataset covering every province/district during this search. This does not imply no local studies or later data exist.

The supplied profiles are deliberately **illustrative scenario proxies**, status=estimated, not statistically validated small-area poverty estimates. Their numeric differences come from the official rank, not an unsupported assumption that residents of an expensive district cannot be poor.

Method:
1. rawFactor = 0.5 + (SEGE rank − 1) / (district count − 1).
2. Compute the 2025 ADNKS population-weighted mean of rawFactor.
3. Rate = 0.13 × rawFactor / weighted mean.

The 13% anchor is a reported national 2025 relative-poverty benchmark at 50% of equivalised national median income, with income referring to 2024. HMB source reproducing TÜİK: https://ms.hmb.gov.tr/uploads/2026/06/II-ISTIHDAMVERIMLILIKUCRETLER-ve-GELIR-DAGILIMI-b0b1634c3b134018.pdf

The mapping and raw SEGE scores/ranks are retained in poverty-sege-crosswalk.json. All 973 districts matched the app IDs. One name alias is explicit: Samsun/Ondokuzmayıs in SEGE = Samsun/19 Mayıs in ADNKS.

This monotonic rank-to-rate mapping is a transparent scenario choice, not an empirical conversion formula. National calibration does not validate district rates. The ADNKS universe includes institutional residents whereas the income-survey poverty universe is different. SEGE's 2022 reference precedes the 2025 scenario; proxyYear, incomeReferenceYear and referenceYear are stored separately. No 2025 district household-income/essential-cost model, 2023-shock adjustment or statistical confidence interval is supplied.

Observed spending alone cannot establish poverty: differences in household composition, rent, prices, income distribution, wealth, debt and transfers matter. SEGE can also overlap with deprivation factors used elsewhere; avoid treating multiple correlated proxies as independent evidence or counting them repeatedly.

## Data shape
poverty-profiles-2025.json contains schemaVersion and profiles. Each profile has:
- geographyID, matching app province or district ID.
- rate: 0…1 or null.
- status: observed / estimated / missing.
- referenceYear, definitionID, sourceURL, method.
- Optional proxyYear, incomeReferenceYear, proxyRank and proxyScore.

An observed label means the supplied source reports an observation. It does not mean the app independently certified it. A missing profile has rate=null. A truly observed zero remains representable when its status, source and definition support it.

## How to use
1. Open the updated project, rebuild and run.
2. Preserve the current plan: Veri ve Kaynaklar → Yoksulluk profili JSON içe aktar → Resources/poverty-profiles-2025.json. Matching geography profiles are merged explicitly; an existing observed entry is protected from replacement by an imported estimate or missing entry. service costs, demand, population and finance remain intact.
3. In Dağıtım Matematiği, set weight to 0.5 or 1 and press Ağırlığı uygula.
4. Compare district/service allocation rows and gaps. National service bars may barely move because the demo's sector coefficients are uniform across districts; district shares are the relevant check.

Alternatively, import services-2025-complete-scenario.json for a full reset to the supplied demonstration, now including profiles and weight=0.5. Export your current plan first if retaining a backup.

For future observed rates, import the same profile schema with status=observed, actual source/year/definition and method. Do not treat a regional proxy as a measured district rate or mix thresholds. Partial imports preserve nonmatching profiles; observed values and scenario proxies must remain labelled correctly.

## Compatibility and persistence
SwiftData entity schema is unchanged; optional fields live in the existing Codable scenario payload. Legacy positive per-service rates remain decodable for compatibility, but a profile dataset overrides them. Legacy zero placeholders are not accepted as known rates for positive weighting. On startup, a legacy plan containing unknown zero placeholders and positive weight is preserved with the weight reset to 0 and an explanatory notice, so it can be upgraded/imported without a destructive database reset.

Native compilation/tests require Xcode and were not executed here. Included test sources verify weight sensitivity, profile precedence, budget conservation, unknown-rate handling and definition compatibility.
