import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
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
    // If not asking, use default directory
    if (!ask) {
      return defaultDir ?? await getApplicationDocumentsDirectory();
    }

    // Platform-specific picker behavior
    if (kIsWeb) {
      // Web doesn't support directory selection
      return defaultDir ?? await getApplicationDocumentsDirectory();
    }

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: use file_selector directory picker
      final String? directoryPath = await getDirectoryPath(
        confirmButtonText: 'Select',
      );
      
      if (directoryPath == null) {
        // User cancelled
        return null;
      }
      
      return Directory(directoryPath);
    } else if (Platform.isAndroid) {
      // Android: MVP - use app dir
      // TODO(#29): Implement SAF (Storage Access Framework) for user-selected directories
      return defaultDir ?? await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // iOS: sandboxed, use app dir
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
