# Fuel & Service Log — v1.1.1 (Patch)

**Release Date:** November 11, 2025

## 🎯 Highlights

### New Features
- **Ask where to save**: Νέα επιλογή στα Settings για επιλογή φακέλου κατά το export (PDF/CSV/Backup)
  - Toggle: ON → ερώτημα πριν κάθε αποθήκευση
  - Toggle: OFF → χρήση προεπιλεγμένου φακέλου εφαρμογής (προηγούμενη συμπεριφορά)
  - Platform support: Windows (file picker), Android (app dir with future SAF support)

- **Stats Filter Persistence**: Το επιλεγμένο φίλτρο και η μετρική αποθηκεύονται αυτόματα
  - Διατήρηση επιλογών μεταξύ navigation (tabs)
  - Επαναφορά προηγούμενης κατάστασης κατά την επανεκκίνηση

### Improvements
- **UTF-8 BOM in CSV exports**: Τέλεια συμβατότητα με Excel και Notepad
  - Greek text διατηρείται χωρίς mojibake
  - Automatic detection στα περισσότερα spreadsheet apps

- **Complete Greek Font Coverage**: NotoSans Regular/Bold με πλήρες Greek subset
  - UI και PDF rendering χωρίς missing glyphs
  - Diacritics (άέήίόύώ) πλήρως υποστηριζόμενα

### Bug Fixes
- **Data Integrity Guards**: Προστασία από RangeError σε short entry IDs
  - Safe substring operations
  - Graceful handling κατά την ανάλυση
  
- **PDF Greek Rendering**: Font fallback mechanism για ελληνικά γλυφά

## 🔧 Technical Details

### Architecture
- **Dependency Injection**: SaveTargetResolver με provider pattern
  - Interface-based design για testability
  - FakeSaveTargetResolver για deterministic tests
  - Channel mocks για file_selector/path_provider

### Testing
- **99 tests passing** (98 + 1 skipped)
- **Deterministic widget tests**: Bounded pumps, no platform calls
- **Zero analyzer warnings** (2 pre-existing deprecations from Flutter SDK)

### Dependencies
- Added: `file_selector: ^1.0.3` για cross-platform file picking
- Dev: `path_provider_platform_interface`, `plugin_platform_interface` για test mocks

## 📦 Upgrade Guide

### Android/Windows
- Απλό update - χωρίς database migrations
- Όλα τα υπάρχοντα δεδομένα διατηρούνται
- Νέες ρυθμίσεις με safe defaults (toggle OFF)

### Settings Migration
- `askWhereToSave`: default `false` (συμπεριφορά ως πριν)
- `statsFilter`: default YTD
- `statsMetric`: default Cost

## 🐛 Known Issues
- None - all tests passing, CI green

## 📝 Commits Included

- feat(settings): save path toggle + resolver DI + tests (#29) - PR #37
- fix(i18n): add 'No data in selected filters' key (#30) - PR #35
- feat(stats): persist filter/metric with controller (#27) - PR #36
- fix(pdf): Greek glyph fallback via NotoSans (#24) - PR #34
- fix(csv): UTF-8 with BOM for Greek text (#25) - PR #33
- fix(integrity): guard RangeError via safe operations (#26) - PR #32

## 🔗 Links

- [Full Changelog](https://github.com/ivmerachtsis-wq/Fuel_Service_Log/compare/v1.1.0...v1.1.1)
- [All Issues in v1.1.1 Milestone](https://github.com/ivmerachtsis-wq/Fuel_Service_Log/milestone/2?closed=1)

---

**Contributors:** @ivmerachtsis-wq
**CI Status:** ✅ All checks passed
