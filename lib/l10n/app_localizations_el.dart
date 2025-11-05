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
  String get theme => 'Θέμα';

  @override
  String get currency => 'Νόμισμα';

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
}
