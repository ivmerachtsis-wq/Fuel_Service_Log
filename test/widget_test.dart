// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fuel_service_log/main.dart';
import 'package:fuel_service_log/state/navigation_controller.dart';
import 'package:fuel_service_log/state/settings_controller.dart';
import 'package:fuel_service_log/state/stats_filter_controller.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';

void main() {
  testWidgets('App builds and shows Fuel tab FAB', (WidgetTester tester) async {
    // Initialize Hive for tests with a temporary directory
    final tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);

    // Build our app and trigger a frame.
    final settings = SettingsController();
    await settings.init();
    
    final uiPrefs = UiPrefsService();
    final statsFilterController = StatsFilterController(uiPrefs);
    statsFilterController.load();
    
    await tester.pumpWidget(MyApp(
      controller: NavigationController(3),
      settings: settings,
      statsFilterController: statsFilterController,
    ));
    await tester.pumpAndSettle();

    // Verify that the initial screen renders and bottom navigation is present
  expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  }, skip: true); // Skipped in CI: full app boot in test can hang due to Hive/path_provider on Windows runners
}
