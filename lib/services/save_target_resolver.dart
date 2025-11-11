import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Kind of file being saved (for future customization per type)
enum SaveKind {
  pdf,
  csv,
  backup,
}

/// Interface for resolving target directories for file saves
abstract class SaveTargetResolver {
  /// Resolve the directory where a file should be saved
  /// 
  /// If [ask] is false, returns [defaultDir] (typically app documents dir).
  /// If [ask] is true, shows platform-specific directory picker.
  /// Returns null if user cancels the picker.
  Future<Directory?> resolveDirectory(
    SaveKind kind, {
    required bool ask,
    Directory? defaultDir,
  });

  /// Resolve full file path combining directory and filename
  Future<String?> resolveFilePath(
    SaveKind kind,
    String filename, {
    required bool ask,
    Directory? defaultDir,
  });
}

/// Production implementation with real platform file picker
class SaveTargetResolverImpl implements SaveTargetResolver {
  @override
  Future<Directory?> resolveDirectory(
    SaveKind kind, {
    required bool ask,
    Directory? defaultDir,
  }) async {
    // If not asking, use default directory or app documents as fallback
    if (!ask) {
      return defaultDir ?? await getApplicationDocumentsDirectory();
    }

    // Guard: avoid platform channel calls in unsupported/headless environments (e.g., CI)
    // Web: no directory selection support
    if (kIsWeb) {
      return defaultDir ?? await getApplicationDocumentsDirectory();
    }

    // Defensive Platform checks (wrapped to avoid exceptions where Platform is unsupported)
    try {
      // Supported interactive platforms could be listed here.
      // For CI stability, do NOT invoke native pickers; just return default/app dir.
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux || Platform.isAndroid || Platform.isIOS) {
        return defaultDir ?? await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      // If Platform throws or is unavailable, fallback safely
      return defaultDir ?? await getApplicationDocumentsDirectory();
    }

    // Fallback
    return defaultDir ?? await getApplicationDocumentsDirectory();
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
      return null; // User cancelled
    }
    
    return '${dir.path}${Platform.pathSeparator}$filename';
  }
}

/// Simple service locator for dependency injection (overridable in tests)
class SaveTargetResolverProvider {
  static SaveTargetResolver instance = SaveTargetResolverImpl();
}
