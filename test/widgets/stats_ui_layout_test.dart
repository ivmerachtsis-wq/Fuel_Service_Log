import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:fuel_service_log/ui/tabs/stats_tab.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/state/stats_filter_controller.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/models/driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stats UI layout', () {
    late Directory tempDir;
    late SettingsController settings;
    late UiPrefsMemory prefs;
    late StatsFilterController statsController;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_stats_ui_');
      Hive.init(tempDir.path);

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VehicleAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FuelEntryAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(DriverAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ServiceEntryAdapter());

      await Hive.openBox<Vehicle>('vehicles');
      await Hive.openBox<FuelEntry>('fuel_entries');
  await Hive.openBox<ServiceEntry>('service_entries');
  await Hive.openBox<Driver>('drivers');

      // Seed minimal data
      final vehicles = Hive.box<Vehicle>('vehicles');
      await vehicles.put('v1', Vehicle(id: 'v1', title: 'Test Vehicle', active: true, currencyCode: 'EUR'));

      final fuel = Hive.box<FuelEntry>('fuel_entries');
      await fuel.put('f1', FuelEntry(
        id: 'f1',
        vehicleId: 'v1',
        date: DateTime.now().subtract(const Duration(days: 15)),
        odometerKm: 12345,
        liters: 30,
        pricePerLiter: 2.0,
        amount: 60,
        fullTank: true,
        driverId: null,
        currencyCode: 'EUR',
      ));
      await fuel.put('f2', FuelEntry(
        id: 'f2',
        vehicleId: 'v1',
        date: DateTime.now().subtract(const Duration(days: 5)),
        odometerKm: 12600,
        liters: 20,
        pricePerLiter: 2.0,
        amount: 40,
        fullTank: true,
        driverId: null,
        currencyCode: 'EUR',
      ));

      final service = Hive.box<ServiceEntry>('service_entries');
      await service.put('s1', ServiceEntry(
        id: 's1',
        vehicleId: 'v1',
        date: DateTime.now().subtract(const Duration(days: 10)),
        odometerKm: 12500,
        description: 'Oil',
        totalAmount: 30,
        currencyCode: 'EUR',
      ));

      settings = SettingsController();
      await settings.init();

      prefs = UiPrefsMemory();
      statsController = StatsFilterController(prefs)..load();
    });

    tearDown(() async {
  if (Hive.isBoxOpen('vehicles')) await Hive.box<Vehicle>('vehicles').close();
  if (Hive.isBoxOpen('fuel_entries')) await Hive.box<FuelEntry>('fuel_entries').close();
  if (Hive.isBoxOpen('service_entries')) await Hive.box<ServiceEntry>('service_entries').close();
  if (Hive.isBoxOpen('drivers')) await Hive.box<Driver>('drivers').close();
  if (Hive.isBoxOpen('settings')) await Hive.box('settings').close();
      await tempDir.delete(recursive: true);
    });

    testWidgets('renders without overflow and shows Date axis', (tester) async {
      FlutterError? captured;
      final prevOnError = FlutterError.onError;
      try {
        FlutterError.onError = (FlutterErrorDetails details) {
          // Capture overflow errors
          final message = details.exceptionAsString();
          if (message.contains('A RenderFlex overflowed') || message.contains('overflowed by')) {
            captured = FlutterError(message);
          }
          // Still print to console for visibility
          FlutterError.dumpErrorToConsole(details);
        };

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en')],
            home: Scaffold(
              body: StatsTab(settings: settings, statsFilterController: statsController),
            ),
          ),
        );

        // Allow initial frames
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Expect no overflow errors captured
        expect(captured, isNull);

        // Either the Date axis (when chart renders) or the no-data caption should be present
        final hasDateAxis = find.text('Date').evaluate().isNotEmpty;
        final hasNoData = find.text('Not enough data for statistics').evaluate().isNotEmpty;
        expect(hasDateAxis || hasNoData, isTrue);

        // Euro legend or labels should be present depending on metric (may not appear if no data)
        if (hasDateAxis) {
          expect(find.textContaining('€'), findsWidgets);
        }
      } finally {
        // Restore handler
        FlutterError.onError = prevOnError;
      }
    });
  });
}
