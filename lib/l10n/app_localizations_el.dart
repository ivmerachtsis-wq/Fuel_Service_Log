// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Fuel & Service Log';

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
}
