import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/domain/stats_service.dart';
import 'package:fuel_service_log/data/models/fuel_entry.dart';

void main() {
  late StatsService service;

  setUp(() {
    service = StatsService();
  });

  group('getFullToFullConsumptions', () {
    test('υπολογίζει σωστά L/100km με 3 fullTank entries και ενδιάμεσα refuels', () {
      final entries = [
        FuelEntry(
          id: '1',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 1),
          odometerKm: 1000,
          liters: 50,
          pricePerLiter: 1.5,
          amount: 75,
          fullTank: true,
        ),
        FuelEntry(
          id: '2',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 5),
          odometerKm: 1200,
          liters: 10,
          pricePerLiter: 1.5,
          amount: 15,
          fullTank: false,
        ),
        FuelEntry(
          id: '3',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 10),
          odometerKm: 1500,
          liters: 30,
          pricePerLiter: 1.5,
          amount: 45,
          fullTank: true,
        ),
        FuelEntry(
          id: '4',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 20),
          odometerKm: 2000,
          liters: 40,
          pricePerLiter: 1.5,
          amount: 60,
          fullTank: true,
        ),
      ];

      final result = service.getFullToFullConsumptions(entries);

      expect(result.length, 2);
      
      // Πρώτο εύρος: 1000->1500km = 500km, λίτρα: 10+30=40, consumption: 8 L/100km
      expect(result[0].litersPer100Km, 8.0);
      expect(result[0].date, DateTime(2024, 1, 10));

      // Δεύτερο εύρος: 1500->2000km = 500km, λίτρα: 40, consumption: 8 L/100km
      expect(result[1].litersPer100Km, 8.0);
      expect(result[1].date, DateTime(2024, 1, 20));
    });

    test('αγνοεί εύρη με οπισθοδρομικό odometer (km <= 0)', () {
      final entries = [
        FuelEntry(
          id: '1',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 1),
          odometerKm: 2000,
          liters: 50,
          pricePerLiter: 1.5,
          amount: 75,
          fullTank: true,
        ),
        FuelEntry(
          id: '2',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 10),
          odometerKm: 1500, // Οπισθοδρομικό!
          liters: 40,
          pricePerLiter: 1.5,
          amount: 60,
          fullTank: true,
        ),
        FuelEntry(
          id: '3',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 20),
          odometerKm: 2000,
          liters: 40,
          pricePerLiter: 1.5,
          amount: 60,
          fullTank: true,
        ),
      ];

      final result = service.getFullToFullConsumptions(entries);

      // Το πρώτο εύρος (2000->1500) αγνοείται, μόνο το δεύτερο (1500->2000) υπολογίζεται
      expect(result.length, 1);
      expect(result[0].litersPer100Km, 8.0);
    });

    test('επιστρέφει κενή λίστα για άδεια entries', () {
      final result = service.getFullToFullConsumptions([]);
      expect(result, isEmpty);
    });

    test('επιστρέφει κενή λίστα όταν υπάρχει μόνο ένα fullTank', () {
      final entries = [
        FuelEntry(
          id: '1',
          vehicleId: 'v1',
          date: DateTime(2024, 1, 1),
          odometerKm: 1000,
          liters: 50,
          pricePerLiter: 1.5,
          amount: 75,
          fullTank: true,
        ),
      ];

      final result = service.getFullToFullConsumptions(entries);
      expect(result, isEmpty);
    });
  });

  group('getMonthlyCost', () {
    test('ομαδοποιεί σωστά κατά μήνα και συμπληρώνει με 0', () {
      final now = DateTime.now();
      final entries = [
        FuelEntry(
          id: '1',
          vehicleId: 'v1',
          date: DateTime(now.year, now.month, 1),
          odometerKm: 1000,
          liters: 50,
          pricePerLiter: 1.5,
          amount: 75,
          fullTank: true,
        ),
        FuelEntry(
          id: '2',
          vehicleId: 'v1',
          date: DateTime(now.year, now.month, 15),
          odometerKm: 1200,
          liters: 30,
          pricePerLiter: 1.5,
          amount: 45,
          fullTank: true,
        ),
      ];

      final result = service.getMonthlyCost(entries, months: 3);

      expect(result.length, 3);
      
      // Τρέχων μήνας πρέπει να έχει άθροισμα 120
      expect(result.last.amount, 120.0);
      
      // Προηγούμενοι μήνες χωρίς δεδομένα πρέπει να έχουν 0
      expect(result[0].amount, 0.0);
      expect(result[1].amount, 0.0);
    });

    test('επιστρέφει κενή λίστα για άδεια entries', () {
      final result = service.getMonthlyCost([]);
      expect(result, isEmpty);
    });
  });

  group('getAverageConsumption', () {
    test('υπολογίζει μέσο όρο σωστά', () {
      final points = [
        ConsumptionPoint(date: DateTime.now(), litersPer100Km: 7.5),
        ConsumptionPoint(date: DateTime.now(), litersPer100Km: 8.5),
        ConsumptionPoint(date: DateTime.now(), litersPer100Km: 9.0),
      ];

      final avg = service.getAverageConsumption(points);
      expect(avg, closeTo(8.33, 0.01));
    });

    test('επιστρέφει 0 για κενή λίστα', () {
      final avg = service.getAverageConsumption([]);
      expect(avg, 0);
    });
  });

  group('getAverageMonthlyCost', () {
    test('υπολογίζει μέσο όρο αγνοώντας μήνες με 0 κόστος', () {
      final costs = [
        MonthlyCost(yearMonth: '2024-01', amount: 0),
        MonthlyCost(yearMonth: '2024-02', amount: 100),
        MonthlyCost(yearMonth: '2024-03', amount: 200),
      ];

      final avg = service.getAverageMonthlyCost(costs);
      expect(avg, 150.0);
    });

    test('επιστρέφει 0 για κενή λίστα', () {
      final avg = service.getAverageMonthlyCost([]);
      expect(avg, 0);
    });
  });
}
