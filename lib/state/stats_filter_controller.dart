import 'package:flutter/foundation.dart';
import '../services/ui_prefs_service.dart';
import 'stats_filter.dart';
import 'stats_metric.dart';

/// Controller for stats filter and metric selection with persistence
class StatsFilterController extends ChangeNotifier {
  final UiPrefs _prefs;
  
  StatsFilter _filter;
  StatsMetric _metric;

  StatsFilterController(this._prefs)
      : _filter = StatsFilter.ytd(),
        _metric = StatsMetric.cost;

  /// Current filter
  StatsFilter get filter => _filter;

  /// Current metric
  StatsMetric get metric => _metric;

  /// Load saved preferences (call once during initialization)
  void load() {
    _filter = _prefs.loadStatsFilter();
    _metric = _prefs.loadStatsMetric();
    notifyListeners();
  }

  /// Set filter and persist
  Future<void> setFilter(StatsFilter filter) async {
    if (_filter != filter) {
      _filter = filter;
      notifyListeners();
      await _prefs.saveStatsFilter(filter);
    }
  }

  /// Set metric and persist
  Future<void> setMetric(StatsMetric metric) async {
    if (_metric != metric) {
      _metric = metric;
      notifyListeners();
      await _prefs.saveStatsMetric(metric);
    }
  }
}
