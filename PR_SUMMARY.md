# [AI] Stats: integrate aggregator in UI + add €/km & L/100km KPIs

## Σύνοψη
Ενσωμάτωση του νέου `stats_aggregator.dart` module στο UI και προσθήκη δύο νέων KPIs: **€/km** και **L/100km** (computed από window-specific data).

## Actions Taken
- **Extended** `lib/domain/stats_aggregator.dart`:
  - Προσθήκη `ExtraKpi` class (costPerKm, litersPer100km)
  - Προσθήκη `computeExtraKpi(...)` function με window-based υπολογισμό
  
- **Added unit tests**:
  - `test/stats/stats_aggregator_test.dart` — aggregation & KPI math (10 tests)
  - `test/stats/stats_extra_kpi_test.dart` — €/km & L/100km window KPIs

- **Integrated extra KPIs in UI**:
  - `lib/ui/tabs/stats_tab.dart`: imported aggregator και προστέθηκε δεύτερη σειρά KPI με:
    - **€/km** από `computeExtraKpi` (currency-aware)
    - **L/100km** από `computeExtraKpi`
  - Distance υπολογίζεται από odometer spread των fuel entries στο window
  - Διατηρήθηκαν τα existing charts και monthly cost logic (χωρίς ριψοκίνδυνο refactor)

- **i18n polish**:
  - Προσθήκη ARB keys: `kpiCostPerKm`, `kpiLitersPer100km`, `kpiDistanceWindow` (EN + EL)
  - Updated stats_tab για χρήση localized labels

- **Updated CHANGELOG**:
  - `CHANGELOG.md` Unreleased: προστέθηκαν stats aggregator + tests + UI KPI integration

## Files Changed
```
lib/domain/stats_aggregator.dart       — ExtraKpi + computeExtraKpi
test/stats/stats_aggregator_test.dart  — 10 tests (monthly aggregation)
test/stats/stats_extra_kpi_test.dart   — extra KPI window tests
lib/ui/tabs/stats_tab.dart             — extra KPI row using aggregator
lib/l10n/app_en.arb                    — i18n keys for new KPIs
lib/l10n/app_el.arb                    — i18n keys (Greek)
CHANGELOG.md                           — Unreleased notes
```

## Quality Gates
- ✅ **Analyzer**: No issues found (ran in 20.1s)
- ✅ **Tests**: All tests passed (32 tests, 1 skipped)
  - Νέα tests: `stats_aggregator_test.dart`, `stats_extra_kpi_test.dart`
- ✅ **Commits**: Atomic commits με σαφή messages
  - `[AI] feat(stats): monthly aggregators & KPIs foundation`
  - `[AI] feat(stats): UI integration with extra €/km & L/100km KPIs`
  - `[AI] i18n: add ARB keys for new KPI labels (€/km, L/100km)`

## PR Checklist
- [x] Analyzer: PASS (0 issues)
- [x] Tests: PASS (all tests)
- [x] Localization: ARB keys added (EN + EL)
- [x] CHANGELOG: Updated under Unreleased
- [x] Commits: Atomic και σαφή
- [x] No breaking changes
- [x] UI tested manually (KPI cards εμφανίζονται σωστά)

## Screenshots / Demo
*(Προαιρετικό: screenshot του stats tab με τα 2 νέα KPI boxes)*

## Next Steps (μετά το merge)
1. **Nightly check**: Τρέξε `tools\ai_build_check.bat` στο ai-dev
2. **Tag RC2**: `git tag -a v1.1.0-rc.2 -m "RC2: Stats KPIs (€/km, L/100km) + aggregator"`
3. **Follow-up PR**: Refactor charts για χρήση `aggregateMonthly` series (drop manual maps)

---
**Base Branch**: `ai-dev`  
**Feature Branch**: `feature/stats-graphs`  
**Commits**: 3 (cced4c7, 372ba16, 4941e18)
