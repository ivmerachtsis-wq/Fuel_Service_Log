import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:fuel_service_log/ui/tabs/stats_tab.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:fuel_service_log/state/stats_filter_controller.dart';
import 'package:fuel_service_log/state/stats_metric.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/models/driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatsMetric L/100km', () {
    late Directory tempDir;
    late SettingsController settings;
    late UiPrefsMemory prefs;
    late StatsFilterController statsController;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stats_l100km_test_');
      Hive.init(tempDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VehicleAdapter());
      if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FuelEntryAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DriverAdapter());
      if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ServiceEntryAdapter());

      // Open boxes
      await Hive.openBox<Vehicle>('vehicles');
      await Hive.openBox<FuelEntry>('fuel_entries');
      await Hive.openBox<ServiceEntry>('service_entries');
      await Hive.openBox<Driver>('drivers');

      // Seed test data: 2 full-tank entries to compute consumption
      final vehicles = Hive.box<Vehicle>('vehicles');
      await vehicles.put('v1', Vehicle(id: 'v1', title: 'Test Car', active: true, currencyCode: 'EUR'));

      final fuel = Hive.box<FuelEntry>('fuel_entries');
      // Entry 1: 50L at 10,000 km (full tank)
      await fuel.put('f1', FuelEntry(
        id: 'f1',
        vehicleId: 'v1',
        date: DateTime.now().subtract(const Duration(days: 30)),
        odometerKm: 10000,
        liters: 50,
        pricePerLiter: 2.0,
        amount: 100,
        fullTank: true,
        driverId: null,
        currencyCode: 'EUR',
      ));
      
      // Entry 2: 40L at 10,500 km (full tank) -> distance = 500km, consumption = 40/500*100 = 8 L/100km
      await fuel.put('f2', FuelEntry(
        id: 'f2',
        vehicleId: 'v1',
        date: DateTime.now().subtract(const Duration(days: 15)),
        odometerKm: 10500,
        liters: 40,
        pricePerLiter: 2.0,
        amount: 80,
        fullTank: true,
        driverId: null,
        currencyCode: 'EUR',
      ));

      settings = SettingsController();
      await settings.init();

      prefs = UiPrefsMemory();
      statsController = StatsFilterController(prefs);
      statsController.load();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('vehicles')) await Hive.box<Vehicle>('vehicles').close();
      if (Hive.isBoxOpen('fuel_entries')) await Hive.box<FuelEntry>('fuel_entries').close();
      if (Hive.isBoxOpen('service_entries')) await Hive.box<ServiceEntry>('service_entries').close();
      if (Hive.isBoxOpen('drivers')) await Hive.box<Driver>('drivers').close();
      if (Hive.isBoxOpen('settings')) await Hive.box('settings').close();
      await tempDir.delete(recursive: true);
    });

    test('StatsMetric enum includes litersPer100km', () {
      expect(StatsMetric.values, contains(StatsMetric.litersPer100km));
    });

    test('UiPrefs can persist litersPer100km metric', () async {
      await prefs.saveStatsMetric(StatsMetric.litersPer100km);
      final loaded = prefs.loadStatsMetric();
      expect(loaded, StatsMetric.litersPer100km);
    });

    testWidgets('StatsTab renders metric button for L/100km', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: StatsTab(
              settings: settings,
              statsFilterController: statsController,
            ),
          ),
        ),
      );

      // Allow initial build
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check that L/100km button exists
      expect(find.text('L/100km'), findsOneWidget);
    });

    testWidgets('Tapping L/100km button switches metric', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: StatsTab(
              settings: settings,
              statsFilterController: statsController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Initially on 'cost' metric
      expect(statsController.metric, StatsMetric.cost);

      // Tap L/100km button
      await tester.tap(find.text('L/100km'));
      await tester.pumpAndSettle();

      // Metric should be updated
      expect(statsController.metric, StatsMetric.litersPer100km);
    });

    testWidgets('L/100km metric renders without errors', (tester) async {
      // Set metric to litersPer100km before building
      statsController.setMetric(StatsMetric.litersPer100km);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: StatsTab(
              settings: settings,
              statsFilterController: statsController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Either chart renders or shows no-data message (both are valid)
      // The important thing is no errors or overflow
      final hasNoData = find.text('Not enough data for statistics').evaluate().isNotEmpty;
      final hasLegend = find.text('Consumption (L/100km)').evaluate().isNotEmpty;
      
      // At least one should be present
      expect(hasNoData || hasLegend, isTrue);
    });
  });
}
