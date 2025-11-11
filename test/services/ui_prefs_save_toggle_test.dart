import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';

void main() {
  group('UiPrefsMemory - Ask where to save toggle', () {
    late UiPrefsMemory service;

    setUp(() {
      service = UiPrefsMemory();
    });

    test('loadAskWhereToSave returns false when not set', () {
      final result = service.loadAskWhereToSave();
      expect(result, equals(false));
    });

    test('saveAskWhereToSave and loadAskWhereToSave round-trip for true', () async {
      await service.saveAskWhereToSave(true);
      final loaded = service.loadAskWhereToSave();
      expect(loaded, equals(true));
    });

    test('saveAskWhereToSave and loadAskWhereToSave round-trip for false', () async {
      await service.saveAskWhereToSave(false);
      final loaded = service.loadAskWhereToSave();
      expect(loaded, equals(false));
    });

    test('saveAskWhereToSave can toggle value multiple times', () async {
      await service.saveAskWhereToSave(true);
      expect(service.loadAskWhereToSave(), equals(true));

      await service.saveAskWhereToSave(false);
      expect(service.loadAskWhereToSave(), equals(false));

      await service.saveAskWhereToSave(true);
      expect(service.loadAskWhereToSave(), equals(true));
    });

    test('Persists together with other prefs without interference', () async {
      // Set stats prefs
      await service.saveStatsMetric(StatsMetric.liters);
      await service.saveStatsFilter(StatsFilter.last30());
      
      // Set ask where to save
      await service.saveAskWhereToSave(true);
      
      // Verify all persisted independently
      expect(service.loadStatsMetric(), equals(StatsMetric.liters));
      expect(service.loadStatsFilter().preset, equals(StatsPreset.last30));
      expect(service.loadAskWhereToSave(), equals(true));
    });
  });
}
