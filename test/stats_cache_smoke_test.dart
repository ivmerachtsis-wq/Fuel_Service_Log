import 'package:flutter_test/flutter_test.dart';

import 'package:fuel_service_log/core/cache/cache_invalidator.dart';
import 'package:fuel_service_log/features/stats/stats_cache.dart';
import 'package:fuel_service_log/state/stats_cache_provider.dart';

void main() {
  late StatsCache statsCache;

  setUp(() async {
    StatsCacheProvider().init();
    statsCache = StatsCacheProvider().cache;
  });

  tearDown(() async {
    StatsCacheProvider().dispose();
  });

  test('revisionForVehicle αυξάνεται σε FuelChanged για ίδιο vehicle', () async {
    const v1 = 'veh_1';
    final notifier = statsCache.revisionForVehicle(v1);
    final before = notifier.value;

    CacheInvalidator().emit('fuel', vehicleId: v1);

    await Future.delayed(const Duration(milliseconds: 30));

    expect(notifier.value, greaterThan(before));
  });

  test('revisionForVehicle ΔΕΝ αλλάζει αν το event αφορά άλλο vehicle', () async {
    const v1 = 'veh_1';
    const v2 = 'veh_2';
    final notifier = statsCache.revisionForVehicle(v1);
    final before = notifier.value;

    CacheInvalidator().emit('fuel', vehicleId: v2);

    await Future.delayed(const Duration(milliseconds: 30));

    expect(notifier.value, equals(before));
  });
}
