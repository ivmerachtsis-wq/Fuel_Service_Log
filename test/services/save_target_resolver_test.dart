import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:fuel_service_log/services/save_target_resolver.dart';
import '../fakes/fake_save_target_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveTargetResolver (Fake)', () {
    late FakeSaveTargetResolver fake;

    setUp(() {
      fake = FakeSaveTargetResolver();
      SaveTargetResolverProvider.instance = fake;
      fake.reset();
    });

    test('resolveDirectory with ask=false returns default dir', () async {
      final defaultDir = Directory('/test/default');
      final result = await SaveTargetResolverProvider.instance.resolveDirectory(
        SaveKind.pdf,
        ask: false,
        defaultDir: defaultDir,
      );
      expect(result, equals(defaultDir));
      expect(fake.calls, 1);
    });

    test('resolveDirectory with ask=false and no defaultDir returns app documents', () async {
      final result = await SaveTargetResolverProvider.instance.resolveDirectory(
        SaveKind.csv,
        ask: false,
      );
      expect(result, isNotNull);
      // Fake returns systemTemp by default
      expect(result!.path, equals(Directory.systemTemp.path));
      expect(fake.calls, 1);
    });

    test('resolveFilePath with ask=false combines directory and filename', () async {
      final defaultDir = Directory('/test/export');
      final result = await SaveTargetResolverProvider.instance.resolveFilePath(
        SaveKind.backup,
        'backup_2024.json',
        ask: false,
        defaultDir: defaultDir,
      );

      expect(result, isNotNull);
      final expected = p.join(defaultDir.path, 'backup_2024.json');
      expect(result, equals(expected));
    });

    test('resolveFilePath uses platform path separator', () async {
      final defaultDir = Directory('/test');
      final result = await SaveTargetResolverProvider.instance.resolveFilePath(
        SaveKind.pdf,
        'report.pdf',
        ask: false,
        defaultDir: defaultDir,
      );

      expect(result, isNotNull);
      final expected = p.join(defaultDir.path, 'report.pdf');
      expect(result, equals(expected));
    });

    test('Different SaveKind values work correctly', () async {
      final dir = Directory('/test');
      
      for (final kind in SaveKind.values) {
        final result = await SaveTargetResolverProvider.instance.resolveDirectory(
          kind,
          ask: false,
          defaultDir: dir,
        );
        
        expect(result, equals(dir), reason: 'Failed for kind: $kind');
      }
    });

    test('resolveDirectory ask=true still returns fake directory (simulating selection)', () async {
      final result = await SaveTargetResolverProvider.instance.resolveDirectory(
        SaveKind.pdf,
        ask: true,
        defaultDir: Directory('/fallback'),
      );
      expect(result, isNotNull);
      expect(result!.path, equals(Directory.systemTemp.path));
      expect(fake.calls, 1);
    });

    test('resolveDirectory ask=true simulate cancel returns null', () async {
      fake.simulateCancel = true;
      final result = await SaveTargetResolverProvider.instance.resolveDirectory(
        SaveKind.csv,
        ask: true,
        defaultDir: Directory('/fallback'),
      );
      expect(result, isNull);
      expect(fake.calls, 1);
    });
  });
}
