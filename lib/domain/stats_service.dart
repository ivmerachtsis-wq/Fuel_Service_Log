import '../data/models/fuel_entry.dart';

/// Service για υπολογισμό στατιστικών καυσίμου
class StatsService {
  /// Υπολογίζει full-to-full κατανάλωση (L/100km) από λίστα FuelEntry
  /// 
  /// Επιστρέφει λίστα από (date, L/100km) για κάθε έγκυρο εύρος μεταξύ 
  /// διαδοχικών fullTank entries.
  /// 
  /// Αγνοεί εύρη με km <= 0 ή χωρίς ενδιάμεσα λίτρα.
  List<ConsumptionPoint> getFullToFullConsumptions(List<FuelEntry> entries) {
    if (entries.isEmpty) return [];

    // Ταξινόμηση κατά ημερομηνία
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));

    final result = <ConsumptionPoint>[];
    int? startIdx;

    for (int i = 0; i < sorted.length; i++) {
      if (sorted[i].fullTank) {
        if (startIdx != null) {
          // Υπολογισμός εύρους από startIdx έως i
          final start = sorted[startIdx];
          final end = sorted[i];
          final km = end.odometerKm - start.odometerKm;

          if (km > 0) {
            // Άθροισμα λίτρων από startIdx (exclusive) μέχρι i (inclusive)
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

  /// Υπολογίζει μηνιαίο κόστος για τους τελευταίους N μήνες
  /// 
  /// Επιστρέφει λίστα από (year-month, totalAmount) ομαδοποιημένα κατά μήνα.
  /// Συμπληρώνει με 0 τους μήνες χωρίς δεδομένα.
  List<MonthlyCost> getMonthlyCost(List<FuelEntry> entries, {int months = 6}) {
    if (entries.isEmpty) return [];

    final now = DateTime.now();
    final monthMap = <String, double>{};

    // Ομαδοποίηση κατά έτος-μήνα
    for (final entry in entries) {
      final key = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}';
      monthMap[key] = (monthMap[key] ?? 0) + entry.amount;
    }

    // Δημιουργία λίστας για τους τελευταίους N μήνες
    final result = <MonthlyCost>[];
    for (int i = months - 1; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final key = '${targetMonth.year}-${targetMonth.month.toString().padLeft(2, '0')}';
      result.add(MonthlyCost(
        yearMonth: key,
        amount: monthMap[key] ?? 0,
      ));
    }

    return result;
  }

  /// Υπολογίζει μέσο όρο κατανάλωσης από λίστα ConsumptionPoint
  double getAverageConsumption(List<ConsumptionPoint> points) {
    if (points.isEmpty) return 0;
    final sum = points.fold<double>(0, (sum, p) => sum + p.litersPer100Km);
    return double.parse((sum / points.length).toStringAsFixed(2));
  }

  /// Υπολογίζει μέσο μηνιαίο κόστος από λίστα MonthlyCost
  double getAverageMonthlyCost(List<MonthlyCost> costs) {
    if (costs.isEmpty) return 0;
    final validCosts = costs.where((c) => c.amount > 0).toList();
    if (validCosts.isEmpty) return 0;
    final sum = validCosts.fold<double>(0, (sum, c) => sum + c.amount);
    return double.parse((sum / validCosts.length).toStringAsFixed(2));
  }
}

/// Δεδομένα σημείου κατανάλωσης
class ConsumptionPoint {
  final DateTime date;
  final double litersPer100Km;

  ConsumptionPoint({required this.date, required this.litersPer100Km});
}

/// Δεδομένα μηνιαίου κόστους
class MonthlyCost {
  final String yearMonth;
  final double amount;

  MonthlyCost({required this.yearMonth, required this.amount});
}
