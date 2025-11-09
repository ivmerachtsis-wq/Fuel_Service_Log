import 'package:hive/hive.dart';
import '../models/service_entry.dart';

class ServiceRepo {
  static const _boxName = 'service_entries';

  Box<ServiceEntry> get _box => Hive.box<ServiceEntry>(_boxName);

  /// Προσθήκη νέας εγγραφής service
  Future<void> add(ServiceEntry entry) async {
    await _box.put(entry.id, entry);
  }

  /// Ενημέρωση υπάρχουσας εγγραφής
  Future<void> update(ServiceEntry entry) async {
    await _box.put(entry.id, entry);
  }

  /// Διαγραφή εγγραφής
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Λήψη εγγραφής με id
  ServiceEntry? getById(String id) {
    return _box.get(id);
  }

  /// Λίστα όλων των εγγραφών
  List<ServiceEntry> listAll() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Λίστα εγγραφών για συγκεκριμένο όχημα
  List<ServiceEntry> listByVehicle(String vehicleId) {
    return _box.values.where((e) => e.vehicleId == vehicleId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Stream για παρακολούθηση αλλαγών
  Stream<List<ServiceEntry>> watchAll() {
    return _box.watch().map((_) => listAll());
  }

  /// Stream για παρακολούθηση αλλαγών συγκεκριμένου οχήματος
  Stream<List<ServiceEntry>> watchByVehicle(String vehicleId) {
    return _box.watch().map((_) => listByVehicle(vehicleId));
  }
}
