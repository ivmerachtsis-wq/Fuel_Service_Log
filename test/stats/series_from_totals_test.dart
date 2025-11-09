import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/domain/stats_aggregator.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';

void main() {
  test('seriesFromTotals groups by month and sums amounts/liters', () {
    final fuel = [
      FuelEntry(
        id: '1',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 10),
        amount: 90.0,
        liters: 60.0,
        odometerKm: 10100,
        pricePerLiter: 1.5,
        fullTank: true,
      ),
      FuelEntry(
        id: '2',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 25),
        amount: 92.0,
        liters: 61.0,
        odometerKm: 10750,
        pricePerLiter: 1.5,
        fullTank: true,
      ),
      FuelEntry(
        id: '3',
        vehicleId: 'v1',
        date: DateTime(2025, 2, 5),
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
        date: DateTime(2025, 1, 15),
        totalAmount: 140.0,
        odometerKm: 10500,
        description: 'Oil change',
      ),
    ];

    final s = seriesFromTotals(fuel: fuel, service: service);
    expect(s.length, 2);
    expect(s[0].month, DateTime(2025, 1, 1));
    expect(s[0].fuelAmount, closeTo(182.0, 0.001));
    expect(s[0].serviceAmount, closeTo(140.0, 0.001));
    expect(s[0].liters, closeTo(121.0, 0.001));
    expect(s[1].month, DateTime(2025, 2, 1));
    expect(s[1].fuelAmount, closeTo(88.0, 0.001));
    expect(s[1].serviceAmount, closeTo(0.0, 0.001));
    expect(s[1].liters, closeTo(58.0, 0.001));
  });
}
