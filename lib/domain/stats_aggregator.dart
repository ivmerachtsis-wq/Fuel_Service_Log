import 'package:collection/collection.dart';

/// A key for grouping entries by month.
class MonthKey implements Comparable<MonthKey> {
  final int year;
  final int month;

  const MonthKey(this.year, this.month);

  factory MonthKey.fromDate(DateTime date) => MonthKey(date.year, date.month);

  @override
  int compareTo(MonthKey other) {
    final yearCmp = year.compareTo(other.year);
    if (yearCmp != 0) return yearCmp;
    return month.compareTo(other.month);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthKey &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// Monthly totals for aggregated statistics.
class MonthlyTotals {
  final MonthKey month;
  final double totalLiters;
  final double totalCost;
  final double totalDistance; // km driven in this month

  const MonthlyTotals({
    required this.month,
    required this.totalLiters,
    required this.totalCost,
    required this.totalDistance,
  });

  /// Cost per kilometer for this month (safe division).
  double get costPerKm => totalDistance > 0 ? totalCost / totalDistance : 0.0;

  /// Average consumption in liters per 100 km.
  double get avgConsumptionL100km =>
      totalDistance > 0 ? (totalLiters / totalDistance) * 100 : 0.0;
}

/// Aggregates a list of entries (fuel + service) by month.
/// Each entry must have: date, liters?, cost, odometer.
/// Returns a sorted list of [MonthlyTotals].
List<MonthlyTotals> aggregateMonthly(List<dynamic> entries) {
  // Group by month
  final grouped = groupBy<dynamic, MonthKey>(
    entries,
    (e) => MonthKey.fromDate(e.date as DateTime),
  );

  // For each month, compute totals
  final results = <MonthlyTotals>[];
  for (final entry in grouped.entries) {
    final monthKey = entry.key;
    final items = entry.value;

    double totalLiters = 0;
    double totalCost = 0;
    double totalDistance = 0;

    // Sort items by odometer to compute distances
    final sorted = items.sortedBy<num>((e) => e.odometer as num);

    for (int i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      totalLiters += (item.liters as double?) ?? 0.0;
      totalCost += item.cost as double;

      // Distance = odometer difference from previous entry
      if (i > 0) {
        final prev = sorted[i - 1];
        final dist = distanceFromOdometer(item.odometer, prev.odometer);
        totalDistance += dist;
      }
    }

    results.add(MonthlyTotals(
      month: monthKey,
      totalLiters: totalLiters,
      totalCost: totalCost,
      totalDistance: totalDistance,
    ));
  }

  // Sort by month (chronological)
  results.sort((a, b) => a.month.compareTo(b.month));
  return results;
}

/// Computes high-level KPIs from monthly totals.
/// Returns: {costPerKm, avgConsumptionL100km, avgMonthlyCost}.
Map<String, double> computeKpis(List<MonthlyTotals> monthlyData) {
  if (monthlyData.isEmpty) {
    return {'costPerKm': 0, 'avgConsumptionL100km': 0, 'avgMonthlyCost': 0};
  }

  double totalCost = 0;
  double totalDistance = 0;
  double totalLiters = 0;

  for (final m in monthlyData) {
    totalCost += m.totalCost;
    totalDistance += m.totalDistance;
    totalLiters += m.totalLiters;
  }

  final costPerKm = totalDistance > 0 ? totalCost / totalDistance : 0.0;
  final avgConsumptionL100km =
      totalDistance > 0 ? (totalLiters / totalDistance) * 100 : 0.0;
  final avgMonthlyCost = totalCost / monthlyData.length;

  return {
    'costPerKm': costPerKm,
    'avgConsumptionL100km': avgConsumptionL100km,
    'avgMonthlyCost': avgMonthlyCost,
  };
}

/// Safe odometer distance calculation.
double distanceFromOdometer(dynamic current, dynamic previous) {
  final curr = (current as num?)?.toDouble() ?? 0.0;
  final prev = (previous as num?)?.toDouble() ?? 0.0;
  return (curr - prev).abs();
}
