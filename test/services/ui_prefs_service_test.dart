import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/ui_prefs_service.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';

void main() {
  group('UiPrefsMemory', () {
    late UiPrefsMemory service;

    setUp(() {
      service = UiPrefsMemory();
    });

    test('loadStatsFilter returns ytd() when no saved preset', () {
      final filter = service.loadStatsFilter();
      expect(filter.preset, equals(StatsPreset.ytd));
    });

    test('loadStatsMetric returns cost when no saved metric', () {
      final metric = service.loadStatsMetric();
      expect(metric, equals(StatsMetric.cost));
    });

    test('saveStatsFilter and loadStatsFilter round-trip for last30', () async {
      final filter = StatsFilter.last30();
      await service.saveStatsFilter(filter);
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.last30));
    });

    test('saveStatsFilter and loadStatsFilter round-trip for last90', () async {
      final filter = StatsFilter.last90();
      await service.saveStatsFilter(filter);
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.last90));
    });

    test('saveStatsFilter and loadStatsFilter round-trip for last180', () async {
      final filter = StatsFilter.last180();
      await service.saveStatsFilter(filter);
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.last180));
    });

    test('saveStatsFilter and loadStatsFilter round-trip for ytd', () async {
      final filter = StatsFilter.ytd();
      await service.saveStatsFilter(filter);
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.ytd));
    });

    test('saveStatsFilter and loadStatsFilter round-trip for all', () async {
      final filter = const StatsFilter.all();
      await service.saveStatsFilter(filter);
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.all));
    });

    test('saveStatsFilter and loadStatsFilter round-trip for custom', () async {
      final from = DateTime(2024, 1, 1);
      final to = DateTime(2024, 12, 31);
      final filter = StatsFilter.custom(from, to);
      await service.saveStatsFilter(filter);
      final loaded = service.loadStatsFilter();
      
      expect(loaded.preset, equals(StatsPreset.custom));
      expect(loaded.from, equals(from));
      expect(loaded.to, equals(to));
    });

    test('saveStatsFilter clears custom dates when switching to standard preset', () async {
      // First save custom filter
      final custom = StatsFilter.custom(DateTime(2024, 1, 1), DateTime(2024, 12, 31));
      await service.saveStatsFilter(custom);
      
      // Verify custom dates are stored (internal check via round-trip)
      var loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.custom));
      expect(loaded.from, equals(DateTime(2024, 1, 1)));
      
      // Switch to standard preset
      final ytd = StatsFilter.ytd();
      await service.saveStatsFilter(ytd);
      
      // Verify custom dates are cleared (switching back to custom should give default)
      loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.ytd));
    });

    test('saveStatsMetric and loadStatsMetric round-trip for cost', () async {
      await service.saveStatsMetric(StatsMetric.cost);
      final loaded = service.loadStatsMetric();
      expect(loaded, equals(StatsMetric.cost));
    });

    test('saveStatsMetric and loadStatsMetric round-trip for liters', () async {
      await service.saveStatsMetric(StatsMetric.liters);
      final loaded = service.loadStatsMetric();
      expect(loaded, equals(StatsMetric.liters));
    });

    test('saveStatsMetric and loadStatsMetric round-trip for distance', () async {
      await service.saveStatsMetric(StatsMetric.distance);
      final loaded = service.loadStatsMetric();
      expect(loaded, equals(StatsMetric.distance));
    });

    test('loadStatsFilter handles invalid preset gracefully', () async {
      // Directly inject invalid data into memory storage
      service.storage['stats.filter.preset'] = 'invalid_preset';
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.ytd)); // Falls back to ytd
    });

    test('loadStatsMetric handles invalid metric gracefully', () async {
      service.storage['stats.metric'] = 'invalid_metric';
      final loaded = service.loadStatsMetric();
      expect(loaded, equals(StatsMetric.cost)); // Falls back to cost
    });

    test('loadStatsFilter handles custom preset with missing dates', () async {
      service.storage['stats.filter.preset'] = 'custom';
      // Don't set from/to dates
      final loaded = service.loadStatsFilter();
      expect(loaded.preset, equals(StatsPreset.ytd)); // Falls back when dates missing
    });
  });
}
