import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/fuel_entry.dart';
import '../../data/models/service_entry.dart';
import '../../domain/stats_service.dart';

/// Απλός controller για τα KPIs των στατιστικών.
/// Δεν τροποποιεί δεδομένα, μόνο διαβάζει τα Hive boxes και κάνει aggregation.
class StatsController {
  final _statsService = StatsService();

  /// Μέση κατανάλωση (L/100km) υπολογισμένη από full-to-full σημεία.
  double averageConsumptionForVehicle(String vehicleId) {
    final box = Hive.box<FuelEntry>('fuel_entries');
    final entries = box.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final points = _statsService.getFullToFullConsumptions(entries);
    return _statsService.getAverageConsumption(points);
  }

  /// Κόστος ανά μήνα (Fuel + Service) συγκεντρωτικό map YYYY-MM -> amount.
  Map<String, double> costPerMonth(String vehicleId, {int months = 6}) {
    final fuelBox = Hive.box<FuelEntry>('fuel_entries');
    final serviceBox = Hive.box<ServiceEntry>('service_entries');
    final fuelEntries = fuelBox.values.where((e) => e.vehicleId == vehicleId).toList();
    // Fuel costs via StatsService monthly cost.
    final fuelMonthly = _statsService.getMonthlyCost(fuelEntries, months: months);
    final serviceEntries = serviceBox.values.where((e) => e.vehicleId == vehicleId).toList();

    // Υπολογισμός service ποσών ανά μήνα
    final serviceMonthMap = <String, double>{};
    for (final s in serviceEntries) {
      final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
      serviceMonthMap[key] = (serviceMonthMap[key] ?? 0) + s.totalAmount;
    }

    final out = <String, double>{};
    for (final mc in fuelMonthly) {
      out[mc.yearMonth] = (out[mc.yearMonth] ?? 0) + mc.amount + (serviceMonthMap[mc.yearMonth] ?? 0);
    }
    return out;
  }

  /// Συχνότητα service σε ημέρες κατά μέσο όρο μεταξύ service καταχωρήσεων.
  double averageServiceFrequencyDays(String vehicleId) {
    final serviceBox = Hive.box<ServiceEntry>('service_entries');
    final items = serviceBox.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (items.length < 2) return 0;
    double totalDays = 0;
    int intervals = 0;
    for (int i = 1; i < items.length; i++) {
      final diff = items[i].date.difference(items[i - 1].date).inDays;
      if (diff > 0) {
        totalDays += diff;
        intervals++;
      }
    }
    if (intervals == 0) return 0;
    return double.parse((totalDays / intervals).toStringAsFixed(1));
  }
}
