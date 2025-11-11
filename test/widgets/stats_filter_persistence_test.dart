import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/state/stats_filter_controller.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fuel_service_log/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stats filter persistence across tab switches', () {
    late UiPrefsMemory uiPrefs;
    late StatsFilterController statsFilterController;

    setUp(() {
      uiPrefs = UiPrefsMemory();
      statsFilterController = StatsFilterController(uiPrefs);
      statsFilterController.load();
    });

    testWidgets('Filter changes persist in controller state', (tester) async {
      // Verify initial state
      expect(statsFilterController.filter.preset, equals(StatsPreset.ytd));

      // Change filter
      await statsFilterController.setFilter(StatsFilter.last30());
      await tester.pump();

      // Verify it persisted
      expect(statsFilterController.filter.preset, equals(StatsPreset.last30));

      // Create new controller instance to simulate app restart
      final newController = StatsFilterController(uiPrefs);
      newController.load();

      // Verify filter survived
      expect(newController.filter.preset, equals(StatsPreset.last30));
    });

    testWidgets('Metric changes persist in controller state', (tester) async {
      // Verify initial metric
      expect(statsFilterController.metric, equals(StatsMetric.cost));

      // Change metric
      await statsFilterController.setMetric(StatsMetric.liters);
      await tester.pump();

      // Verify it changed
      expect(statsFilterController.metric, equals(StatsMetric.liters));

      // Create new controller to simulate restart
      final newController = StatsFilterController(uiPrefs);
      newController.load();

      // Verify metric survived
      expect(newController.metric, equals(StatsMetric.liters));
    });

    testWidgets('Both filter and metric persist together', (tester) async {
      // Change both
      await statsFilterController.setFilter(StatsFilter.last180());
      await statsFilterController.setMetric(StatsMetric.distance);
      await tester.pump();

      // Verify both changed
      expect(statsFilterController.filter.preset, equals(StatsPreset.last180));
      expect(statsFilterController.metric, equals(StatsMetric.distance));

      // Simulate restart
      final newController = StatsFilterController(uiPrefs);
      newController.load();

      // Verify both persisted
      expect(newController.filter.preset, equals(StatsPreset.last180));
      expect(newController.metric, equals(StatsMetric.distance));
    });

    testWidgets('Custom filter with dates persists', (tester) async {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);
      
      await statsFilterController.setFilter(StatsFilter.custom(from, to));
      await tester.pump();

      expect(statsFilterController.filter.preset, equals(StatsPreset.custom));
      expect(statsFilterController.filter.from, equals(from));
      expect(statsFilterController.filter.to, equals(to));

      // Simulate restart
      final newController = StatsFilterController(uiPrefs);
      newController.load();

      expect(newController.filter.preset, equals(StatsPreset.custom));
      expect(newController.filter.from, equals(from));
      expect(newController.filter.to, equals(to));
    });
  });
}
