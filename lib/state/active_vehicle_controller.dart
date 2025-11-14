import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../data/models/vehicle.dart';
import '../services/ui_prefs_service.dart';

/// Single source of truth για το ενεργό όχημα.
/// Reads/writes από UiPrefsService και παρέχει ValueNotifier για reactive UI.
class ActiveVehicleController {
  static const _boxName = 'vehicles';
  final UiPrefs _prefs;
  
  /// ValueNotifier που κρατάει το τρέχον active vehicle ID.
  /// Widgets μπορούν να κάνουν listen για αλλαγές.
  final ValueNotifier<String?> activeVehicleIdNotifier = ValueNotifier(null);
  
  ActiveVehicleController({UiPrefs? prefs}) : _prefs = prefs ?? UiPrefsService() {
    // Initialize notifier με την τρέχουσα τιμή
    activeVehicleIdNotifier.value = _prefs.loadActiveVehicleId();
  }
  
  /// Επιστρέφει το τρέχον active vehicle ID από UiPrefs.
  /// Αν δεν υπάρχει, επιστρέφει το πρώτο διαθέσιμο vehicle ή δημιουργεί ένα default.
  Future<String> getActiveVehicleId() async {
    final storedId = _prefs.loadActiveVehicleId();
    if (storedId != null) {
      return storedId;
    }
    
    // Fallback: αν δεν υπάρχει stored ID, βρες το πρώτο vehicle ή δημιούργησε ένα
    final box = Hive.box<Vehicle>(_boxName);
    if (box.isEmpty) {
      final v = Vehicle(id: 'vehicle-default', title: 'My Vehicle', active: true);
      await box.put(v.id, v);
      await setActiveVehicleId(v.id);
      return v.id;
    }
    
    // Βρες vehicle με active=true ή το πρώτο
    final activeVehicle = box.values.firstWhere((v) => v.active, orElse: () => box.values.first);
    await setActiveVehicleId(activeVehicle.id);
    return activeVehicle.id;
  }
  
  /// Ενημερώνει το active vehicle ID στο UiPrefs και το ValueNotifier.
  Future<void> setActiveVehicleId(String id) async {
    await _prefs.saveActiveVehicleId(id);
    activeVehicleIdNotifier.value = id;
  }
}
