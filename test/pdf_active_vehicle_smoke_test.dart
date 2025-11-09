import 'package:flutter_test/flutter_test.dart';
// Intentionally minimal imports to avoid analyzer warnings

import 'package:fuel_service_log/features/exports/pdf/active_vehicle_report.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/l10n/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveVehicleReport PDF smoke', () {
    test('buildActiveVehicleReport returns non-trivial bytes', () async {
      final vehicle = Vehicle(id: 'veh_1', title: 'TestCar', plate: 'TEST-123', active: true);
      final fuelEntries = List.generate(8, (i) {
        return FuelEntry(
          id: 'fuel_$i',
          vehicleId: 'veh_1',
          date: DateTime(2025, 1, i + 1),
          odometerKm: 1000 + i * 50,
          liters: (40 + i).toDouble(),
          pricePerLiter: 1.7,
          amount: (40 + i) * 1.7,
          fullTank: i % 3 == 0,
        );
      });
      final serviceEntries = List.generate(5, (i) {
        return ServiceEntry(
          id: 'svc_$i',
          vehicleId: 'veh_1',
          date: DateTime(2025, 2, i + 1),
          odometerKm: 1400 + i * 60,
          description: 'Service desc $i',
          totalAmount: (120 + i * 15).toDouble(),
        );
      });

      const kpis = StatsKpis(avgConsumption: 6.8, costPerKm: 0.12, monthlyCost: 150.00);
      final l10n = AppLocalizationsEn();

      final bytes = await buildActiveVehicleReport(
        v: vehicle,
        fuel: fuelEntries,
        service: serviceEntries,
        kpis: kpis,
        l10n: l10n,
        currencyCode: 'EUR',
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
    });
  });
}