import 'dart:math';

/// Simple unique ID generator.
/// Combines timestamp microseconds + 4 random base36 chars to reduce collision risk
/// without external dependencies.
String generateId() {
  final micros = DateTime.now().microsecondsSinceEpoch.toString();
  final rand = Random();
  const alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';
  final suffix = List.generate(4, (_) => alphabet[rand.nextInt(alphabet.length)]).join();
  return '${micros}_$suffix';
}