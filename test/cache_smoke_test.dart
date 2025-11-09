import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';

import 'package:fuel_service_log/core/cache/cached_box_service.dart';
import 'package:fuel_service_log/core/diagnostics/app_start_metrics.dart';

void main() {
  group('CachedBoxService — L1 RAM cache (CRUD, watch, revision)', () {
    late Box<String> box;
    late CachedBoxService<String> cache;
    final receivedEvents = <dynamic>[];

    setUp(() async {
      await setUpTestHive();
      box = await Hive.openBox<String>('test_box');
      cache = CachedBoxService<String>(box, 'test_box');
      await cache.init();

      receivedEvents.clear();
      cache.watch().listen(receivedEvents.add);
    });

    tearDown(() async {
      cache.dispose();
      await box.close();
      await tearDownTestHive();
    });

    test('αρχικοποίηση: getAll() είναι κενό & revision ξεκινά', () {
      expect(cache.getAll(), isEmpty);
      expect(cache.revision.value, isA<int>());
    });

    test('put/get/delete ενημερώνουν RAM + revision + events', () async {
      final initialRev = cache.revision.value;

      await cache.put('k1', 'v1');
      expect(cache.get('k1'), 'v1');
      expect(cache.getAll(), contains('v1'));
      expect(cache.revision.value, greaterThan(initialRev));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(receivedEvents.length, greaterThanOrEqualTo(1));

      final revAfterPut = cache.revision.value;

      await cache.delete('k1');
      expect(cache.get('k1'), isNull);
      expect(cache.getAll(), isNot(contains('v1')));
      expect(cache.revision.value, greaterThan(revAfterPut));

      await Future.delayed(const Duration(milliseconds: 10));
      expect(receivedEvents.length, greaterThanOrEqualTo(2));
    });
  });

  group('AppStartMetrics — t0/t1/t2 & summary()', () {
    test('παράγονται με αύξουσες τιμές και formatted summary', () async {
      AppStartMetrics.markT0();
      await Future.delayed(const Duration(milliseconds: 5));
      AppStartMetrics.markT1();
      await Future.delayed(const Duration(milliseconds: 5));
      AppStartMetrics.markT2();

      final summary = AppStartMetrics.summary();
      expect(summary, contains('t0='));
      expect(summary, contains('t1='));
      expect(summary, contains('t2='));
    });
  });
}
