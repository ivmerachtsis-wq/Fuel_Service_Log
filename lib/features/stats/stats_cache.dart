import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/cache/cache_invalidator.dart';
import '../../domain/stats_service.dart';
import '../../data/models/fuel_entry.dart';

/// Stats aggregation cache with selective invalidation.
/// 
/// Memoizes expensive computations (avg consumption, monthly costs) and
/// invalidates only when relevant data changes (per-vehicle granularity).
class StatsCache {
  final StatsService _statsService = StatsService();
  final CacheInvalidator _invalidator = CacheInvalidator();

  // Cache key: "${vehicleId}_${periodKey}" → computed result
  final Map<String, _CachedStats> _cache = {};

  // Revision counters per vehicle for UI rebuilds
  final Map<String, ValueNotifier<int>> _revisions = {};

  StreamSubscription? _eventSubscription;

  /// Initialize cache and wire invalidation listeners.
  void init() {
    _eventSubscription = _invalidator.events.listen((event) {
      // Invalidate stats for affected vehicle
      if (event.vehicleId != null) {
        _invalidateVehicle(event.vehicleId!);
      } else if (event.boxName == 'vehicles') {
        // Full invalidation on vehicle changes (add/delete)
        _cache.clear();
        for (final notifier in _revisions.values) {
          notifier.value++;
        }
      }
    });
  }

  /// Get revision notifier for a vehicle (for ValueListenableBuilder).
  ValueNotifier<int> revisionForVehicle(String vehicleId) {
    return _revisions.putIfAbsent(vehicleId, () => ValueNotifier<int>(0));
  }

  /// Get average consumption (memoized, runs in isolate if uncached).
  Future<double> getAverageConsumption({
    required String vehicleId,
    required List<FuelEntry> entries,
    required DateTime from,
    required DateTime to,
    String? driverId,
  }) async {
    final key = _buildKey(vehicleId, from, to, driverId);
    
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (cached.avgConsumption != null) {
        debugPrint('[StatsCache] HIT: avgConsumption for $key');
        return cached.avgConsumption!;
      }
    }

    // MISS: compute in isolate
    debugPrint('[StatsCache] MISS: computing avgConsumption for $key');
    final consumptions = await compute(_computeConsumptions, {
      'entries': entries,
      'from': from,
      'to': to,
      'driverId': driverId,
    });

    final avg = _statsService.getAverageConsumption(consumptions);
    
    _cache[key] = (_cache[key] ?? _CachedStats()).copyWith(avgConsumption: avg);
    return avg;
  }

  /// Get monthly costs (memoized, runs in isolate if uncached).
  Future<List<MonthlyCost>> getMonthlyCosts({
    required String vehicleId,
    required List<FuelEntry> entries,
    required int months,
    required DateTime from,
    required DateTime to,
    String? driverId,
  }) async {
    final key = _buildKey(vehicleId, from, to, driverId);
    
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (cached.monthlyCosts != null) {
        debugPrint('[StatsCache] HIT: monthlyCosts for $key');
        return cached.monthlyCosts!;
      }
    }

    // MISS: compute in isolate
    debugPrint('[StatsCache] MISS: computing monthlyCosts for $key');
    final costs = await compute(_computeMonthlyCosts, {
      'entries': entries,
      'months': months,
      'from': from,
      'to': to,
      'driverId': driverId,
    });

    _cache[key] = (_cache[key] ?? _CachedStats()).copyWith(monthlyCosts: costs);
    return costs;
  }

  String _buildKey(String vehicleId, DateTime from, DateTime to, String? driverId) {
    final period = '${from.toIso8601String()}_${to.toIso8601String()}';
    final driver = driverId ?? 'all';
    return '${vehicleId}_${period}_$driver';
  }

  void _invalidateVehicle(String vehicleId) {
    // Remove all cache entries for this vehicle
    _cache.removeWhere((key, _) => key.startsWith('${vehicleId}_'));
    
    // Bump revision to trigger UI rebuild
    revisionForVehicle(vehicleId).value++;
    
    debugPrint('[StatsCache] Invalidated vehicle: $vehicleId');
  }

  void dispose() {
    _eventSubscription?.cancel();
    for (final notifier in _revisions.values) {
      notifier.dispose();
    }
  }
}

/// Cached stats data.
class _CachedStats {
  final double? avgConsumption;
  final List<MonthlyCost>? monthlyCosts;

  const _CachedStats({this.avgConsumption, this.monthlyCosts});

  _CachedStats copyWith({double? avgConsumption, List<MonthlyCost>? monthlyCosts}) {
    return _CachedStats(
      avgConsumption: avgConsumption ?? this.avgConsumption,
      monthlyCosts: monthlyCosts ?? this.monthlyCosts,
    );
  }
}

/// Isolate function for consumption computation.
List<ConsumptionPoint> _computeConsumptions(Map<String, dynamic> params) {
  final entries = params['entries'] as List<FuelEntry>;
  final from = params['from'] as DateTime;
  final to = params['to'] as DateTime;
  final driverId = params['driverId'] as String?;

  final statsService = StatsService();
  return statsService.getFullToFullConsumptions(
    entries,
    from: from,
    to: to,
    driverId: driverId,
  );
}

/// Isolate function for monthly cost computation.
List<MonthlyCost> _computeMonthlyCosts(Map<String, dynamic> params) {
  final entries = params['entries'] as List<FuelEntry>;
  final months = params['months'] as int;
  final from = params['from'] as DateTime;
  final to = params['to'] as DateTime;
  final driverId = params['driverId'] as String?;

  final statsService = StatsService();
  return statsService.getMonthlyCost(
    entries,
    months: months,
    from: from,
    to: to,
    driverId: driverId,
  );
}
