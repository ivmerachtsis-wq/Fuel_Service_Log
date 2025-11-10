import 'package:flutter/foundation.dart';

enum StatsPreset { last30, last90, last180, ytd, all, custom }

@immutable
class StatsFilter {
  final StatsPreset preset;
  final DateTime? from;
  final DateTime? to;

  const StatsFilter._(this.preset, this.from, this.to);

  const StatsFilter.all() : this._(StatsPreset.all, null, null);
  factory StatsFilter.last30() {
    final now = DateTime.now();
    return StatsFilter._(StatsPreset.last30, now.subtract(const Duration(days: 30)), now);
  }
  factory StatsFilter.last90() {
    final now = DateTime.now();
    return StatsFilter._(StatsPreset.last90, now.subtract(const Duration(days: 90)), now);
  }
  factory StatsFilter.last180() {
    final now = DateTime.now();
    return StatsFilter._(StatsPreset.last180, now.subtract(const Duration(days: 180)), now);
  }
  factory StatsFilter.ytd() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    return StatsFilter._(StatsPreset.ytd, start, now);
  }

  factory StatsFilter.custom(DateTime from, DateTime to) {
    if (from.isAfter(to)) {
      return StatsFilter._(StatsPreset.custom, to, from);
    }
    return StatsFilter._(StatsPreset.custom, from, to);
  }

  bool includes(DateTime d) {
    if (from == null || to == null) return true;
    return !d.isBefore(from!) && !d.isAfter(to!);
  }
}
