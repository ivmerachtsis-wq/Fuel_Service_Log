import 'package:hive/hive.dart';
import '../models/vehicle.dart';

class VehicleRepo {
  static const _boxName = 'vehicles';

  Box<Vehicle> get _box => Hive.box<Vehicle>(_boxName);

  /// Προσθήκη νέου οχήματος
  Future<void> add(Vehicle vehicle) async {
    await _box.put(vehicle.id, vehicle);
  }

  /// Ενημέρωση υπάρχοντος οχήματος
  Future<void> update(Vehicle vehicle) async {
    await _box.put(vehicle.id, vehicle);
  }

  /// Διαγραφή οχήματος
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Λήψη οχήματος με id
  Vehicle? getById(String id) {
    return _box.get(id);
  }

  /// Λίστα όλων των οχημάτων
  List<Vehicle> listAll() {
    return _box.values.toList();
  }

  /// Λίστα ενεργών οχημάτων
  List<Vehicle> listActive() {
    return _box.values.where((v) => v.active).toList();
  }

  /// Stream για παρακολούθηση αλλαγών
  Stream<List<Vehicle>> watchAll() {
    return _box.watch().map((_) => listAll());
  }
}
