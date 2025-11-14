## What

Android & Windows parity after v1.3.0:

### Shell & Navigation
- Unified main entrypoint with a single Shell for all platforms.
- Tabs: Fuel, Service, Stats, Vehicles, Settings on both Android & Windows.

### Forms & IDs
- Centralized ID generation for fuel, service and vehicle records (no manual ID inputs).
- Removed visible `*_id` fields from all forms; IDs are now auto-generated.

### Vehicle selector
- Fuel & Service forms now show all vehicles, not only the active one.
- Default selection is the active vehicle on both desktop & mobile.

### Currency picker
- Shared searchable CurrencyPickerField reused in Fuel, Service and Vehicle forms.
- Dozens of currencies available (not only EUR/USD), consistent across platforms.

### Date picker
- Shared DatePickerField for Fuel & Service entries.
- Same date UX for Windows and Android.

### Settings parity
- Settings on Android now mirror Windows:
  - Vehicles CRUD + Active badge
  - Theme selection
  - "Ask where to save" for PDF/CSV/Backup
  - Export CSV, Fuel PDF, Service PDF
  - Backup/Restore JSON
  - About section

### Themes
- AppTheme enum: System, Light, Dark, Comfort Light, Midnight.
- Theme selection dropdown applies immediately on both platforms.

## Quality
- flutter analyze --no-fatal-infos: only 2 deprecation infos (value vs initialValue).
- flutter test --timeout=2m: all tests passed (163), 14 skipped by design (heavy widget tests).
