import 'dart:async';
import 'cache_event.dart';

/// Global cache invalidation coordinator.
/// 
/// Emits cache events for cross-layer synchronization (L1 ↔ L2, Stats invalidation).
class CacheInvalidator {
  static final CacheInvalidator _instance = CacheInvalidator._();
  factory CacheInvalidator() => _instance;
  CacheInvalidator._();

  final _controller = StreamController<CacheEvent>.broadcast();

  /// Stream of all cache invalidation events.
  Stream<CacheEvent> get events => _controller.stream;

  /// Emit a cache event to notify listeners of data changes.
  void emit(String boxName, {dynamic key, String? vehicleId}) {
    if (!_controller.isClosed) {
      _controller.add(CacheEvent.changed(boxName, key, vehicleId: vehicleId));
    }
  }

  /// Emit deletion event.
  void emitDeleted(String boxName, dynamic key, {String? vehicleId}) {
    if (!_controller.isClosed) {
      _controller.add(CacheEvent.deleted(boxName, key, vehicleId: vehicleId));
    }
  }

  /// Emit box cleared event.
  void emitCleared(String boxName) {
    if (!_controller.isClosed) {
      _controller.add(CacheEvent.cleared(boxName));
    }
  }

  /// Dispose (only for testing; singleton normally lives for app lifetime).
  void dispose() {
    _controller.close();
  }
}
