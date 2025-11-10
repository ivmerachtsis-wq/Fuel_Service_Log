# Fuel & Service Log — Roadmap v1.1

Η έκδοση v1.1 επικεντρώνεται στην ενίσχυση της εμπειρίας χρήστη, στην επαγγελματική ποιότητα εξαγωγών (PDF/Share), σε πιο ισχυρά και ευέλικτα στατιστικά (με φίλτρα ανά όχημα/οδηγό/ημερομηνία), σε βελτιώσεις απόδοσης για ομαλή κύλιση σε μεγάλες λίστες, και σε ένα proof-of-concept για συγχρονισμό στο cloud (Google Drive) με μελλοντική πρόβλεψη για κρυπτογράφηση αντιγράφων ασφαλείας.

---

## A) Στόχος έκδοσης

Να παραδώσουμε μια σημαντική αναβάθμιση προσανατολισμένη στον χρήστη με: (α) εξαγωγές PDF υψηλής ποιότητας και δυνατότητα κοινοποίησης, (β) φίλτρα και πολυ-παραμετρικά analytics για πολλαπλά οχήματα/οδηγούς/εύρη ημερομηνιών, (γ) καλαίσθητο και συνεπές UI με επιλογή θέματος (Light/Dark), (δ) σταθερή απόδοση με ομαλή κύλιση και μειωμένα rebuilds, και (ε) λειτουργικό πρωτότυπο συγχρονισμού στο Google Drive για χειροκίνητο ανεβοκατέβασμα αντιγράφων με placeholder για κρυπτογράφηση.

---

## B) Milestones

### 1. PDF Exports & Share
- Εργασίες
  - Δημιουργία PDF από τα υπάρχοντα CSV datasets (Fuel & Service) χρησιμοποιώντας βιβλιοθήκη `pdf` (Dart) και διάταξη με πίνακες.
  - Ενσωμάτωση header με μεταδεδομένα: όχημα, οδηγός, περίοδος/ημερομηνίες, σύνολα (π.χ. σύνολο λίτρων, συνολικό κόστος), νόμισμα.
  - Προαιρετικό λογότυπο εφαρμογής στο header (vector/bitmap) με σωστό DPI.
  - UI ροή: επιλογή τύπου εξαγωγής (Fuel/Service), περίοδος/φίλτρα, κουμπί "Εξαγωγή σε PDF".
  - Μετά την αποθήκευση: SnackBar με όνομα αρχείου και ενέργεια "Άνοιγμα φακέλου" (Windows/Android όπου υποστηρίζεται).
  - Κοινοποίηση (Android/Windows) με `share_plus` όταν είναι διαθέσιμο, fallback άνοιγμα φακέλου σε Windows.
- Acceptance Criteria
  - Το PDF αποθηκεύεται επιτυχώς με σωστές στήλες, σειρές και UTF-8 ελληνικά χωρίς αλλοιώσεις.
  - Εμφανίζεται header με όχημα/οδηγό/περίοδο/σύνολα και λογότυπο (αν έχει ενεργοποιηθεί).
  - Η διανομή/κοινοποίηση λειτουργεί σε Android· σε Windows παρέχεται τουλάχιστον "Άνοιγμα φακέλου".
  - Οι ρυθμίσεις νομίσματος/μορφοποίησης τιμών αντανακλώνται σωστά.

### 2. Stats Filters & Multi-Vehicle Analytics
- Εργασίες
  - Προσθήκη φίλτρων: Όχημα, Οδηγός, Εύρος Ημερομηνιών (DateRangePicker), Τύπος Καυσίμου (εφόσον υφίσταται), Κατηγορίες Service.
  - Άμεσο re-compute των δεικτών/γραφημάτων όταν αλλάζει φίλτρο (ValueListenable/Provider/Riverpod ή ελαφρύ BLoC μόνο για τα φίλτρα).
  - Σωστή συνάθροιση και κανονικοποίηση μετρήσεων σε πολλαπλά οχήματα (π.χ. μέση κατανάλωση ανά 100km, κόστος/μήνα, χιλιόμετρα καλυμμένα).
  - Καθαρή ένδειξη "Δεν υπάρχουν δεδομένα" ανάλογα με τα ενεργά φίλτρα.
