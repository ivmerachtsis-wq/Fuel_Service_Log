import 'package:collection/collection.dart';
import '../data/models/fuel_entry.dart';
import '../data/models/service_entry.dart';

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

// --- Extra KPI extension ---
/// Additional KPI bundle for direct window calculations.
class ExtraKpi {
  final double costPerKm;       // €/km
  final double litersPer100km;  // L/100km
  const ExtraKpi({required this.costPerKm, required this.litersPer100km});
}

/// Computes extra KPIs given raw fuel & service entries inside [from,to] window.
/// Each fuel entry must expose: date(DateTime), liters(num), amount(num).
/// Each service entry must expose: date(DateTime), totalAmount(num).
ExtraKpi computeExtraKpi({
  required Iterable<dynamic> fuelEntries,
  required Iterable<dynamic> serviceEntries,
  required DateTime from,
  required DateTime to,
  required double distanceKmInWindow,
}) {
  double fuelLiters = 0.0;
  double totalCost = 0.0;
  bool inRange(DateTime d) => !d.isBefore(from) && !d.isAfter(to);

  for (final e in fuelEntries) {
    final d = e.date as DateTime;
    if (!inRange(d)) continue;
    fuelLiters += (e.liters as num).toDouble();
    totalCost += (e.amount as num).toDouble();
  }
  for (final s in serviceEntries) {
    final d = s.date as DateTime;
    if (!inRange(d)) continue;
    totalCost += (s.totalAmount as num).toDouble();
  }

  final costPerKm = distanceKmInWindow > 0 ? totalCost / distanceKmInWindow : 0.0;
  final litersPer100km = distanceKmInWindow > 0 ? (fuelLiters / distanceKmInWindow) * 100.0 : 0.0;

  return ExtraKpi(costPerKm: costPerKm, litersPer100km: litersPer100km);
}

// === Day 10 additions: unified monthly series + distance fallback ===

class MonthlyBucket {
  final DateTime month; // normalized (year, month, 1)
  final double fuelAmount;
  final double serviceAmount;
  final double liters;

  const MonthlyBucket({
    required this.month,
    required this.fuelAmount,
    required this.serviceAmount,
    required this.liters,
  });
}

List<MonthlyBucket> seriesFromTotals({
  required List<FuelEntry> fuel,
  required List<ServiceEntry> service,
}) {
  DateTime norm(DateTime d) => DateTime(d.year, d.month, 1);
  String key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  final map = <String, MonthlyBucket>{};

  for (final f in fuel) {
    final m = norm(f.date);
    final k = key(m);
    final cur = map[k];
    map[k] = MonthlyBucket(
      month: m,
      fuelAmount: (cur?.fuelAmount ?? 0) + f.amount,
      serviceAmount: cur?.serviceAmount ?? 0,
      liters: (cur?.liters ?? 0) + f.liters,
    );
  }

  for (final s in service) {
    final m = norm(s.date);
    final k = key(m);
    final cur = map[k];
    map[k] = MonthlyBucket(
      month: m,
      fuelAmount: cur?.fuelAmount ?? 0,
      serviceAmount: (cur?.serviceAmount ?? 0) + s.totalAmount,
      liters: cur?.liters ?? 0,
    );
  }

  final out = map.values.toList()
    ..sort((a, b) => a.month.compareTo(b.month));
  return out;
}

/// Compute distance (km) preferring fuel odometer span; fallback to service span; else 0.
double computeDistanceKm({
  required List<FuelEntry> fuel,
  required List<ServiceEntry> service,
}) {
  double span(List<double> xs) {
    if (xs.isEmpty) return 0;
    double minX = xs.first, maxX = xs.first;
    for (final v in xs) {
      if (v < minX) minX = v;
      if (v > maxX) maxX = v;
    }
    return (maxX - minX).abs();
  }

  // 1) Try fuel entries (robust to order; allows >=1 entry; span can be 0)
  if (fuel.isNotEmpty) {
    final d = span(fuel.map((e) => e.odometerKm).toList());
    if (d > 0 || fuel.length >= 2) return d;
  }

  // 2) Fallback via service entries
  if (service.isNotEmpty) {
    final d = span(service.map((e) => e.odometerKm).toList());
    if (d > 0) return d;
  }

  // 3) Nothing usable
  return 0;
}
// === End of Day 10 additions ===
