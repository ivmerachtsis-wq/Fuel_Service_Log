import 'dart:io';
import 'package:fuel_service_log/services/save_target_resolver.dart';

/// Fake implementation of SaveTargetResolver for testing
/// Avoids real file_selector platform calls
class FakeSaveTargetResolver implements SaveTargetResolver {
  /// Track number of calls for verification
  int calls = 0;
  
  /// Track last parameters passed
  Directory? lastDefaultDir;
  bool? lastAsk;
  SaveKind? lastKind;
  
  /// Fixed directory to return (defaults to system temp)
  Directory fixed = Directory.systemTemp;
  
  /// Whether to simulate user cancellation (return null)
  bool simulateCancel = false;

  @override
  Future<Directory?> resolveDirectory(
    SaveKind kind, {
    required bool ask,
    Directory? defaultDir,
  }) async {
    calls++;
    lastDefaultDir = defaultDir;
    lastAsk = ask;
    lastKind = kind;
    
    if (simulateCancel && ask) {
      return null; // Simulate user cancelling picker
    }
    
    return fixed;
  }

  @override
  Future<String?> resolveFilePath(
    SaveKind kind,
    String filename, {
    required bool ask,
    Directory? defaultDir,
  }) async {
    final dir = await resolveDirectory(kind, ask: ask, defaultDir: defaultDir);
    if (dir == null) {
      return null;
    }
    return '${dir.path}${Platform.pathSeparator}$filename';
  }
  
  /// Reset tracking state between tests
  void reset() {
    calls = 0;
    lastDefaultDir = null;
    lastAsk = null;
    lastKind = null;
    simulateCancel = false;
  }
}
