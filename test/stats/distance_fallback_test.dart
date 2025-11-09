import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/domain/stats_aggregator.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';

void main() {
  test('computeDistanceKm uses fuel when enough data', () {
    final fuel = [
      FuelEntry(
        id: '1',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 1),
        odometerKm: 10000,
        amount: 0,
        liters: 0,
        pricePerLiter: 0,
        fullTank: true,
      ),
      FuelEntry(
        id: '2',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 10),
        odometerKm: 10500,
        amount: 0,
        liters: 0,
        pricePerLiter: 0,
        fullTank: true,
      ),
    ];
    final service = [
      ServiceEntry(
        id: 's1',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 5),
        odometerKm: 10200,
        totalAmount: 0,
        description: 'Service',
      ),
    ];
    final d = computeDistanceKm(fuel: fuel, service: service);
    expect(d, 500);
  });

  test('computeDistanceKm falls back to service when fuel < 2 or zero span', () {
    final fuel = [
      FuelEntry(
        id: '1',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 1),
        odometerKm: 10000,
        amount: 0,
        liters: 0,
        pricePerLiter: 0,
        fullTank: true,
      ),
    ];
    final service = [
      ServiceEntry(
        id: 's1',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 20),
        odometerKm: 10800,
        totalAmount: 0,
        description: 'Service 1',
      ),
      ServiceEntry(
        id: 's2',
        vehicleId: 'v1',
        date: DateTime(2025, 1, 5),
        odometerKm: 10200,
        totalAmount: 0,
        description: 'Service 2',
      ),
    ];
    final d = computeDistanceKm(fuel: fuel, service: service);
    expect(d, 600);
  });

  test('computeDistanceKm returns 0 when nothing usable', () {
    final d = computeDistanceKm(fuel: const [], service: const []);
    expect(d, 0);
  });
}
