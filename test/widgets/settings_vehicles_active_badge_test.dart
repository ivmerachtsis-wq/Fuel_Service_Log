import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/ui/tabs/settings_tab.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings vehicles active badge', () {
    late SettingsController settingsController;
    late UiPrefsMemory uiPrefs;
    late Directory tempDir;

    setUp(() async {
      uiPrefs = UiPrefsMemory();

      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(VehicleAdapter());
      }

      await Hive.openBox<Vehicle>('vehicles');

      settingsController = SettingsController();
      await settingsController.init();

      // Seed two vehicles
      final box = Hive.box<Vehicle>('vehicles');
      await box.put('v1', Vehicle(id: 'v1', title: 'Car 1', active: false, currencyCode: 'EUR'));
      await box.put('v2', Vehicle(id: 'v2', title: 'Car 2', active: false, currencyCode: 'EUR'));

      // Set active in prefs
      await uiPrefs.saveActiveVehicleId('v1');
    });

    tearDown(() async {
      // Dispose settings controller
      settingsController.dispose();
      
      // Close vehicles box with correct type
      if (Hive.isBoxOpen('vehicles')) {
        await Hive.box<Vehicle>('vehicles').close();
      }
      
      // Close settings
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').close();
      }
      
      // Delete temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('shows Active badge for the selected vehicle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: SettingsTab(
              settings: settingsController,
              uiPrefs: uiPrefs,
            ),
          ),
        ),
      );

      // Allow initial build
      await tester.pump();

      expect(find.text('Car 1'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Change active via long press on Car 2
      await tester.longPress(find.text('Car 2'));
      await tester.pump();

      // Now Car 2 should have the badge
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