- Acceptance Criteria
  - Οι γραφικές απεικονίσεις και KPI ενημερώνονται ακαριαία χωρίς spinners.
  - Τα αποτελέσματα συμφωνούν με χειροκίνητους υπολογισμούς σε τουλάχιστον 3 σενάρια (μονο-όχημα, multi-όχημα, φιλτράρισμα ημερομηνιών).
  - Η επιλογή φίλτρων παραμένει (persist) μεταξύ εκκινήσεων.

### 3. UI Enhancements (Theme & Polish)
- Εργασίες
  - Εναλλαγή Light/Dark mode από Settings, αποθήκευση προτίμησης (Hive settings key) και άμεση εφαρμογή θέματος.
  - Επανασχεδιασμός spacing/typography σε κύριες οθόνες (Fuel/Service/Stats) για καλύτερη αναγνωσιμότητα.
  - Προσθήκη προσαρμοστικών διατάξεων (Responsive breakpoints) για desktop πλάτος >1200px.
  - Αναθεώρηση εικονιδίων και καταστάσεων κενού (empty states) με σαφή CTA.
- Acceptance Criteria
  - Καμία υπερχείλιση/clip σε κοινά DPI/αναλύσεις (1080p/1440p/4K) σε Windows.
  - Το theme toggle επιμένει στο επόμενο launch και δεν εμφανίζει flicker.
  - Βελτιωμένος Lighthouse-like UX έλεγχος (χειροκίνητος) για spacing/ανάγνωση.

### 4. Performance Optimization
- Εργασίες
  - Εικονική κύλιση/“lazy” rendering για μεγάλες λίστες Fuel/Service (π.χ. `ListView.builder` με `addAutomaticKeepAlives: false`, σωστή χρήση keys).
  - Ελαχιστοποίηση rebuilds με granular ValueListenables/Selectors και memoization των βαριών υπολογισμών (π.χ. cache για integrity report).
  - Batch operations με Hive (transactions-like) όπου είναι εφικτό, και αποφυγή περιττών write/flush.
  - Προφίλ απόδοσης με Flutter DevTools σε σενάρια 5k+ εγγραφών.
- Acceptance Criteria
  - Ομαλή κύλιση ~60fps σε desktop hardware μέσης κατηγορίας.
  - Χρόνος υπολογισμού integrity report μειώνεται με caching και invalidation στη μεταβολή δεδομένων.
  - Μηδενικά dropped frames κατά την αλλαγή καρτελών και εφαρμογή φίλτρων.

### 5. Cloud Sync Prototype (Google Drive)
- Εργασίες
  - Προσθήκη λειτουργιών: Χειροκίνητο Upload/Download του backup JSON στο Google Drive (σημαντικός φάκελος/ονομασία αρχείων).
  - Ροή OAuth: desktop (Windows) και Android, αποθήκευση token με Hive (κρυπτογραφημένο στο μέλλον).
  - Placeholder κρυπτογράφησης backup (βασισμένο σε `encrypt` ή `pointycastle`) με απλό κλειδί που αποθηκεύεται τοπικά προς το παρόν.
  - UI: δράσεις στο Settings με καθαρά status (Signed in/Out, τελευταίος συγχρονισμός, προφύλαξη λαθών).
- Acceptance Criteria
  - Επιτυχές ανέβασμα/κατέβασμα ενός backup αρχείου σε λογαριασμό δοκιμής Google.
  - Ασφαλής αποθήκευση token (όχι σε plain text αρχείο), με δυνατότητα sign-out και token revoke.
  - Clear UX ροή με μήνυμα επιτυχίας/σφάλματος και δυνατότητα "Άνοιγμα φακέλου" τοπικά.

---

## C) Technical Upgrades (Προτάσεις & Rationale)

- `pdf` (Dart) και πιθανώς `printing` (προεπισκόπηση/εκτύπωση): για δημιουργία επαγγελματικών PDF με πίνακες, header/footer και υποστήριξη UTF-8.
- `share_plus`: για κοινοποίηση αρχείων σε Android/Windows (όπου υποστηρίζεται), εναλλακτικά fallback "Άνοιγμα φακέλου".
- `flutter_lints` 6.x: αυστηρότερες συμβάσεις κώδικα, καθαρότερα PRs και λιγότερα regressions.
- Ελαφρύ state management για φίλτρα στατιστικών: `provider` ή `riverpod` (ή εστιασμένο `flutter_bloc` μόνο για το υποσύστημα φίλτρων) ώστε να μοντελοποιούνται καθαρά οι καταστάσεις/γεγονότα.
- `encrypt` (ή `pointycastle`): placeholder συμμετρικής κρυπτογράφησης για backups πριν από πλήρη ασφάλεια κλειδιών.
- `googleapis` + `google_sign_in` (Android) / OAuth for desktop: πρόσβαση στο Google Drive REST API για το prototype συγχρονισμού.
- Προαιρετικά `shared_preferences` για απλές ρυθμίσεις, αν και παραμένουμε στο Hive για συνέπεια και offline-first.

