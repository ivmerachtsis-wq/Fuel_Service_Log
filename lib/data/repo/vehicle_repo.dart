import 'package:hive/hive.dart';
import '../models/vehicle.dart';
import 'dart:async';

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

  /// Stream για παρακολούθηση αλλαγών με αρχική τιμή
  Stream<List<Vehicle>> watchAll() {
    late StreamController<List<Vehicle>> controller;
    StreamSubscription<BoxEvent>? subscription;
    
    controller = StreamController<List<Vehicle>>.broadcast(
      onListen: () {
        // Emit initial value immediately
        if (!controller.isClosed) {
          controller.add(listAll());
        }
        // Start watching box changes
        subscription = _box.watch().listen((_) {
          if (!controller.isClosed) {
            controller.add(listAll());
          }
        });
      },
      onCancel: () {
        subscription?.cancel();
        controller.close();
      },
    );
    
    return controller.stream;
  }
}
