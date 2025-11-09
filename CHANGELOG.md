# Changelog

Όλες οι σημαντικές αλλαγές σε αυτό το project θα τεκμηριώνονται εδώ, ακολουθώντας το
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) και [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] – v1.1.0
### Added
- PDF Reports: βελτιωμένη τυπογραφία (NotoSans Regular/Bold), locale-aware αριθμοί/νομίσματα.
- Προετοιμασία custom table rendering (Fuel/Service πίνακες με headers/footers).
- AI Continuous Dev Cycle: `AI_DEV_CYCLE.md`, branch `ai-dev`, nightly analyzer/build script.
- Stats: `stats_aggregator.dart` (MonthlyTotals, KPIs), `computeExtraKpi` (€/km, L/100km),
  UI integration with new KPI row in Stats tab.
- Unified monthly aggregation via `seriesFromTotals()` (fuel/service amounts, liters).
- Distance fallback from service odometers when fuel entries are insufficient.
- Date-range filter presets (Last 30/90/180, YTD, All) and custom range dialog for Stats.
- Charts metric toggle (Cost €, Liters L, Distance km) based on unified monthly buckets.
- Helper `estimateMonthlyDistanceKm()` for monthly distance estimation in charts.

### Tests
- `test/stats/stats_aggregator_test.dart` — aggregation & KPI math
- `test/stats/stats_extra_kpi_test.dart` — €/km & L/100km window KPIs
- Added `series_from_totals_test.dart` and `distance_fallback_test.dart`.
- Added `filter_and_metric_test.dart` for filter range, series aggregation with filtered inputs, and monthly distance estimation.

### Changed
- Ενοποιημένο theme για PDF (`pw.ThemeData.withFont`), σταθερά margins/στήλες (A4).
- Καθαροί κανόνες PR & commits για AI-driven ροή.
- Stats charts now consume the unified monthly series.
- KPI widgets handle zero-distance gracefully (placeholder + tooltip).
- Chart polish: rounded bars (radius 6px), improved tooltips with month/fuel/service breakdown.
- KPIs and charts now respect the active date-range filter and metric selection.

### Fixed
- Μηδενικά analyzer warnings (0) σε Windows/Android builds.

## [v1.0-pre-ai] – 2025-11-09
### Added
- Βασικές λειτουργίες: Fuel/Service CRUD με Undo, L/100km υπολογισμοί.
- Exports: CSV/JSON, Auto-backup (rotation 2), DataIntegrityService & αναφορά.
- Tabs: Fuel / Service / Stats / Settings με i18n (EN/EL), currency handling.
- Windows & Android builds καθαρά (analyzer 0).

### Notes
- Tag snapshot πριν την έναρξη του AI dev cycle.
