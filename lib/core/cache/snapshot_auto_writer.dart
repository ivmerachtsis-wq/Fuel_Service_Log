import 'dart:async';
import 'package:flutter/foundation.dart';
import 'cached_services.dart';
import 'snapshot_store.dart';
import 'cache_invalidator.dart';

/// Observes cache mutation events and triggers debounced snapshot writes.
class SnapshotAutoWriter {
  final SnapshotStore _store;
  final CachedServices _services;
  final int _schemaVersion;
  final String _appVersion;

  Timer? _debounce;
  StreamSubscription? _sub;

  SnapshotAutoWriter(this._store, this._services,
      {int schemaVersion = 1, String appVersion = '1.1.0'})
      : _schemaVersion = schemaVersion,
        _appVersion = appVersion;

  void start() {
    _sub?.cancel();
    _sub = CacheInvalidator().events.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), () {
        final state = _services.toCachedState(_schemaVersion, _appVersion);
        _store.debouncedWriteState(state);
        debugPrint('[SnapshotAutoWriter] scheduled debounced write');
      });
    });
  }

  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
  }
}
