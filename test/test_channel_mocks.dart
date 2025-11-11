import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock file_selector MethodChannel to prevent real platform calls in tests
Future<void> mockFileSelectorChannel() async {
  const channel = MethodChannel('plugins.flutter.io/file_selector');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    // Simulate user cancelling the picker (return null)
    // This prevents hangs from awaiting real platform response
    return null;
  });
}

/// Mock path_provider channels to prevent real platform calls
Future<void> mockPathProviderChannels() async {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    // Return fake paths for common path_provider methods
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
        return '/fake/app/documents';
      case 'getTemporaryDirectory':
        return '/fake/temp';
      case 'getDownloadsDirectory':
        return '/fake/downloads';
      default:
        return null;
    }
  });
}

/// Mock all common platform channels used in the app
Future<void> mockAllPlatformChannels() async {
  await mockFileSelectorChannel();
  await mockPathProviderChannels();
}
