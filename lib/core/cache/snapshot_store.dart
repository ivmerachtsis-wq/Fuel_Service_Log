import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'models/cached_state.dart';

/// L2 persistent JSON snapshot for fast cold-start hydration.
/// 
/// Reads/writes a versioned JSON file with debounced updates (1s after bursts).
/// Validates schema version and checksums; gracefully falls back to Hive on mismatch.
class SnapshotStore {
  static const int _currentSchemaVersion = 1;
  static const String _snapshotFileName = 'cache_snapshot.json';
  
  Timer? _debounce;
  bool _enabled = true;

  /// Read snapshot if valid; returns null if missing/invalid/disabled.
  /// 
  /// Validates schemaVersion match. Checksum validation deferred to caller
  /// (after Hive data is loaded for comparison).
  Future<CachedState?> readIfValid() async {
    if (!_enabled) return null;

    try {
      final file = await _getSnapshotFile();
      if (!await file.exists()) {
        debugPrint('[SnapshotStore] No snapshot file found');
        return null;
      }

      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final state = CachedState.fromJson(json);

      if (state.schemaVersion != _currentSchemaVersion) {
        debugPrint('[SnapshotStore] Schema mismatch: ${state.schemaVersion} != $_currentSchemaVersion');
        return null;
      }

      debugPrint('[SnapshotStore] Snapshot loaded: ${state.generatedAt}, ${state.boxes.length} boxes');
      return state;
    } catch (e, st) {
      debugPrint('[SnapshotStore] Read failed: $e\n$st');
      return null;
    }
  }

  /// Write snapshot with debounce (1s after last call).
  /// 
  /// [boxes] should be a map of boxName → list of items (already serialized to JSON).
  void write(Map<String, List<Map<String, dynamic>>> boxes) {
    if (!_enabled) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () async {
      await _writeNow(boxes);
    });
  }

  /// Immediate write (used on app background/dispose).
  Future<void> writeNow(Map<String, List<Map<String, dynamic>>> boxes) async {
    if (!_enabled) return;
    _debounce?.cancel();
    await _writeNow(boxes);
  }

  Future<void> _writeNow(Map<String, List<Map<String, dynamic>>> boxes) async {
    try {
      final boxSnapshots = <String, BoxSnapshot>{};
      for (final entry in boxes.entries) {
        final items = entry.value;
        final checksum = _computeChecksum(items);
        boxSnapshots[entry.key] = BoxSnapshot(
          revision: 0, // TODO: wire actual revision from CachedBoxService
          checksum: checksum,
          items: items,
        );
      }

      final state = CachedState(
        schemaVersion: _currentSchemaVersion,
        generatedAt: DateTime.now(),
        appVersion: '1.1.0', // TODO: wire from package_info
        boxes: boxSnapshots,
      );

      final file = await _getSnapshotFile();
      final jsonStr = jsonEncode(state.toJson());
      await file.writeAsString(jsonStr);

      debugPrint('[SnapshotStore] Snapshot written: ${state.boxes.length} boxes');
    } catch (e, st) {
      debugPrint('[SnapshotStore] Write failed: $e\n$st');
    }
  }

  /// Compute fast checksum for a list of items.
  /// 
  /// Uses MD5 over stable JSON (sorted keys to ensure determinism).
  String _computeChecksum(List<Map<String, dynamic>> items) {
    // Sort items by a stable key (e.g., 'id' if present) for determinism
    final sortedItems = items.map((item) {
      final sortedKeys = item.keys.toList()..sort();
      return {for (var k in sortedKeys) k: item[k]};
    }).toList();

    final stableJson = jsonEncode(sortedItems);
    final bytes = utf8.encode(stableJson);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<File> _getSnapshotFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_snapshotFileName');
  }

  /// Enable/disable snapshot caching (Settings toggle).
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _debounce?.cancel();
    }
  }

  /// Dispose timer on app shutdown.
  void dispose() {
    _debounce?.cancel();
  }
}
