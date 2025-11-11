import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../state/stats_filter.dart';
import '../state/stats_metric.dart';

/// Abstract interface for UI preferences persistence
abstract class UiPrefs {
  StatsFilter loadStatsFilter();
  StatsMetric loadStatsMetric();
  Future<void> saveStatsFilter(StatsFilter filter);
  Future<void> saveStatsMetric(StatsMetric metric);
  
  bool loadAskWhereToSave();
  Future<void> saveAskWhereToSave(bool value);
}

/// In-memory implementation for tests (no IO)
class UiPrefsMemory implements UiPrefs {
  @visibleForTesting
  final Map<String, dynamic> storage = {};
  
  @override
  StatsFilter loadStatsFilter() {
    final presetStr = storage['stats.filter.preset'] as String?;
    if (presetStr == null) {
      return StatsFilter.ytd();
    }
    
    final preset = _parseStatsPreset(presetStr);
    if (preset == null) {
      return StatsFilter.ytd();
    }
    
    if (preset == StatsPreset.custom) {
      final fromMs = storage['stats.filter.from'] as int?;
      final toMs = storage['stats.filter.to'] as int?;
      if (fromMs != null && toMs != null) {
        final from = DateTime.fromMillisecondsSinceEpoch(fromMs);
        final to = DateTime.fromMillisecondsSinceEpoch(toMs);
        return StatsFilter.custom(from, to);
      }
      return StatsFilter.ytd();
    }
    
    switch (preset) {
      case StatsPreset.last30:
        return StatsFilter.last30();
      case StatsPreset.last90:
        return StatsFilter.last90();
      case StatsPreset.last180:
        return StatsFilter.last180();
      case StatsPreset.ytd:
        return StatsFilter.ytd();
      case StatsPreset.all:
        return const StatsFilter.all();
      case StatsPreset.custom:
        return StatsFilter.ytd();
    }
  }
  
  @override
  StatsMetric loadStatsMetric() {
    final metricStr = storage['stats.metric'] as String?;
    if (metricStr == null) {
      return StatsMetric.cost;
    }
    return _parseStatsMetric(metricStr) ?? StatsMetric.cost;
  }
  
  @override
  Future<void> saveStatsFilter(StatsFilter filter) async {
    storage['stats.filter.preset'] = filter.preset.name;
    if (filter.preset == StatsPreset.custom) {
      if (filter.from != null && filter.to != null) {
        storage['stats.filter.from'] = filter.from!.millisecondsSinceEpoch;
        storage['stats.filter.to'] = filter.to!.millisecondsSinceEpoch;
      }
    } else {
      storage.remove('stats.filter.from');
      storage.remove('stats.filter.to');
    }
  }
  
  @override
  Future<void> saveStatsMetric(StatsMetric metric) async {
    storage['stats.metric'] = metric.name;
  }
  
  @override
  bool loadAskWhereToSave() {
    return storage['settings.askWhereToSave'] as bool? ?? false;
  }
  
  @override
  Future<void> saveAskWhereToSave(bool value) async {
    storage['settings.askWhereToSave'] = value;
  }
  
  StatsPreset? _parseStatsPreset(String str) {
    try {
      return StatsPreset.values.firstWhere((e) => e.name == str);
    } catch (_) {
      return null;
    }
  }
  
  StatsMetric? _parseStatsMetric(String str) {
    try {
      return StatsMetric.values.firstWhere((e) => e.name == str);
    } catch (_) {
      return null;
    }
  }
}

/// Hive-based implementation for production
class UiPrefsService implements UiPrefs {
  static const String _boxName = 'ui_prefs';
  static const String _statsFilterPresetKey = 'stats.filter.preset';
  static const String _statsFilterFromKey = 'stats.filter.from';
  static const String _statsFilterToKey = 'stats.filter.to';
  static const String _statsMetricKey = 'stats.metric';
  static const String _askWhereToSaveKey = 'settings.askWhereToSave';

  Box get _box => Hive.box(_boxName);

  @override
  StatsFilter loadStatsFilter() {
    final presetStr = _box.get(_statsFilterPresetKey) as String?;
    if (presetStr == null) {
      return StatsFilter.ytd();
    }

    final preset = _parseStatsPreset(presetStr);
    if (preset == null) {
      return StatsFilter.ytd();
    }

    // For custom preset, load the date range
    if (preset == StatsPreset.custom) {
      final fromMs = _box.get(_statsFilterFromKey) as int?;
      final toMs = _box.get(_statsFilterToKey) as int?;
      if (fromMs != null && toMs != null) {
        final from = DateTime.fromMillisecondsSinceEpoch(fromMs);
        final to = DateTime.fromMillisecondsSinceEpoch(toMs);
        return StatsFilter.custom(from, to);
      }
      // Fallback if custom dates missing
      return StatsFilter.ytd();
    }

    // Use factory constructor for standard presets
    switch (preset) {
      case StatsPreset.last30:
        return StatsFilter.last30();
      case StatsPreset.last90:
        return StatsFilter.last90();
      case StatsPreset.last180:
        return StatsFilter.last180();
      case StatsPreset.ytd:
        return StatsFilter.ytd();
      case StatsPreset.all:
        return const StatsFilter.all();
      case StatsPreset.custom:
        return StatsFilter.ytd(); // Should not reach here
    }
  }

  @override
  Future<void> saveStatsFilter(StatsFilter filter) async {
    await _box.put(_statsFilterPresetKey, filter.preset.name);
    if (filter.preset == StatsPreset.custom) {
      if (filter.from != null && filter.to != null) {
        await _box.put(_statsFilterFromKey, filter.from!.millisecondsSinceEpoch);
        await _box.put(_statsFilterToKey, filter.to!.millisecondsSinceEpoch);
      }
    } else {
      // Clear custom dates when switching to standard presets
      await _box.delete(_statsFilterFromKey);
      await _box.delete(_statsFilterToKey);
    }
  }

  @override
  StatsMetric loadStatsMetric() {
    final metricStr = _box.get(_statsMetricKey) as String?;
    if (metricStr == null) {
      return StatsMetric.cost;
    }
    return _parseStatsMetric(metricStr) ?? StatsMetric.cost;
  }

  @override
  Future<void> saveStatsMetric(StatsMetric metric) async {
    await _box.put(_statsMetricKey, metric.name);
  }
  
  @override
  bool loadAskWhereToSave() {
    return _box.get(_askWhereToSaveKey) as bool? ?? false;
  }
  
  @override
  Future<void> saveAskWhereToSave(bool value) async {
    await _box.put(_askWhereToSaveKey, value);
  }

  /// Parse StatsPreset from string
  StatsPreset? _parseStatsPreset(String str) {
    try {
      return StatsPreset.values.firstWhere((e) => e.name == str);
    } catch (_) {
      return null;
    }
  }

  /// Parse StatsMetric from string
  StatsMetric? _parseStatsMetric(String str) {
    try {
      return StatsMetric.values.firstWhere((e) => e.name == str);
    } catch (_) {
      return null;
    }
  }
}
