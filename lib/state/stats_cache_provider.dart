import 'package:flutter/foundation.dart';
import '../features/stats/stats_cache.dart';

/// Global singleton for StatsCache instance.
class StatsCacheProvider {
  static final StatsCacheProvider _instance = StatsCacheProvider._();
  factory StatsCacheProvider() => _instance;
  StatsCacheProvider._();

  final StatsCache cache = StatsCache();

  /// Initialize cache (call once during app startup).
  void init() {
    cache.init();
    debugPrint('[StatsCacheProvider] Initialized');
  }

  /// Dispose (for testing).
  void dispose() {
    cache.dispose();
  }
}
