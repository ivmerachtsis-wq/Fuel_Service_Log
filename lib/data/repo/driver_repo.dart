import 'package:hive/hive.dart';
import '../models/driver.dart';

class DriverRepo {
  static const _boxName = 'drivers';

  Box<Driver> get _box => Hive.box<Driver>(_boxName);

  /// Προσθήκη νέου οδηγού
  Future<void> add(Driver driver) async {
    await _box.put(driver.id, driver);
  }

  /// Ενημέρωση υπάρχοντος οδηγού
  Future<void> update(Driver driver) async {
    await _box.put(driver.id, driver);
  }

  /// Διαγραφή οδηγού
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Λήψη οδηγού με id
  Driver? getById(String id) {
    return _box.get(id);
  }

  /// Λίστα όλων των οδηγών
  List<Driver> listAll() {
    return _box.values.toList();
  }

  /// Stream για παρακολούθηση αλλαγών
  Stream<List<Driver>> watchAll() {
    return _box.watch().map((_) => listAll());
  }
}
