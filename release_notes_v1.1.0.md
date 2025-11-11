# v1.1.0 (Stable)

## Highlights
- **Filtered-Stats PDF export**
- **Empty-data guard** for empty filters
- **Full test suite pass (45 tests)**
- **Exports & Backup/Restore verified**

## Compatibility
- CI: Flutter 3.27.1 / Dart 3.6.0
- Local: Flutter 3.35.7 / Dart 3.9.2
- pdf v3.11.3

## QA Summary
All main features passed manual QA on Windows:
- PDF (normal + empty) OK
- CSV OK (encoding to be improved)
- Backup/Restore OK
- Integrity check: RangeError edge case logged
- Fonts: NotoSans Greek fallback missing (next patch)

## Next milestone → v1.1.1
- Font locale fallback
- CSV UTF-8 encoding
- Data integrity guard fix
- Filter persistence & Vehicle CRUD (Settings)
