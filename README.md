# Fuel & Service Log

[![Flutter CI](https://github.com/ivmerachtsis-wq/fuel-service-log-app/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/ivmerachtsis-wq/fuel-service-log-app/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Παρακολούθηση καυσίμων, service και στατιστικών οχημάτων.  
Flutter app — Windows & Android.

## Χαρακτηριστικά
- Πολλαπλά οχήματα & οδηγοί
- Καρτέλες Fuel / Service / Stats / Settings
- Υπολογισμός κατανάλωσης (full-to-full, L/100km)
- Export CSV & JSON, Auto-Backup (κρατά 2 τελευταία)
- Έλεγχος ακεραιότητας δεδομένων (Data Integrity)
- Δίγλωσσο UI (Ελληνικά/Αγγλικά), προτιμήσεις νομίσματος

## Εγκατάσταση (Windows)
1) Κατέβασε το `Fuel_Service_Log_v1.0.0-stable_Windows.zip` από το GitHub Releases  
2) Άνοιξε το zip και τρέξε `fuel_service_log.exe`

## Εγκατάσταση (Android)
1) Κατέβασε το `Fuel_Service_Log_v1.0.0-stable_Android.apk`  
2) Εγκατάσταση σε συσκευή (Άγνωστες Πηγές: ενεργοποίηση)

## Φάκελοι δεδομένων
- Backups: `Documents/FuelServiceLog/backups/`
- Exports:  `Documents/FuelServiceLog/exports/`

## Έκδοση
- `v1.0.0-stable` — δείτε το **GitHub Release** για αλλαγές & αρχεία

## Development
```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d windows
```

## License
MIT
