import '../data/models/fuel_entry.dart';

/// Service για υπολογισμό στατιστικών καυσίμου
class StatsService {
  /// Υπολογίζει full-to-full κατανάλωση (L/100km) από λίστα FuelEntry με φίλτρα.
  /// Τα φίλτρα εφαρμόζονται πριν την ανάλυση (ημερομηνίες, driverId).
  List<ConsumptionPoint> getFullToFullConsumptions(
    List<FuelEntry> entries, {
    DateTime? from,
    DateTime? to,
    String? driverId,
  }) {
    if (entries.isEmpty) return [];

    final filtered = entries.where((e) {
      final afterFrom = from == null || !e.date.isBefore(from);
      final beforeTo = to == null || !e.date.isAfter(to);
      final driverOk = driverId == null || driverId.isEmpty || e.driverId == driverId;
      return afterFrom && beforeTo && driverOk;
    }).toList();

    if (filtered.isEmpty) return [];

    // Ταξινόμηση κατά ημερομηνία
    final sorted = [...filtered]..sort((a, b) => a.date.compareTo(b.date));

    final result = <ConsumptionPoint>[];
    int? startIdx;

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].fullTank) {
        if (startIdx != null) {
          final start = sorted[startIdx];
          final end = sorted[i];
          final km = end.odometerKm - start.odometerKm;

          if (km > 0) {
            double totalLiters = 0;
            for (int j = startIdx + 1; j <= i; j++) {
              totalLiters += sorted[j].liters;
            }
            if (totalLiters > 0) {
              final consumption = (totalLiters / km) * 100;
              result.add(ConsumptionPoint(
                date: end.date,
                litersPer100Km: double.parse(consumption.toStringAsFixed(2)),
              ));
            }
          }
        }
        startIdx = i;
      }
    }
    return result;
  }

  /// Υπολογίζει μηνιαίο κόστος με φίλτρα (months, driverId και date window).
  List<MonthlyCost> getMonthlyCost(
    List<FuelEntry> entries, {
    int months = 6,
    String? driverId,
    DateTime? from,
    DateTime? to,
  }) {
    if (entries.isEmpty) return [];

    final now = DateTime.now();
    final filtered = entries.where((e) {
      final afterFrom = from == null || !e.date.isBefore(from);
      final beforeTo = to == null || !e.date.isAfter(to);
      final driverOk = driverId == null || driverId.isEmpty || e.driverId == driverId;
      return afterFrom && beforeTo && driverOk;
    }).toList();

    if (filtered.isEmpty) return [];

    final monthMap = <String, double>{};
    for (final entry in filtered) {
      final key = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      monthMap[key] = (monthMap[key] ?? 0) + entry.amount;
    }

    final result = <MonthlyCost>[];
    for (int i = months - 1; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final key = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}';
      result.add(MonthlyCost(yearMonth: key, amount: monthMap[key] ?? 0));
    }
    return result;
  }

  double getAverageConsumption(List<ConsumptionPoint> points) {
    if (points.isEmpty) return 0;
    final sum = points.fold<double>(0, (sum, p) => sum + p.litersPer100Km);
    return double.parse((sum / points.length).toStringAsFixed(2));
  }

  double getAverageMonthlyCost(List<MonthlyCost> costs) {
    if (costs.isEmpty) return 0;
    final valid = costs.where((c) => c.amount > 0).toList();
    if (valid.isEmpty) return 0;
    final sum = valid.fold<double>(0, (sum, c) => sum + c.amount);
    return double.parse((sum / valid.length).toStringAsFixed(2));
  }
}

class ConsumptionPoint {
  final DateTime date;
  final double litersPer100Km;
  ConsumptionPoint({required this.date, required this.litersPer100Km});
}

class MonthlyCost {
  final String yearMonth;
  final double amount;
  MonthlyCost({required this.yearMonth, required this.amount});
}
