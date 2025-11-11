import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_service_log/services/save_target_resolver.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/mock/app/documents';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveTargetResolver', () {
    late SaveTargetResolver resolver;

    setUp(() {
      resolver = SaveTargetResolverImpl();
      // Register mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();
    });

    test('resolveDirectory with ask=false returns default dir', () async {
      final defaultDir = Directory('/test/default');
      final result = await resolver.resolveDirectory(
        SaveKind.pdf,
        ask: false,
        defaultDir: defaultDir,
      );

      expect(result, equals(defaultDir));
    });

    test('resolveDirectory with ask=false and no defaultDir returns app documents', () async {
      final result = await resolver.resolveDirectory(
        SaveKind.csv,
        ask: false,
      );

      expect(result, isNotNull);
      expect(result!.path, equals('/mock/app/documents'));
    });

    test('resolveFilePath with ask=false combines directory and filename', () async {
      final defaultDir = Directory('/test/export');
      final result = await resolver.resolveFilePath(
        SaveKind.backup,
        'backup_2024.json',
        ask: false,
        defaultDir: defaultDir,
      );

      expect(result, isNotNull);
      expect(result, contains('/test/export'));
      expect(result, contains('backup_2024.json'));
    });

    test('resolveFilePath uses platform path separator', () async {
      final defaultDir = Directory('/test');
      final result = await resolver.resolveFilePath(
        SaveKind.pdf,
        'report.pdf',
        ask: false,
        defaultDir: defaultDir,
      );

      expect(result, isNotNull);
      // Should use platform-specific separator
      expect(result, matches(RegExp(r'/test[/\\]report\.pdf')));
    });

    test('Different SaveKind values work correctly', () async {
      final dir = Directory('/test');
      
      for (final kind in SaveKind.values) {
        final result = await resolver.resolveDirectory(
          kind,
          ask: false,
          defaultDir: dir,
        );
        
        expect(result, equals(dir), reason: 'Failed for kind: $kind');
      }
    });

    // Note: Testing with ask=true requires mocking file_selector 
    // which shows native dialogs. For MVP, we skip interactive tests.
    test('TODO: Test with ask=true requires file_selector mock', () {
      // This is a placeholder for future integration with file_selector mocks
      // For now, manual testing on Windows/Android is required
    });
  });
}
