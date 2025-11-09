import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_event.dart';
import 'cache_invalidator.dart';

/// L1 in-memory cache wrapper for a Hive `Box<T>`.
/// 
/// Maintains a synchronized `Map<dynamic, T>` for instant reads and emits
/// CacheEvents for downstream invalidation (L2 snapshot, Stats memoization).
class CachedBoxService<T> {
  final Box<T> _box;
  final String boxName;
  final Map<dynamic, T> _mem = {};
  final CacheInvalidator _invalidator = CacheInvalidator();

  /// Revision counter for UI rebuilds via ValueListenableBuilder.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  StreamSubscription? _boxWatchSubscription;

  CachedBoxService(this._box, this.boxName);

  /// Initialize (or re-initialize) cache: optionally hydrate from preloaded state (L2 snapshot).
  /// Safe to call multiple times; cancels previous watcher and clears memory before hydration.
  Future<void> init({Map<dynamic, T>? preload}) async {
    // Cancel existing subscription (if any) to avoid multiple listeners.
    await _boxWatchSubscription?.cancel();
    _boxWatchSubscription = null;
    _mem.clear();

    if (preload != null) {
      _mem.addAll(preload);
    } else {
      for (final key in _box.keys) {
        final value = _box.get(key);
        if (value != null) {
          _mem[key] = value;
        }
      }
    }
    revision.value++;

    _boxWatchSubscription = _box.watch().listen((event) {
      if (event.deleted) {
        _mem.remove(event.key);
        _invalidator.emitDeleted(boxName, event.key);
      } else {
        final value = _box.get(event.key);
        if (value != null) {
          _mem[event.key] = value;
          _invalidator.emit(boxName, key: event.key);
        }
      }
      revision.value++;
    });
  }

  /// Get all cached items (instant read from RAM).
  List<T> getAll() => _mem.values.toList();

  /// Get single item by key (instant read from RAM).
  T? get(dynamic key) => _mem[key];

  /// Put item (write to Hive + update RAM + emit event).
  Future<void> put(dynamic key, T value) async {
    await _box.put(key, value);
    _mem[key] = value;
    _invalidator.emit(boxName, key: key);
    revision.value++;
  }

  /// Delete item (remove from Hive + RAM + emit event).
  Future<void> delete(dynamic key) async {
    await _box.delete(key);
    _mem.remove(key);
    _invalidator.emitDeleted(boxName, key);
    revision.value++;
  }

  /// Stream of cache invalidation events.
  Stream<CacheEvent> watch() => _invalidator.events.where((e) => e.boxName == boxName);

  /// Dispose subscriptions.
  void dispose() {
    _boxWatchSubscription?.cancel();
    revision.dispose();
  }
}
