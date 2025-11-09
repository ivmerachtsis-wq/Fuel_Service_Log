import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/domain/stats_aggregator.dart';

// Mock classes for testing
class _Fuel {
  final DateTime date;
  final double liters;
  final double cost;
  final double odometer;

  _Fuel(this.date, this.liters, this.cost, this.odometer);
}

class _Service {
  final DateTime date;
  final double cost;
  final double odometer;
  double? get liters => null; // Service entries don't have liters

  _Service(this.date, this.cost, this.odometer);
}

void main() {
  group('MonthKey', () {
    test('equality and comparison', () {
      final m1 = MonthKey(2024, 1);
      final m2 = MonthKey(2024, 1);
      final m3 = MonthKey(2024, 2);

      expect(m1, equals(m2));
      expect(m1.compareTo(m2), 0);
      expect(m1.compareTo(m3), lessThan(0));
    });

    test('fromDate factory', () {
      final key = MonthKey.fromDate(DateTime(2024, 3, 15));
      expect(key.year, 2024);
      expect(key.month, 3);
    });
  });

  group('aggregateMonthly', () {
    test('groups entries by month and sums totals', () {
      final entries = [
        _Fuel(DateTime(2024, 1, 5), 40, 80, 1000),
        _Fuel(DateTime(2024, 1, 15), 35, 70, 1500),
        _Service(DateTime(2024, 1, 20), 50, 1600),
        _Fuel(DateTime(2024, 2, 3), 38, 76, 2000),
      ];

      final result = aggregateMonthly(entries);

      expect(result.length, 2);

      // January
      expect(result[0].month, MonthKey(2024, 1));
      expect(result[0].totalLiters, 75); // 40 + 35
      expect(result[0].totalCost, 200); // 80 + 70 + 50
      // Distance: (1500-1000) + (1600-1500) = 500 + 100 = 600
      expect(result[0].totalDistance, 600);

      // February
      expect(result[1].month, MonthKey(2024, 2));
      expect(result[1].totalLiters, 38);
      expect(result[1].totalCost, 76);
      // Only one entry in Feb, no previous entry -> distance = 0
      expect(result[1].totalDistance, 0);
    });

    test('returns empty list for no entries', () {
      final result = aggregateMonthly([]);
      expect(result, isEmpty);
    });
  });

  group('computeKpis', () {
    test('calculates correct KPIs from monthly data', () {
      final monthlyData = [
        MonthlyTotals(
          month: MonthKey(2024, 1),
          totalLiters: 75,
          totalCost: 200,
          totalDistance: 600,
        ),
        MonthlyTotals(
          month: MonthKey(2024, 2),
          totalLiters: 50,
          totalCost: 100,
          totalDistance: 400,
        ),
      ];

      final kpis = computeKpis(monthlyData);

      // Total: 300 cost, 1000 km, 125 liters
      // costPerKm = 300 / 1000 = 0.3
      expect(kpis['costPerKm'], closeTo(0.3, 0.01));

      // avgConsumptionL100km = (125 / 1000) * 100 = 12.5
      expect(kpis['avgConsumptionL100km'], closeTo(12.5, 0.01));

      // avgMonthlyCost = 300 / 2 = 150
      expect(kpis['avgMonthlyCost'], closeTo(150, 0.01));
    });

    test('returns zeros for empty data', () {
      final kpis = computeKpis([]);
      expect(kpis['costPerKm'], 0);
      expect(kpis['avgConsumptionL100km'], 0);
      expect(kpis['avgMonthlyCost'], 0);
    });
  });

  group('distanceFromOdometer', () {
    test('calculates absolute distance', () {
      expect(distanceFromOdometer(1500, 1000), 500);
      expect(distanceFromOdometer(1000, 1500), 500); // Absolute value
    });

    test('handles nulls safely', () {
      expect(distanceFromOdometer(null, 1000), 1000);
      expect(distanceFromOdometer(1500, null), 1500);
      expect(distanceFromOdometer(null, null), 0);
    });
  });

  group('MonthlyTotals', () {
    test('computes derived metrics correctly', () {
      final totals = MonthlyTotals(
        month: MonthKey(2024, 1),
        totalLiters: 60,
        totalCost: 180,
        totalDistance: 600,
      );

      // costPerKm = 180 / 600 = 0.3
      expect(totals.costPerKm, closeTo(0.3, 0.01));

      // avgConsumptionL100km = (60 / 600) * 100 = 10
      expect(totals.avgConsumptionL100km, closeTo(10, 0.01));
    });

    test('handles zero distance safely', () {
      final totals = MonthlyTotals(
        month: MonthKey(2024, 1),
        totalLiters: 40,
        totalCost: 100,
        totalDistance: 0,
      );

      expect(totals.costPerKm, 0);
      expect(totals.avgConsumptionL100km, 0);
    });
  });
}
