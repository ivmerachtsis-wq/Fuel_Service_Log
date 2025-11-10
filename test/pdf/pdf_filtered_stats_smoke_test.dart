import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/pdf/active_vehicle_report.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveVehiclePdfReport smoke tests', () {
    test('builds PDF with minimal filtered dataset (>1024 bytes)', () async {
      // Arrange: minimal in-memory dataset with 2 fuel entries + 1 service entry
      final vehicle = Vehicle(
        id: 'v1',
        title: 'Test Vehicle',
        plate: 'ABC-123',
        active: true,
      );

      final now = DateTime.now();
      final fuelEntries = [
        FuelEntry(
          id: 'f1',
          vehicleId: 'v1',
          date: now.subtract(const Duration(days: 10)),
          odometerKm: 10000,
          liters: 45.0,
          pricePerLiter: 1.50,
          amount: 67.50,
          fullTank: true,
        ),
        FuelEntry(
          id: 'f2',
          vehicleId: 'v1',
          date: now.subtract(const Duration(days: 5)),
          odometerKm: 10500,
          liters: 40.0,
          pricePerLiter: 1.55,
          amount: 62.00,
          fullTank: true,
        ),
      ];

      final serviceEntries = [
        ServiceEntry(
          id: 's1',
          vehicleId: 'v1',
          date: now.subtract(const Duration(days: 7)),
          odometerKm: 10250,
          description: 'Oil Change',
          totalAmount: 85.00,
        ),
      ];

      // Narrow date filter that includes all entries
      final filter = StatsFilter.custom(
        now.subtract(const Duration(days: 15)),
        now,
      );

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        serviceEntries: serviceEntries,
        filter: filter,
        metric: StatsMetric.cost,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert: PDF should be substantial (>1024 bytes for a real report)
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1024));
    });

    test('builds minimal PDF with "No data" message when filters produce zero entries', () async {
      // Arrange: dataset with entries, but filter excludes all
      final vehicle = Vehicle(
        id: 'v2',
        title: 'Empty Test Vehicle',
        plate: 'XYZ-999',
        active: true,
      );

      final now = DateTime.now();
      final fuelEntries = [
        FuelEntry(
          id: 'f3',
          vehicleId: 'v2',
          date: now.subtract(const Duration(days: 100)),
          odometerKm: 5000,
          liters: 50.0,
          pricePerLiter: 1.40,
          amount: 70.00,
          fullTank: true,
        ),
      ];

      final serviceEntries = [
        ServiceEntry(
          id: 's2',
          vehicleId: 'v2',
          date: now.subtract(const Duration(days: 95)),
          odometerKm: 5200,
          description: 'Tire Rotation',
          totalAmount: 50.00,
        ),
      ];

      // Filter that excludes all entries (recent 10 days, but entries are 95-100 days old)
      final filter = StatsFilter.custom(
        now.subtract(const Duration(days: 10)),
        now,
      );

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        serviceEntries: serviceEntries,
        filter: filter,
        metric: StatsMetric.cost,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert: PDF should be generated without throwing
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(512)); // Minimal PDF with message

      // Verify the PDF contains the "No data" message by checking raw bytes
      final pdfString = String.fromCharCodes(bytes);
      expect(pdfString, contains('No data in selected filters'));
    });
  });
}
