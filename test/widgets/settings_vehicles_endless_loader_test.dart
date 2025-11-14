import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/ui/tabs/settings_tab.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings vehicles endless loader guard', () {
    late SettingsController settingsController;
    late UiPrefsMemory uiPrefs;

    setUp(() async {
      // Memory prefs
      uiPrefs = UiPrefsMemory();

      // Hive init only with settings box; DO NOT open vehicles box
      final testDir = '${Directory.systemTemp.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testDir);

      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }

      settingsController = SettingsController();
      await settingsController.init();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').clear();
        await Hive.box('settings').close();
      }
      await Hive.deleteFromDisk();
    });

    testWidgets('shows brief spinner then empty state within ~1s', (tester) async {
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

      // Initial frame, potentially shows tiny progress
      await tester.pump(const Duration(milliseconds: 100));

      // After 600ms total, the empty state should be visible even if vehicles box isn't open
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('No vehicles'), findsWidgets);

      // Ensure there's no large infinite spinner in the tree
      // Accept small progress indicator may exist transiently; after 1s it should be gone
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
