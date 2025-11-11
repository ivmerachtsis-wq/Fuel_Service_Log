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
  String get languageEnglish => 'English';

  @override
  String get languageGreek => 'Greek';

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
  String get kpiCostPerKm => 'Cost per km';

  @override
  String get kpiLitersPer100km => 'Consumption (L/100km)';

  @override
  String get kpiDistanceWindow => 'Distance (window)';

  @override
  String get chartNoData => 'Not enough data for statistics';

  @override
  String get chartAxisDate => 'Date';

  @override
  String get chartAxisConsumption => 'L/100km';

  @override
  String get statsHintFullToFull => 'Add at least 2 full-tank refuels to see consumption statistics';

  @override
  String get noFuelEntries => 'No fuel entries yet';

  @override
  String get addFuelTitle => 'Add Fuel';

  @override
  String get editFuelTitle => 'Edit Fuel';

  @override
  String get liters => 'Liters';

  @override
  String get pricePerLiter => 'Price per liter';

  @override
  String get amount => 'Amount';

  @override
  String get fullTank => 'Full tank';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsGeneral => 'General preferences';

  @override
  String get noActiveVehicle => 'No active vehicle';

  @override
  String get odometerKm => 'Odometer (km)';

  @override
  String get editService => 'Edit Service Entry';

  @override
  String get serviceNoEntries => 'No service entries yet';

  @override
  String get serviceDate => 'Date';

  @override
  String get serviceOdometer => 'Odometer (km)';

  @override
  String get serviceDescription => 'Description';

  @override
  String get serviceAmount => 'Total amount';

  @override
  String get serviceNotes => 'Notes';

  @override
  String get serviceInvoice => 'Invoice';

  @override
  String get deleted => 'Deleted';

  @override
  String get settingsMaintenance => 'Maintenance & Data Integrity';

  @override
  String get runIntegrityCheck => 'Run data integrity check';

  @override
  String get integrityOk => 'No issues found';

  @override
  String get integrityIssuesFound => 'Issues found';

  @override
  String get autoBackupOk => 'Automatic backup completed';

  @override
  String get autoBackupFailed => 'Automatic backup failed';

  @override
  String get integrityReportTitle => 'Data Integrity Report';

  @override
  String integrityReportSummary(Object fuel, Object service) {
    return 'Fuel: $fuel, Service: $service';
  }

  @override
  String get settingsExportCsvSubtitle => 'Fuel & Service entries as CSV files';

  @override
  String get settingsRestoreSubtitle => 'Import from the latest backup file';

  @override
  String get ok => 'OK';

  @override
  String get settingsVersion => 'Version';

  @override
  String get version => 'Version';

  @override
  String get validationRequired => 'Required field';

  @override
  String get errorFutureDateNotAllowed => 'Future date not allowed';

  @override
  String get exportSuccess => 'Export completed';

  @override
  String get openFolder => 'Open folder';

  @override
  String get exportFuelPdf => 'Export Fuel PDF';

  @override
  String get exportServicePdf => 'Export Service PDF';

  @override
  String get pdfTitleFuel => 'Fuel Export';

  @override
  String get pdfTitleService => 'Service Export';

  @override
  String get pdfMetaVehicle => 'Vehicle';

  @override
  String get pdfMetaDriver => 'Driver';

  @override
  String get pdfMetaCreatedAt => 'Created at';

  @override
  String get pdfSummary => 'Summary';

  @override
  String get pdfCount => 'Count';

  @override
  String get pdfTotalLiters => 'Total liters';

  @override
  String get pdfTotalAmount => 'Total amount';

  @override
  String get statsFilters => 'Filters';

  @override
  String get filterVehicle => 'Vehicle';

  @override
  String get filterDriver => 'Driver';

  @override
  String get filterDateRange => 'Date range';

  @override
  String get range3m => 'Last 3 months';

  @override
  String get range6m => 'Last 6 months';

  @override
  String get range12m => 'Last 12 months';

  @override
  String get allDrivers => 'All';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get statsReportTitle => 'Statistics Report';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get pdfKpiHeader => 'Key Performance Indicators';

  @override
  String get pdfMonthlyOverviewHeader => 'Monthly Cost Overview (Last 12 Months)';

  @override
  String get pdfPageFooter => 'Page';

  @override
  String get pdfPageOf => 'of';

  @override
  String get useSnapshotCache => 'Use Snapshot Cache';

  @override
  String get useSnapshotCacheDesc => 'Accelerate cold start using a local JSON snapshot';

  @override
  String get pdfExport => 'PDF Export';

  @override
  String get activeVehicleReport => 'Active Vehicle Report';

  @override
  String get litersHeader => 'Liters';

  @override
  String get amountHeader => 'Amount';

  @override
  String get odometerHeader => 'Odometer';

  @override
  String get pricePerLiterHeader => 'Price/L';

  @override
  String get avgConsumptionHeader => 'Average consumption (L/100km)';

  @override
  String get costPerKmHeader => 'Cost per km (€)';

  @override
  String get monthlyCostHeader => 'Monthly cost';

  @override
  String get pdfGeneratedFooter => 'Generated by Fuel & Service Log — v1.1';

  @override
  String get exportPdfActiveVehicle => 'Export PDF (Active Vehicle)';

  @override
  String get stats_noDataInSelectedFilters => 'No data in selected filters';
}
