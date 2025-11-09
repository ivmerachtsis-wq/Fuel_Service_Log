import 'package:hive/hive.dart';
import '../data/models/vehicle.dart';

/// Απλός controller για το ενεργό όχημα.
/// Προς το παρόν: αν δεν υπάρχει όχημα, δημιουργεί ένα default.
class ActiveVehicleController {
  static const _boxName = 'vehicles';

  Future<String> getActiveVehicleId() async {
    final box = Hive.box<Vehicle>(_boxName);
    if (box.isEmpty) {
      final v = Vehicle(id: 'vehicle-default', title: 'My Vehicle');
      await box.put(v.id, v);
      return v.id;
    }
    // Επιστρέφει το πρώτο διαθέσιμο
    final first = box.values.first;
    return first.id;
  }
}