Σημείωση: Οι βιβλιοθήκες προτείνονται για το v1.1 χωρίς να επιβάλλεται άμεση υιοθέτηση παντού. Θα προστεθούν στοχευμένα ανά milestone με μικρά, ελεγχόμενα PRs.

---

## D) QA & Testing Strategy

- Επίπεδα ελέγχων
  - Unit tests: υπολογισμοί στατιστικών, formatters (νόμισμα/ημερομηνίες), φίλτρα (predicate logic), backup/export μετασχηματισμοί.
  - Widget tests: UI των φίλτρων (state changes), PDF export flow (UI events μέχρι την κλήση υπηρεσίας), theme toggle persistence.
  - Integration tests (όπου εφικτό): end-to-end εξαγωγή και επιβεβαίωση ύπαρξης παραγόμενου αρχείου, basic Drive upload/download με test credentials.
- Regression checks
  - Fuel/Service εισαγωγές-επεξεργασίες-διαγραφές: έλεγχος ότι δεν επηρεάζονται από νέα φίλτρα/θέματα.
  - Υπολογισμοί κατανάλωσης/κόστους: σύγκριση με αναμενόμενα αποτελέσματα για προκαθορισμένα datasets.
  - Localizations: γένεση l10n μετά από αλλαγές ARB, επιβεβαίωση ότι νέα strings εμφανίζονται σωστά.
- Ποιότητα Κώδικα
  - `flutter analyze` πρέπει να επιστρέφει 0 issues.
  - Προαιρετικά golden tests για βασικές οθόνες (χωρίς flakiness σε DPI differences).

---

## E) Προτεινόμενα Prompts για Copilot

> Prompt #v1.1-M1 — PDF Export Implementation
- Στόχος: Υλοποίηση εξαγωγής PDF για Fuel & Service με header μεταδεδομένων και δυνατότητα κοινοποίησης.
- Βήματα:
  1) Πρόσθεσε/ενημέρωσε εξαρτήσεις: `pdf`, `share_plus` (και `printing` αν χρειαστεί προεπισκόπηση).
  2) Δημιούργησε service `pdf_export.dart` με συναρτήσεις δημιουργίας PDF για Fuel/Service (παίρνουν δεδομένα + φίλτρα).
  3) Πρόσθεσε UI κουμπιά "Εξαγωγή σε PDF" στις αντίστοιχες καρτέλες/Settings και SnackBars με όνομα αρχείου + "Άνοιγμα φακέλου".
  4) Σε Android: ενεργοποίησε share μέσω `share_plus`. Σε Windows: άνοιγμα φακέλου με `url_launcher`.
  5) Πρόσθεσε βασικά unit tests για το service (μη κενό PDF bytes, σωστός τίτλος/headings με επιλεγμένα φίλτρα).
- Acceptance Criteria:
  - PDF με σωστές στήλες/κειμενοποίηση/μεταδεδομένα και UTF-8.
  - Επιτυχής αποθήκευση και λειτουργία "Άνοιγμα φακέλου"/share.
- Εντολές:
  ```powershell
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  flutter run -d windows
  ```

> Prompt #v1.1-M2 — Stats Filter & Driver Analytics
- Στόχος: Προσθήκη φίλτρων (Όχημα/Οδηγός/Ημερομηνίες/Κατηγορίες) και δυναμικών υπολογισμών/γραφημάτων.
- Βήματα:
  1) Δημιούργησε μοντέλο κατάστασης φίλτρων και controller (Provider/Riverpod ή μικρό BLoC).
  2) Πρόσθεσε UI components: dropdowns/DateRangePicker, και σύνδεσέ τα με την κατάσταση.
  3) Προσαρμογή StatsService για συνάθροιση σε πολλά οχήματα και re-compute με αλλαγές φίλτρων.
  4) Προσθήκη κειμένων "Δεν υπάρχουν δεδομένα" ανά φίλτρο.
  5) Tests: unit (predicate/aggregations) + widget (UI updates instantaneously).
