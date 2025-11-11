import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';
import 'package:fuel_service_log/data/models/service_entry.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/pdf/active_vehicle_report.dart';
import 'package:fuel_service_log/state/stats_filter.dart';
import 'package:fuel_service_log/state/stats_metric.dart';

/// Issue #24: PDF Greek fallback test
/// Validates that Greek characters (π.χ. «Τακτική συντήρηση», «Κατανάλωση», «Χιλιόμετρα»)
/// render properly in PDF output without throwing and with sufficient byte size.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Greek fallback tests (issue #24)', () {
    test('renders Greek text in vehicle title, service descriptions without throwing', () async {
      // Arrange: Dataset with Greek strings in critical fields
      final vehicle = Vehicle(
        id: 'v_gr1',
        title: 'Τεστ Όχημα',  // Greek: "Test Vehicle"
        plate: 'ΑΒΓ-1234',      // Greek plate with Greek letters
        active: true,
      );

      final now = DateTime.now();
      final fuelEntries = [
        FuelEntry(
          id: 'f_gr1',
          vehicleId: 'v_gr1',
          date: now.subtract(const Duration(days: 10)),
          odometerKm: 15000,
          liters: 50.5,
          pricePerLiter: 1.75,
          amount: 88.38,
          fullTank: true,
          notes: 'Κατανάλωση 7.2L/100km',  // Greek: "Consumption 7.2L/100km"
        ),
        FuelEntry(
          id: 'f_gr2',
          vehicleId: 'v_gr1',
          date: now.subtract(const Duration(days: 5)),
          odometerKm: 15700,
          liters: 48.0,
          pricePerLiter: 1.80,
          amount: 86.40,
          fullTank: true,
          notes: 'Χιλιόμετρα: 700 km',  // Greek: "Kilometers: 700 km"
        ),
      ];

      final serviceEntries = [
        ServiceEntry(
          id: 's_gr1',
          vehicleId: 'v_gr1',
          date: now.subtract(const Duration(days: 7)),
          odometerKm: 15350,
          description: 'Τακτική συντήρηση',  // Greek: "Routine maintenance"
          totalAmount: 120.00,
          notes: 'Αλλαγή λαδιών και φίλτρων',  // Greek: "Oil and filter change"
        ),
        ServiceEntry(
          id: 's_gr2',
          vehicleId: 'v_gr1',
          date: now.subtract(const Duration(days: 3)),
          odometerKm: 15600,
          description: 'Έλεγχος φρένων',  // Greek: "Brake inspection"
          totalAmount: 45.00,
          notes: 'Ελεγχος με διαγνωστικό',  // Greek: "Diagnostic check"
        ),
      ];

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

      // Act: Build PDF with Greek content
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert: PDF should be generated without throwing
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1024), reason: 'PDF should have substantial size for real content');

      // Verify PDF structure
      final header = String.fromCharCodes(bytes.sublist(0, 8));
      expect(header, startsWith('%PDF-'), reason: 'Should have valid PDF header');
    });

    test('renders mixed Greek and English text in single PDF', () async {
      // Arrange: Mix of Greek and English to test fallback robustness
      final vehicle = Vehicle(
        id: 'v_mix',
        title: 'Test Vehicle - Δοκιμαστικό Όχημα',  // Mixed EN/GR
        plate: 'ABC-123',
        active: true,
      );

      final now = DateTime.now();
      final fuelEntries = [
        FuelEntry(
          id: 'f_mix1',
          vehicleId: 'v_mix',
          date: now.subtract(const Duration(days: 2)),
          odometerKm: 20000,
          liters: 45.0,
          pricePerLiter: 1.65,
          amount: 74.25,
          fullTank: true,
          notes: 'Full tank - Γέμισμα ρεζερβουάρ',
        ),
      ];

      final serviceEntries = [
        ServiceEntry(
          id: 's_mix1',
          vehicleId: 'v_mix',
          date: now.subtract(const Duration(days: 1)),
          odometerKm: 20100,
          description: 'Oil change / Αλλαγή λαδιών',
          totalAmount: 95.00,
          notes: 'Synthetic 5W-30 - Συνθετικό λάδι',
        ),
      ];

      final filter = StatsFilter.custom(
        now.subtract(const Duration(days: 5)),
        now,
      );

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        serviceEntries: serviceEntries,
        filter: filter,
        metric: StatsMetric.liters,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1024));

      final header = String.fromCharCodes(bytes.sublist(0, 8));
      expect(header, startsWith('%PDF-'));
    });

    test('renders Greek text with all diacritics (άέήίόύώ)', () async {
      // Arrange: Test comprehensive Greek character coverage including diacritics
      final vehicle = Vehicle(
        id: 'v_diacritics',
        title: 'Δοκιμή διακριτικών',  // "Diacritics test"
        plate: 'ΔΟΚ-999',
        active: true,
      );

      final now = DateTime.now();
      final serviceEntries = [
        ServiceEntry(
          id: 's_diacritics',
          vehicleId: 'v_diacritics',
          date: now,
          odometerKm: 25000,
          description: 'Έλεγχος με διακριτικά: άέήίόύώ ΆΈΉΊΌΎΏ',
          totalAmount: 50.00,
          notes: 'Δοκιμή όλων των ελληνικών χαρακτήρων με τόνους',
        ),
      ];

      final filter = StatsFilter.all();

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: const [],
        serviceEntries: serviceEntries,
        filter: filter,
        metric: StatsMetric.cost,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert: Should render without errors despite complex diacritics
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(512));

      final header = String.fromCharCodes(bytes.sublist(0, 8));
      expect(header, startsWith('%PDF-'));
    });

    test('minimal Greek-only PDF for byte-size comparison', () async {
      // Arrange: Simplest possible Greek PDF to establish baseline size
      final vehicle = Vehicle(
        id: 'v_minimal',
        title: 'Δοκιμή',  // Just "Test"
        plate: 'ΔΟΚ-1',
        active: true,
      );

      final now = DateTime.now();
      final fuelEntries = [
        FuelEntry(
          id: 'f_minimal',
          vehicleId: 'v_minimal',
          date: now,
          odometerKm: 1000,
          liters: 10.0,
          pricePerLiter: 1.50,
          amount: 15.00,
          fullTank: true,
        ),
      ];

      final filter = StatsFilter.all();

      final input = PdfStatsReportInput(
        vehicle: vehicle,
        fuelEntries: fuelEntries,
        serviceEntries: const [],
        filter: filter,
        metric: StatsMetric.cost,
      );

      // Act
      final bytes = await ActiveVehiclePdfReport.build(input);

      // Assert: Minimal but valid PDF
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1024), reason: 'Even minimal report should exceed 1KB');
      expect(bytes.length, lessThan(50000), reason: 'Minimal report should be compact');

      // Heuristic: If NotoSans fonts are embedded, size should be reasonable
      // (not orders of magnitude different from English equivalent)
      // A proper font with Greek glyphs will add overhead but not excessive
      final header = String.fromCharCodes(bytes.sublist(0, 8));
      expect(header, startsWith('%PDF-'));
    });
  });
}
