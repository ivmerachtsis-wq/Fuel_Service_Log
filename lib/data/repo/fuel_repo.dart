import 'package:hive/hive.dart';
import '../models/fuel_entry.dart';

class FuelRepo {
  static const _boxName = 'fuel_entries';

  Box<FuelEntry> get _box => Hive.box<FuelEntry>(_boxName);

  /// Προσθήκη νέας εγγραφής καυσίμων
  Future<void> add(FuelEntry entry) async {
    await _box.put(entry.id, entry);
  }

  /// Ενημέρωση υπάρχουσας εγγραφής
  Future<void> update(FuelEntry entry) async {
    await _box.put(entry.id, entry);
  }

  /// Διαγραφή εγγραφής
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Λήψη εγγραφής με id
  FuelEntry? getById(String id) {
    return _box.get(id);
  }

  /// Λίστα όλων των εγγραφών
  List<FuelEntry> listAll() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Λίστα εγγραφών για συγκεκριμένο όχημα
  List<FuelEntry> listByVehicle(String vehicleId) {
    return _box.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Stream για παρακολούθηση αλλαγών
  Stream<List<FuelEntry>> watchAll() {
    return _box.watch().map((_) => listAll());
  }

  /// Stream για παρακολούθηση αλλαγών συγκεκριμένου οχήματος
  Stream<List<FuelEntry>> watchByVehicle(String vehicleId) {
    return _box.watch().map((_) => listByVehicle(vehicleId));
  }
}
