import '../data/repo/fuel_repo.dart';
import '../data/repo/service_repo.dart';
import '../state/settings_controller.dart';

/// Service για έλεγχο ακεραιότητας δεδομένων
class DataIntegrityService {
  /// Safe substring helper - επιστρέφει κενό string αν τα όρια είναι εκτός εύρους
  static String _safeSubstring(String s, int start, [int? end]) {
    if (s.isEmpty) return '';
    final len = s.length;
    final s0 = (start < 0) ? 0 : (start > len ? len : start);
    final e0 = (end == null) ? len : (end < 0 ? 0 : (end > len ? len : end));
    if (e0 < s0) return '';
    return s.substring(s0, e0);
  }

  /// Safe truncation για εμφάνιση ID - επιστρέφει το πρώτο μέρος ή ολόκληρο αν είναι μικρό
  static String _truncateId(String id, [int maxLen = 8]) {
    if (id.isEmpty) return '(κενό)';
    if (id.length <= maxLen) return id;
    return '${_safeSubstring(id, 0, maxLen)}...';
  }

  /// Εκτελεί πλήρη έλεγχο ακεραιότητας για Fuel και Service entries
  static Future<DataIntegrityReport> runFullCheck({
    required SettingsController settings,
    required FuelRepo fuelRepo,
    required ServiceRepo serviceRepo,
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    
    final issues = <String>[];
    
    // Έλεγχος Fuel entries
    final fuelEntries = fuelRepo.listAll();
    final fuelIds = <String>{};
    
    for (final entry in fuelEntries) {
      // Έλεγχος κενού/διπλότυπου id
      if (entry.id.isEmpty) {
        issues.add('Fuel: Κενό id');
      } else if (fuelIds.contains(entry.id)) {
        issues.add('Fuel: Διπλότυπο id "${entry.id}"');
      } else {
        fuelIds.add(entry.id);
      }
      
      // Έλεγχος ημερομηνίας
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.isAfter(todayDate)) {
        issues.add('Fuel: Μελλοντική ημερομηνία (${entry.date})');
      }
      
      // Έλεγχος odometerKm
      if (entry.odometerKm < 0) {
        issues.add('Fuel: Αρνητικά χιλιόμετρα (${entry.odometerKm})');
      }
      
      // Έλεγχος currencyCode
      if (entry.currencyCode == null) {
        issues.add('Fuel: Κενό νόμισμα για entry ${_truncateId(entry.id)} (προτείνεται: ${settings.currencyCode})');
      }
    }
    
    // Έλεγχος Service entries
    final serviceEntries = serviceRepo.listAll();
    final serviceIds = <String>{};
    
    for (final entry in serviceEntries) {
      // Έλεγχος κενού/διπλότυπου id
      if (entry.id.isEmpty) {
        issues.add('Service: Κενό id');
      } else if (serviceIds.contains(entry.id)) {
        issues.add('Service: Διπλότυπο id "${entry.id}"');
      } else {
        serviceIds.add(entry.id);
      }
      
      // Έλεγχος περιγραφής
      if (entry.description.trim().isEmpty) {
        issues.add('Service: Κενή περιγραφή για entry ${_truncateId(entry.id)}');
      }
      
      // Έλεγχος odometerKm
      if (entry.odometerKm < 0) {
        issues.add('Service: Αρνητικά χιλιόμετρα (${entry.odometerKm})');
      }
      
      // Έλεγχος ημερομηνίας
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate.isAfter(todayDate)) {
        issues.add('Service: Μελλοντική ημερομηνία (${entry.date})');
      }
      
      // Έλεγχος currencyCode
      if (entry.currencyCode == null) {
        issues.add('Service: Κενό νόμισμα για entry ${_truncateId(entry.id)} (προτείνεται: ${settings.currencyCode})');
      }
    }
    
    return DataIntegrityReport(
      fuelCount: fuelEntries.length,
      serviceCount: serviceEntries.length,
      issues: issues,
    );
  }
}

/// Αναφορά ελέγχου ακεραιότητας δεδομένων
class DataIntegrityReport {
  final int fuelCount;
  final int serviceCount;
  final List<String> issues;
  
  DataIntegrityReport({
    required this.fuelCount,
    required this.serviceCount,
    required this.issues,
  });
  
  /// Επιστρέφει true αν δεν βρέθηκαν προβλήματα
  bool get ok => issues.isEmpty;
}
