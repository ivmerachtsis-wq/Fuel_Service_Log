import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/domain/stats_aggregator.dart';

class _Fuel {
  final DateTime date; final double liters; final double amount; final double odometerKm;
  _Fuel(this.date, this.liters, this.amount, this.odometerKm);
}
class _Service {
  final DateTime date; final double totalAmount; final double odometerKm;
  _Service(this.date, this.totalAmount, this.odometerKm);
}

void main() {
  test('computeExtraKpi returns €/km and L/100km for the window', () {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 60));
    final to = now;

    // 1500 km στο παράθυρο
    final fuel = [
      _Fuel(from.add(const Duration(days: 1)), 30, 50, 10000),
      _Fuel(from.add(const Duration(days: 20)), 35, 60, 10300),
      _Fuel(from.add(const Duration(days: 45)), 36, 62, 11500),
    ];
    final svc = [
      _Service(from.add(const Duration(days: 10)), 120, 10100),
    ];
    final distanceKm = 1500.0;

    final x = computeExtraKpi(
      fuelEntries: fuel,
      serviceEntries: svc,
      from: from, to: to,
      distanceKmInWindow: distanceKm,
    );

    expect(x.costPerKm > 0, true);
    expect(x.litersPer100km > 0, true);
    // Προσεγγιστικοί έλεγχοι τάξης μεγέθους:
    // Συνολικό κόστος ≈ 50+60+62+120 = 292€ → €/km ≈ 0.194
    expect(x.costPerKm, closeTo(292/1500, 0.05));
    // Λίτρα = 30+35+36=101 → 101/1500*100 ≈ 6.73 L/100km
    expect(x.litersPer100km, closeTo((101/1500)*100, 0.5));
  });
}
