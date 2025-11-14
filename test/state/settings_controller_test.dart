import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:fuel_service_log/state/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsController', () {
    late Directory tempDir;
    late SettingsController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('settings_test_');
      Hive.init(tempDir.path);
      controller = SettingsController();
      await controller.init();
    });

    tearDown(() async {
      if (Hive.isBoxOpen('settings')) {
        await Hive.box('settings').close();
      }
      await tempDir.delete(recursive: true);
    });

    test('default appTheme is system', () {
      expect(controller.appTheme, AppTheme.system);
    });

    test('setAppTheme persists and notifies', () async {
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.setAppTheme(AppTheme.midnight);
      expect(controller.appTheme, AppTheme.midnight);
      expect(controller.themeMode, ThemeMode.dark);
      expect(notified, isTrue);
    });

    test('setAppTheme to comfortLight sets light mode', () async {
      await controller.setAppTheme(AppTheme.comfortLight);
      expect(controller.appTheme, AppTheme.comfortLight);
      expect(controller.themeMode, ThemeMode.light);
    });

    test('setAppTheme persists to Hive', () async {
      await controller.setAppTheme(AppTheme.midnight);
      
      // Create new controller instance to verify persistence
      final controller2 = SettingsController();
      await controller2.init();
      
      expect(controller2.appTheme, AppTheme.midnight);
      expect(controller2.themeMode, ThemeMode.dark);
    });

    test('all AppTheme values have correct ThemeMode mapping', () async {
      await controller.setAppTheme(AppTheme.system);
      expect(controller.themeMode, ThemeMode.system);

      await controller.setAppTheme(AppTheme.light);
      expect(controller.themeMode, ThemeMode.light);

      await controller.setAppTheme(AppTheme.dark);
      expect(controller.themeMode, ThemeMode.dark);

      await controller.setAppTheme(AppTheme.comfortLight);
      expect(controller.themeMode, ThemeMode.light);

      await controller.setAppTheme(AppTheme.midnight);
      expect(controller.themeMode, ThemeMode.dark);
    });
  });
}