- Acceptance Criteria:
  - Άμεση ενημέρωση γραφημάτων/KPI χωρίς spinners.
  - Αποτελέσματα που ταιριάζουν σε χειροκίνητους υπολογισμούς για προκαθορισμένα datasets.
- Εντολές:
  ```powershell
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  flutter run -d windows
  ```

> Prompt #v1.1-M3 — UI Theme & Adaptive Polish
- Στόχος: Εναλλαγή Light/Dark mode με επιμονή ρύθμισης και βελτίωση UI spacing/typography.
- Βήματα:
  1) Πρόσθεσε setting toggle στο Settings και Hive key για αποθήκευση θέματος.
  2) Σύνδεσε το theme στον MaterialApp ώστε να αλλάζει άμεσα (notifyListeners/ValueListenable).
  3) Επανέλεγξε spacing/typography/empty states και διόρθωσε overflow issues.
  4) Πρόσθεσε responsive breakpoints για desktop wide layouts.
  5) Widget tests για theme persistence και βασικές διατάξεις.
- Acceptance Criteria:
  - Theme toggle που διατηρείται και εφαρμόζεται χωρίς flicker.
  - Καμία υπερχείλιση σε 1080p/1440p/4K.
- Εντολές:
  ```powershell
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  flutter run -d windows
  ```

> Prompt #v1.1-M4 — Performance Optimization
- Στόχος: Ομαλή κύλιση και μειωμένα rebuilds σε μεγάλες λίστες, caching integrity report.
- Βήματα:
  1) Εφάρμοσε virtualized λίστες με `ListView.builder` και σωστά keys.
  2) Διάσπαση widgets/ValueListenables για ελάχιστα rebuilds.
  3) Cache/Μνημονικοποίηση integrity report με invalidation στη μεταβολή δεδομένων.
  4) Προφίλ με DevTools σε dataset 5k+ γραμμών και βελτιστοποίησε hot paths.
  5) Πρόσθεσε μικρά benchmarks ή μετρήσεις χρόνου όπου εφικτό.
- Acceptance Criteria:
  - Ομαλή κύλιση ~60fps και μηδενικά stutters στις οθόνες λιστών.
  - Γρήγορη εκ νέου φόρτωση integrity report χάρη στο cache.
- Εντολές:
  ```powershell
  flutter pub get
  flutter analyze
  flutter run -d windows
  ```

> Prompt #v1.1-M5 — Cloud Sync Prototype (Google Drive)
- Στόχος: Proof-of-concept για χειροκίνητο Upload/Download backup JSON στο Google Drive με OAuth και placeholder κρυπτογράφησης.
- Βήματα:
  1) Πρόσθεσε εξαρτήσεις: `googleapis` (Drive v3), `google_sign_in` (Android), OAuth desktop flow για Windows.
  2) Υλοποίησε service `cloud_sync.dart` με μεθόδους sign-in/out, upload/download, αποθήκευση token (Hive) και απλό encryption wrapper.
  3) Πρόσθεσε UI στο Settings: login/logout, manual sync, status τελευταίου συγχρονισμού.
  4) Διαχειρίσου λάθη/limits (quota, network) με καθαρά μηνύματα.
  5) Integration test (όπου εφικτό) για upload/download με test project credentials.
- Acceptance Criteria:
  - Επιτυχημένο upload/download ενός backup αρχείου.
  - Ασφαλής αποθήκευση token (όχι plain text), δυνατότητα sign-out/revoke.
- Εντολές:
  ```powershell
  flutter pub get
  flutter gen-l10n
  flutter analyze
  flutter test
  flutter run -d windows
  ```

---

## F) Έξοδος

- Το παρόν έγγραφο αποθηκεύτηκε ως `docs/v1_1_roadmap.md` και είναι έτοιμο για commit.
- Προτεινόμενος κύκλος εργασίας ανά Milestone:
  1) Δημιουργία branch `feature/v1.1-mX-<short-name>`.
  2) Μικρά PRs ανά υπο-εργασία, με `flutter analyze` και `flutter test` πράσινα.
  3) Manual QA σε Windows (και Android όπου αφορά).
  4) Συγχώνευση στο `windows-base` μετά από review.
