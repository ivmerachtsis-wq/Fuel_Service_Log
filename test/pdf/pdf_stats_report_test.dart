import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/pdf/active_vehicle_report.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';

void main() {
  group('ActiveVehiclePdfReport', () {
    test('generates valid PDF bytes with sample data', () async {
      // Arrange
      final vehicle = Vehicle(
        id: 'v1',
  title: 'Toyota Corolla 2020',
      );

      final fuelEntries = [
        FuelEntry(
          id: 'f1',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 15),
          odometerKm: 10000,
          liters: 40.0,
          pricePerLiter: 1.5,
          amount: 60.0,
        ),
        FuelEntry(
          id: 'f2',
          vehicleId: 'v1',
          date: DateTime(2024, 2, 20),
          odometerKm: 10500,
          liters: 35.0,
          pricePerLiter: 1.5,
          amount: 52.5,
        ),
      ];

      final serviceEntries = [
        ServiceEntry(
          id: 's1',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 10),
          odometerKm: 9800,
          totalAmount: 150.0,
          description: 'Oil change',
        ),
      ];

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        serviceEntries: serviceEntries,
        filter: StatsFilter.last90(),
        metric: StatsMetric.cost,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000), reason: 'PDF should be at least 1KB');
      expect(bytes[0], equals(0x25), reason: 'PDF should start with %');
      expect(bytes[1], equals(0x50), reason: 'PDF magic number');
      expect(bytes[2], equals(0x44), reason: 'PDF magic number');
      expect(bytes[3], equals(0x46), reason: 'PDF magic number');
    });

    test('generates PDF with empty data', () async {
      // Arrange
      final vehicle = Vehicle(
        id: 'v1',
  title: 'Honda Civic 2019',
      );

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: [],
        serviceEntries: [],
        filter: const StatsFilter.all(),
        metric: StatsMetric.distance,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(500), reason: 'Empty PDF should still have structure');
    });

    test('generates PDF with different metrics', () async {
      // Arrange
      final vehicle = Vehicle(
        id: 'v1',
  title: 'Ford Focus 2021',
      );

      final fuelEntries = [
        FuelEntry(
          id: 'f1',
          vehicleId: 'v1',
          date: DateTime(2024, 3, 1),
          odometerKm: 15000,
          liters: 45.0,
          pricePerLiter: 1.5,
          amount: 67.5,
        ),
      ];

      // Test each metric
      for (final metric in StatsMetric.values) {
        final input = PdfStatsReportInput(
          vehicle: vehicle,
          fuelEntries: fuelEntries,
          serviceEntries: [],
          filter: StatsFilter.ytd(),
          metric: metric,
        );

        final bytes = await ActiveVehiclePdfReport.build(input);

        expect(bytes, isNotEmpty, reason: 'Should generate PDF for $metric');
        expect(bytes.length, greaterThan(1000), reason: 'PDF for $metric should be valid');
      }
    });
  });
}
