// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Καταγραφή Καυσίμων & Service';

  @override
  String get tabFuel => 'Καύσιμα';

  @override
  String get tabService => 'Service';

  @override
  String get tabStats => 'Στατιστικά';

  @override
  String get tabSettings => 'Ρυθμίσεις';

  @override
  String get emptyFuel => 'Δεν υπάρχουν καταχωρήσεις καυσίμων';

  @override
  String get emptyService => 'Δεν υπάρχουν καταχωρήσεις service';

  @override
  String get statsTitle => 'Στατιστικά';

  @override
  String get settingsTitle => 'Ρυθμίσεις';

  @override
  String get actionAdd => 'Προσθήκη';

  @override
  String get actionEdit => 'Επεξεργασία';

  @override
  String get actionDelete => 'Διαγραφή';

  @override
  String get actionUndo => 'Αναίρεση';

  @override
  String get addFuel => 'Νέα Καταχώρηση Καυσίμου';

  @override
  String get addService => 'Νέα Καταχώρηση Service';

  @override
  String get exportCsv => 'Εξαγωγή CSV';

  @override
  String get backupJson => 'Δημιουργία Αντιγράφου';

  @override
  String get restoreJson => 'Επαναφορά Αντιγράφου';

  @override
  String get language => 'Γλώσσα';

  @override
  String get languageEnglish => 'Αγγλικά';

  @override
  String get languageGreek => 'Ελληνικά';

  @override
  String get theme => 'Θέμα';

  @override
  String get currency => 'Νόμισμα';

  @override
  String get currencyEUR => 'Ευρώ (€)';

  @override
  String get currencyUSD => 'Δολάριο ΗΠΑ (\$)';

  @override
  String get currencyGBP => 'Λίρα Αγγλίας (£)';

  @override
  String get successExport => 'Η εξαγωγή ολοκληρώθηκε επιτυχώς';

  @override
  String get successBackup => 'Το αντίγραφο δημιουργήθηκε επιτυχώς';

  @override
  String get successRestore => 'Η επαναφορά ολοκληρώθηκε επιτυχώς';

  @override
  String get kpiAvgConsumption => 'Μέση κατανάλωση (L/100km)';

  @override
  String get kpiMonthlyCost => 'Κόστος/μήνα (τελευταίοι 6)';

  @override
  String get chartNoData => 'Δεν υπάρχουν επαρκή δεδομένα για στατιστικά';

  @override
  String get chartAxisDate => 'Ημερομηνία';

  @override
  String get chartAxisConsumption => 'L/100km';

  @override
  String get statsHintFullToFull => 'Προσθέστε τουλάχιστον 2 γεμίσματα με γεμάτο ρεζερβουάρ για να δείτε στατιστικά κατανάλωσης';

  @override
  String get noFuelEntries => 'Δεν υπάρχουν καταχωρήσεις καυσίμων';

  @override
  String get addFuelTitle => 'Νέα Καταχώρηση Καυσίμου';

  @override
  String get editFuelTitle => 'Επεξεργασία Καυσίμου';

  @override
  String get liters => 'Λίτρα';

  @override
  String get pricePerLiter => 'Τιμή ανά λίτρο';

  @override
  String get amount => 'Ποσό';

  @override
  String get fullTank => 'Γεμάτο ρεζερβουάρ';

  @override
  String get notes => 'Σημειώσεις';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get cancel => 'Άκυρο';

  @override
  String get settingsGeneral => 'Γενικές προτιμήσεις';

  @override
  String get noActiveVehicle => 'Δεν έχει οριστεί ενεργό όχημα';

  @override
  String get odometerKm => 'Χιλιόμετρα (km)';

  @override
  String get editService => 'Επεξεργασία Service';

  @override
  String get serviceNoEntries => 'Δεν υπάρχουν καταχωρήσεις service';

  @override
  String get serviceDate => 'Ημερομηνία';

  @override
  String get serviceOdometer => 'Χιλιόμετρα (km)';

  @override
  String get serviceDescription => 'Περιγραφή';

  @override
  String get serviceAmount => 'Συνολικό ποσό';

  @override
  String get serviceNotes => 'Σημειώσεις';

  @override
  String get serviceInvoice => 'Τιμολόγιο';

  @override
  String get deleted => 'Διαγράφηκε';

  @override
  String get settingsMaintenance => 'Συντήρηση & Ακεραιότητα Δεδομένων';

  @override
  String get runIntegrityCheck => 'Έλεγχος δεδομένων';

  @override
  String get integrityOk => 'Δεν βρέθηκαν προβλήματα';

  @override
  String get integrityIssuesFound => 'Βρέθηκαν προβλήματα';

  @override
  String get autoBackupOk => 'Ο αυτόματος backup ολοκληρώθηκε';

  @override
  String get autoBackupFailed => 'Αποτυχία αυτόματου backup';

  @override
  String get integrityReportTitle => 'Αναφορά Ακεραιότητας Δεδομένων';

  @override
  String integrityReportSummary(Object fuel, Object service) {
    return 'Καύσιμα: $fuel, Συντήρηση: $service';
  }

  @override
  String get settingsExportCsvSubtitle => 'Εγγραφές καυσίμων και συντήρησης σε CSV';

  @override
  String get settingsRestoreSubtitle => 'Εισαγωγή από το τελευταίο αρχείο αντιγράφων ασφαλείας';

  @override
  String get ok => 'OK';

  @override
  String get settingsVersion => 'Έκδοση';

  @override
  String get version => 'Έκδοση';

  @override
  String get validationRequired => 'Απαιτούμενο πεδίο';

  @override
  String get errorFutureDateNotAllowed => 'Δεν επιτρέπεται μελλοντική ημερομηνία';

  @override
  String get exportSuccess => 'Η εξαγωγή ολοκληρώθηκε';

  @override
  String get openFolder => 'Άνοιγμα φακέλου';

  @override
  String get exportFuelPdf => 'Εξαγωγή Fuel σε PDF';

  @override
  String get exportServicePdf => 'Εξαγωγή Service σε PDF';

  @override
  String get pdfTitleFuel => 'Εξαγωγή Καυσίμων';

  @override
  String get pdfTitleService => 'Εξαγωγή Service';

  @override
  String get pdfMetaVehicle => 'Όχημα';

  @override
  String get pdfMetaDriver => 'Οδηγός';

  @override
  String get pdfMetaCreatedAt => 'Δημιουργήθηκε';

  @override
  String get pdfSummary => 'Σύνοψη';

  @override
  String get pdfCount => 'Πλήθος';

  @override
  String get pdfTotalLiters => 'Σύνολο λίτρων';

  @override
  String get pdfTotalAmount => 'Σύνολο ποσού';

  @override
  String get statsFilters => 'Φίλτρα';

  @override
  String get filterVehicle => 'Όχημα';

  @override
  String get filterDriver => 'Οδηγός';

  @override
  String get filterDateRange => 'Χρονικό εύρος';

  @override
  String get range3m => 'Τελευταίοι 3 μήνες';

  @override
  String get range6m => 'Τελευταίοι 6 μήνες';

  @override
  String get range12m => 'Τελευταίοι 12 μήνες';

  @override
  String get allDrivers => 'Όλοι';
}
