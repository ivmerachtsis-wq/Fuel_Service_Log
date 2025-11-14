import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel & Service Log'**
  String get appTitle;

  /// No description provided for @tabFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get tabFuel;

  /// No description provided for @tabService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get tabService;

  /// No description provided for @tabStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get tabStats;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;
  String get tabVehicles;

  /// No description provided for @emptyFuel.
  ///
  /// In en, this message translates to:
  /// **'No fuel entries yet'**
  String get emptyFuel;

  /// No description provided for @emptyService.
  ///
  /// In en, this message translates to:
  /// **'No service entries yet'**
  String get emptyService;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @addFuel.
  ///
  /// In en, this message translates to:
  /// **'Add Fuel Entry'**
  String get addFuel;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service Entry'**
  String get addService;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @backupJson.
  ///
  /// In en, this message translates to:
  /// **'Backup JSON'**
  String get backupJson;

  /// No description provided for @restoreJson.
  ///
  /// In en, this message translates to:
  /// **'Restore JSON'**
  String get restoreJson;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get languageGreek;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyEUR.
  ///
  /// In en, this message translates to:
  /// **'Euro (€)'**
  String get currencyEUR;

  /// No description provided for @currencyUSD.
  ///
  /// In en, this message translates to:
  /// **'US Dollar (\$)'**
  String get currencyUSD;

  /// No description provided for @currencyGBP.
  ///
  /// In en, this message translates to:
  /// **'British Pound (£)'**
  String get currencyGBP;

  /// No description provided for @successExport.
  ///
  /// In en, this message translates to:
  /// **'Export completed successfully'**
  String get successExport;

  /// No description provided for @successBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get successBackup;

  /// No description provided for @successRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore completed successfully'**
  String get successRestore;

  /// No description provided for @kpiAvgConsumption.
  ///
  /// In en, this message translates to:
  /// **'Average consumption (L/100km)'**
  String get kpiAvgConsumption;

  /// No description provided for @kpiMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Monthly cost (last 6)'**
  String get kpiMonthlyCost;

  /// No description provided for @kpiCostPerKm.
  ///
  /// In en, this message translates to:
  /// **'Cost per km'**
  String get kpiCostPerKm;

  /// No description provided for @kpiLitersPer100km.
  ///
  /// In en, this message translates to:
  /// **'Consumption (L/100km)'**
  String get kpiLitersPer100km;

  /// No description provided for @kpiDistanceWindow.
  ///
  /// In en, this message translates to:
  /// **'Distance (window)'**
  String get kpiDistanceWindow;

  /// No description provided for @chartNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data for statistics'**
  String get chartNoData;

  /// No description provided for @chartAxisDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get chartAxisDate;

  /// No description provided for @chartAxisConsumption.
  ///
  /// In en, this message translates to:
  /// **'L/100km'**
  String get chartAxisConsumption;

  /// No description provided for @statsHintFullToFull.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 full-tank refuels to see consumption statistics'**
  String get statsHintFullToFull;

  /// No description provided for @noFuelEntries.
  ///
  /// In en, this message translates to:
  /// **'No fuel entries yet'**
  String get noFuelEntries;

  /// No description provided for @addFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Fuel'**
  String get addFuelTitle;

  /// No description provided for @editFuelTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Fuel'**
  String get editFuelTitle;

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get liters;

  /// No description provided for @pricePerLiter.
  ///
  /// In en, this message translates to:
  /// **'Price per liter'**
  String get pricePerLiter;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @fullTank.
  ///
  /// In en, this message translates to:
  /// **'Full tank'**
  String get fullTank;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General preferences'**
  String get settingsGeneral;

  /// No description provided for @noActiveVehicle.
  ///
  /// In en, this message translates to:
  /// **'No active vehicle'**
  String get noActiveVehicle;

  /// No description provided for @odometerKm.
  ///
  /// In en, this message translates to:
  /// **'Odometer (km)'**
  String get odometerKm;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service Entry'**
  String get editService;

  /// No description provided for @serviceNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No service entries yet'**
  String get serviceNoEntries;

  /// No description provided for @serviceDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get serviceDate;

  /// No description provided for @serviceOdometer.
  ///
  /// In en, this message translates to:
  /// **'Odometer (km)'**
  String get serviceOdometer;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get serviceDescription;

  /// No description provided for @serviceAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get serviceAmount;

  /// No description provided for @serviceNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get serviceNotes;

  /// No description provided for @serviceInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get serviceInvoice;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @settingsMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance & Data Integrity'**
  String get settingsMaintenance;

  /// No description provided for @runIntegrityCheck.
  ///
  /// In en, this message translates to:
  /// **'Run data integrity check'**
  String get runIntegrityCheck;

  /// No description provided for @integrityOk.
  ///
  /// In en, this message translates to:
  /// **'No issues found'**
  String get integrityOk;

  /// No description provided for @integrityIssuesFound.
  ///
  /// In en, this message translates to:
  /// **'Issues found'**
  String get integrityIssuesFound;

  /// No description provided for @autoBackupOk.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup completed'**
  String get autoBackupOk;

  /// No description provided for @autoBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup failed'**
  String get autoBackupFailed;

  /// No description provided for @integrityReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Integrity Report'**
  String get integrityReportTitle;

  /// No description provided for @integrityReportSummary.
  ///
  /// In en, this message translates to:
  /// **'Fuel: {fuel}, Service: {service}'**
  String integrityReportSummary(Object fuel, Object service);

  /// No description provided for @settingsExportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fuel & Service entries as CSV files'**
  String get settingsExportCsvSubtitle;

  /// No description provided for @settingsRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import from the latest backup file'**
  String get settingsRestoreSubtitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get validationRequired;

  /// No description provided for @errorFutureDateNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Future date not allowed'**
  String get errorFutureDateNotAllowed;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export completed'**
  String get exportSuccess;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @exportFuelPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Fuel PDF'**
  String get exportFuelPdf;

  /// No description provided for @exportServicePdf.
  ///
  /// In en, this message translates to:
  /// **'Export Service PDF'**
  String get exportServicePdf;

  /// No description provided for @pdfTitleFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Export'**
  String get pdfTitleFuel;

  /// No description provided for @pdfTitleService.
  ///
  /// In en, this message translates to:
  /// **'Service Export'**
  String get pdfTitleService;

  /// No description provided for @pdfMetaVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get pdfMetaVehicle;

  /// No description provided for @pdfMetaDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get pdfMetaDriver;

  /// No description provided for @pdfMetaCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get pdfMetaCreatedAt;

  /// No description provided for @pdfSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get pdfSummary;

  /// No description provided for @pdfCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get pdfCount;

  /// No description provided for @pdfTotalLiters.
  ///
  /// In en, this message translates to:
  /// **'Total liters'**
  String get pdfTotalLiters;

  /// No description provided for @pdfTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get pdfTotalAmount;

  /// No description provided for @statsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get statsFilters;

  /// No description provided for @filterVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get filterVehicle;

  /// No description provided for @filterDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get filterDriver;

  /// No description provided for @filterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get filterDateRange;

  /// No description provided for @filtersVehicleActive.
  ///
  /// In en, this message translates to:
  /// **'Active vehicle'**
  String get filtersVehicleActive;

  /// No description provided for @filtersVehicleAll.
  ///
  /// In en, this message translates to:
  /// **'All vehicles'**
  String get filtersVehicleAll;

  /// No description provided for @filtersAllEntries.
  ///
  /// In en, this message translates to:
  /// **'All entries'**
  String get filtersAllEntries;

  /// No description provided for @range3m.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get range3m;

  /// No description provided for @range6m.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get range6m;

  /// No description provided for @range12m.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get range12m;

  /// No description provided for @allDrivers.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allDrivers;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @statsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics Report'**
  String get statsReportTitle;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @pdfKpiHeader.
  ///
  /// In en, this message translates to:
  /// **'Key Performance Indicators'**
  String get pdfKpiHeader;

  /// No description provided for @pdfMonthlyOverviewHeader.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cost Overview (Last 12 Months)'**
  String get pdfMonthlyOverviewHeader;

  /// No description provided for @pdfPageFooter.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pdfPageFooter;

  /// No description provided for @pdfPageOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get pdfPageOf;

  /// No description provided for @useSnapshotCache.
  ///
  /// In en, this message translates to:
  /// **'Use Snapshot Cache'**
  String get useSnapshotCache;

  /// No description provided for @useSnapshotCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Accelerate cold start using a local JSON snapshot'**
  String get useSnapshotCacheDesc;

  /// No description provided for @pdfExport.
  ///
  /// In en, this message translates to:
  /// **'PDF Export'**
  String get pdfExport;

  /// No description provided for @activeVehicleReport.
  ///
  /// In en, this message translates to:
  /// **'Active Vehicle Report'**
  String get activeVehicleReport;

  /// No description provided for @litersHeader.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get litersHeader;

  /// No description provided for @amountHeader.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountHeader;

  /// No description provided for @odometerHeader.
  ///
  /// In en, this message translates to:
  /// **'Odometer'**
  String get odometerHeader;

  /// No description provided for @pricePerLiterHeader.
  ///
  /// In en, this message translates to:
  /// **'Price/L'**
  String get pricePerLiterHeader;

  /// No description provided for @avgConsumptionHeader.
  ///
  /// In en, this message translates to:
  /// **'Average consumption (L/100km)'**
  String get avgConsumptionHeader;

  /// No description provided for @costPerKmHeader.
  ///
  /// In en, this message translates to:
  /// **'Cost per km (€)'**
  String get costPerKmHeader;

  /// No description provided for @monthlyCostHeader.
  ///
  /// In en, this message translates to:
  /// **'Monthly cost'**
  String get monthlyCostHeader;

  /// No description provided for @pdfGeneratedFooter.
  ///
  /// In en, this message translates to:
  /// **'Generated by Fuel & Service Log — v1.1'**
  String get pdfGeneratedFooter;

  /// No description provided for @exportPdfActiveVehicle.
  ///
  /// In en, this message translates to:
  /// **'Export PDF (Active Vehicle)'**
  String get exportPdfActiveVehicle;

  /// Shown when the active stats filter yields no entries in PDF/UI.
  ///
  /// In en, this message translates to:
  /// **'No data in selected filters'**
  String get stats_noDataInSelectedFilters;

  /// Settings toggle to enable platform file/folder pickers before saving exports and backups.
  ///
  /// In en, this message translates to:
  /// **'Ask where to save (PDF/CSV/Backup)'**
  String get settingsAskWhereToSave;

  /// No description provided for @settings_vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get settings_vehicles;

  /// No description provided for @vehicle_add.
  ///
  /// In en, this message translates to:
  /// **'Add vehicle'**
  String get vehicle_add;

  /// No description provided for @vehicle_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get vehicle_edit;

  /// No description provided for @vehicle_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete vehicle'**
  String get vehicle_delete;

  /// No description provided for @vehicle_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get vehicle_name;

  /// No description provided for @vehicle_plate.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get vehicle_plate;

  /// No description provided for @vehicle_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get vehicle_currency;

  /// No description provided for @vehicle_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get vehicle_save;

  /// No description provided for @vehicle_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get vehicle_cancel;

  /// No description provided for @vehicle_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this vehicle?'**
  String get vehicle_delete_confirm;

  /// No description provided for @vehicle_deleted_undo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted — Undo?'**
  String get vehicle_deleted_undo;

  /// No description provided for @error_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get error_required;

  /// No description provided for @error_currency3.
  ///
  /// In en, this message translates to:
  /// **'Use a 3-letter currency code (e.g., EUR)'**
  String get error_currency3;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @metric_eur.
  ///
  /// In en, this message translates to:
  /// **'€'**
  String get metric_eur;

  /// No description provided for @metric_liters.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get metric_liters;

  /// No description provided for @metric_km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get metric_km;

  /// No description provided for @metric_l_per_100km.
  ///
  /// In en, this message translates to:
  /// **'L/100km'**
  String get metric_l_per_100km;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['el', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el': return AppLocalizationsEl();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
