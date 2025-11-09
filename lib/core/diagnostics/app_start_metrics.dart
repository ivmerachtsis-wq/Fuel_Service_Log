import 'package:flutter/foundation.dart';

/// App startup performance telemetry.
/// 
/// Tracks key milestones:
/// - t0: main() entry
/// - t1: Snapshot hydrated (L1 RAM ready)
/// - t2: Hive boxes opened + validated (full ready)
class AppStartMetrics {
  static final Stopwatch _sw = Stopwatch()..start();
  
  static Duration? _t0;
  static Duration? _t1;
  static Duration? _t2;

  static Duration? get t0 => _t0;
  static Duration? get t1 => _t1;
  static Duration? get t2 => _t2;

  /// Mark t0: main() entry point.
  static void markT0() {
    _t0 = _sw.elapsed;
    debugPrint('[AppStartMetrics] t0: ${_t0!.inMilliseconds}ms (main entry)');
  }

  /// Mark t1: Snapshot hydrated, L1 cache ready.
  static void markT1() {
    _t1 = _sw.elapsed;
    debugPrint('[AppStartMetrics] t1: ${_t1!.inMilliseconds}ms (snapshot hydrated)');
  }

  /// Mark t2: Hive boxes opened + validated, full ready.
  static void markT2() {
    _t2 = _sw.elapsed;
    debugPrint('[AppStartMetrics] t2: ${_t2!.inMilliseconds}ms (hive ready)');
  }

  /// Summary for logging.
  static String summary() {
    final t0ms = _t0?.inMilliseconds ?? 0;
    final t1ms = _t1?.inMilliseconds ?? 0;
    final t2ms = _t2?.inMilliseconds ?? 0;
    return 't0=${t0ms}ms, t1=${t1ms}ms (delta: ${t1ms - t0ms}ms), t2=${t2ms}ms (delta: ${t2ms - t1ms}ms)';
  }
}
