import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/ui/fuel/fuel_form_controller.dart';

void main() {
  group('FuelFormController 2-of-3', () {
    test('liters + price -> amount', () {
      final c = FuelFormController();
      c.setLiters(10);
      c.setPricePerLiter(2);
      expect(c.amount, 20);
    });

    test('liters + amount -> price', () {
      final c = FuelFormController();
      c.setLiters(5);
      c.setAmount(10);
      expect(c.pricePerLiter, 2);
    });

    test('price + amount -> liters', () {
      final c = FuelFormController();
      c.setPricePerLiter(2);
      c.setAmount(10);
      expect(c.liters, 5);
    });

    test('no loops on recalculation', () {
      final c = FuelFormController();
      c.setLiters(5);
      c.setPricePerLiter(2);
      // Now amount should be 10.
      expect(c.amount, 10);
      // Changing amount should recompute price (since liters known)
      c.setAmount(20);
      expect(c.pricePerLiter, 4);
    });
  });
}
