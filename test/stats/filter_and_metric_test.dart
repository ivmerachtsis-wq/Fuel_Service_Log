import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/domain/stats_aggregator.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';

void main() {
  final jan10 = DateTime(2025, 1, 10);
  final jan25 = DateTime(2025, 1, 25);
  final feb05 = DateTime(2025, 2, 5);
  final feb15 = DateTime(2025, 2, 15);

  final fuel = [
    FuelEntry(
      id: '1',
      vehicleId: 'v1',
      date: jan10,
      amount: 90.0,
      liters: 60.0,
      odometerKm: 10100,
      pricePerLiter: 1.5,
      fullTank: true,
    ),
    FuelEntry(
      id: '2',
      vehicleId: 'v1',
      date: jan25,
      amount: 92.0,
      liters: 61.0,
      odometerKm: 10750,
      pricePerLiter: 1.5,
      fullTank: true,
    ),
    FuelEntry(
      id: '3',
      vehicleId: 'v1',
      date: feb05,
      amount: 88.0,
      liters: 58.0,
      odometerKm: 11400,
      pricePerLiter: 1.5,
      fullTank: true,
    ),
  ];

  final service = [
    ServiceEntry(
      id: 's1',
      vehicleId: 'v1',
      date: feb15,
      totalAmount: 140.0,
      odometerKm: 11600,
      description: 'Oil change',
    ),
  ];

  test('StatsFilter.custom includes only dates within range', () {
    final f = StatsFilter.custom(DateTime(2025, 1, 1), DateTime(2025, 1, 31));
    expect(f.includes(jan10), isTrue);
    expect(f.includes(feb05), isFalse);
  });

  test('seriesFromTotals respects filtered inputs', () {
    final filteredFuel = fuel.where((e) => e.date.month == 1).toList();
    final filteredService = <ServiceEntry>[];
    final series = seriesFromTotals(fuel: filteredFuel, service: filteredService);
    expect(series.length, 1);
    expect(series.first.month, DateTime(2025, 1, 1));
    expect(series.first.fuelAmount, closeTo(182.0, 0.001));
    expect(series.first.liters, closeTo(121.0, 0.001));
  });

  test('estimateMonthlyDistanceKm uses odometer span per month', () {
    final janFuel = fuel.where((e) => e.date.month == 1).toList(); // 10100..10750 => 650
    final febFuel = fuel.where((e) => e.date.month == 2).toList(); // 11400..11400 => 0
    final febService = service.where((e) => e.date.month == 2).toList(); // 11600 only -> 0 span

    final dJan = estimateMonthlyDistanceKm(fuelMonth: janFuel, serviceMonth: const []);
    final dFeb = estimateMonthlyDistanceKm(fuelMonth: febFuel, serviceMonth: febService);

    expect(dJan, 650);
    expect(dFeb, 0);
  });
}
