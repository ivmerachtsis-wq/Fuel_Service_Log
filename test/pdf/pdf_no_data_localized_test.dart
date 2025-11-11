import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/pdf/active_vehicle_report.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';
import 'package:fuel_service_log/l10n/app_localizations_el.dart';

/// Issue #30: PDF "No data" localized test
/// Validates that PDF generation works with Greek localized "No data" text
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF No Data localized (issue #30)', () {
    test('generates PDF with Greek "No data" message when filters exclude all entries', () async {
      final l10n = AppLocalizationsEl();

      // Arrange: Empty filtered dataset (entries exist but are excluded by filter)
      final vehicle = Vehicle(
        id: 'v_el_empty',
        title: 'Τεστ Όχημα',
        plate: 'ΑΒΓ-123',
        active: true,
      );

      final now = DateTime.now();
      final fuelEntries = [
        FuelEntry(
          id: 'f_old',
          vehicleId: 'v_el_empty',
          date: now.subtract(const Duration(days: 200)),
          odometerKm: 10000,
          liters: 50.0,
          pricePerLiter: 1.50,
          amount: 75.00,
          fullTank: true,
        ),
      ];

      final serviceEntries = [
        ServiceEntry(
          id: 's_old',
          vehicleId: 'v_el_empty',
          date: now.subtract(const Duration(days: 195)),
          odometerKm: 10200,
          description: 'Παλιό service',
          totalAmount: 100.00,
        ),
      ];

      // Filter that excludes all entries (last 30 days, but entries are 195-200 days old)
      final filter = StatsFilter.custom(
        now.subtract(const Duration(days: 30)),
        now,
      );

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        serviceEntries: serviceEntries,
        filter: filter,
        metric: StatsMetric.cost,
        noDataText: l10n.stats_noDataInSelectedFilters,
      );

      // Act: Build PDF with Greek "No data" text
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert: PDF should be generated without throwing
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(512), reason: 'Minimal PDF with Greek empty message should be generated');
      expect(bytes.length, lessThan(15000), reason: 'Empty PDF should be compact');

      // Verify PDF structure
      final header = String.fromCharCodes(bytes.sublist(0, 8));
      expect(header, startsWith('%PDF-'), reason: 'Should have valid PDF header');
    });

    test('generates PDF with Greek "No data" message for completely empty vehicle', () async {
      final l10n = AppLocalizationsEl();

      // Arrange: Vehicle with absolutely no entries
      final vehicle = Vehicle(
        id: 'v_el_completely_empty',
        title: 'Άδειο Όχημα',
        plate: 'ΧΨΩ-999',
        active: true,
      );

      final filter = StatsFilter.all();

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: const [],
        serviceEntries: const [],
        filter: filter,
        metric: StatsMetric.liters,
        noDataText: l10n.stats_noDataInSelectedFilters,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(512));

      final header = String.fromCharCodes(bytes.sublist(0, 8));
      expect(header, startsWith('%PDF-'));
    });
  });
}
