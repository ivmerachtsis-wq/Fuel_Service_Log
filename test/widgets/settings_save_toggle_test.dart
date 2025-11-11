import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/ui/tabs/settings_tab.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/services/save_target_resolver.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import '../fakes/fake_save_target_resolver.dart';
import '../test_channel_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings save path toggle', () {
    late SettingsController settingsController;
    late UiPrefsMemory uiPrefs;
    late FakeSaveTargetResolver fakeResolver;

    setUp(() async {
      // Mock platform channels to prevent hangs
      await mockAllPlatformChannels();
      
      // Inject fake resolver
      fakeResolver = FakeSaveTargetResolver();
      SaveTargetResolverProvider.instance = fakeResolver;
      
      // Use memory-based prefs (no real Hive IO)
      uiPrefs = UiPrefsMemory();
      
      // Initialize Hive with unique directory per test to avoid file locks
      final testDir = '${Directory.systemTemp.path}/hive_test_${DateTime.now().millisecondsSinceEpoch}';
      Hive.init(testDir);
      
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }
      
      settingsController = SettingsController();
      await settingsController.init();
    });

    tearDown(() async {
      fakeResolver.reset();
      
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').clear();
        await Hive.box('settings').close();
      }
      await Hive.deleteFromDisk();
      
      // Reset resolver to production impl
      SaveTargetResolverProvider.instance = SaveTargetResolverImpl();
    });

    testWidgets('Settings tab renders save path toggle', (tester) async {
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

      // Use bounded pump instead of pumpAndSettle
      await tester.pump(const Duration(milliseconds: 100));

      // Find the toggle by looking for the text
      expect(find.text('Ask where to save (PDF/CSV/Backup)'), findsOneWidget);
      
      // Find the switch widget (should be the second one after snapshot cache)
      final switches = find.byType(Switch);
      expect(switches, findsAtLeastNWidgets(2));
    });

    testWidgets('Toggle starts in OFF state by default', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 100));

      // Verify default is false
      expect(uiPrefs.loadAskWhereToSave(), isFalse);
    });

    testWidgets('Tapping toggle changes state and persists', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 100));

      // Find the save path toggle switch by key
      final switchFinder = find.byKey(const Key('settings.askWhereToSave.switch'));
      expect(switchFinder, findsOneWidget);
      
      // Verify starts as OFF
      Switch switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
      
      // Tap to enable
      await tester.tap(switchFinder);
      await tester.pump(); // Trigger the onChanged callback
      await tester.pump(const Duration(milliseconds: 100)); // Allow setState to complete

      // Verify it's now ON
      switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
      
      // Verify persisted to prefs
      expect(uiPrefs.loadAskWhereToSave(), isTrue);
    });

    testWidgets('Toggle calls resolver when enabled', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 100));

      // Enable the toggle
      final switchFinder = find.byKey(const Key('settings.askWhereToSave.switch'));
      await tester.tap(switchFinder);
      await tester.pump(); // Trigger onChanged
      await tester.pump(const Duration(milliseconds: 100)); // Allow setState

      // Verify toggle is ON
      expect(uiPrefs.loadAskWhereToSave(), isTrue);

      // Now simulate calling resolver (what export/backup services will do)
      final dir = await SaveTargetResolverProvider.instance.resolveDirectory(
        SaveKind.pdf,
        ask: uiPrefs.loadAskWhereToSave(),
        defaultDir: Directory.systemTemp,
      );

      // Verify resolver was called
      expect(fakeResolver.calls, greaterThanOrEqualTo(1));
      expect(fakeResolver.lastAsk, isTrue);
      expect(fakeResolver.lastKind, SaveKind.pdf);
      expect(dir, isNotNull);
    });
  });
}

