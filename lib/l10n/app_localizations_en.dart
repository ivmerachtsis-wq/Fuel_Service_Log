// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fuel & Service Log';

  @override
  String get tabFuel => 'Fuel';

  @override
  String get tabService => 'Service';

  @override
  String get tabStats => 'Stats';

  @override
  String get tabSettings => 'Settings';

  @override
  String get emptyFuel => 'No fuel entries yet';

  @override
  String get emptyService => 'No service entries yet';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionUndo => 'Undo';

  @override
  String get addFuel => 'Add Fuel Entry';

  @override
  String get addService => 'Add Service Entry';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get backupJson => 'Backup JSON';

  @override
  String get restoreJson => 'Restore JSON';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get currency => 'Currency';

  @override
  String get currencyEUR => 'Euro (€)';

  @override
  String get currencyUSD => 'US Dollar (\$)';

  @override
  String get currencyGBP => 'British Pound (£)';

  @override
  String get successExport => 'Export completed successfully';

  @override
  String get successBackup => 'Backup created successfully';

  @override
  String get successRestore => 'Restore completed successfully';

  @override
  String get kpiAvgConsumption => 'Average consumption (L/100km)';

  @override
  String get kpiMonthlyCost => 'Monthly cost (last 6)';

  @override
  String get chartNoData => 'Not enough data for statistics';

  @override
  String get chartAxisDate => 'Date';

  @override
  String get chartAxisConsumption => 'L/100km';
}
