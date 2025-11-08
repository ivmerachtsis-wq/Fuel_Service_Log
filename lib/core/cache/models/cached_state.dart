/// Persistent snapshot state for fast cold-start hydration.
class CachedState {
  final int schemaVersion;
  final DateTime generatedAt;
  final String appVersion;
  final Map<String, BoxSnapshot> boxes;

  const CachedState({
    required this.schemaVersion,
    required this.generatedAt,
    required this.appVersion,
    required this.boxes,
  });

  factory CachedState.fromJson(Map<String, dynamic> json) {
    return CachedState(
      schemaVersion: json['schemaVersion'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      appVersion: json['appVersion'] as String,
      boxes: (json['boxes'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, BoxSnapshot.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'generatedAt': generatedAt.toIso8601String(),
      'appVersion': appVersion,
      'boxes': boxes.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}

/// Snapshot of a single Hive box.
class BoxSnapshot {
  final int revision;
  final String checksum;
  final List<Map<String, dynamic>> items;

  const BoxSnapshot({
    required this.revision,
    required this.checksum,
    required this.items,
  });

  factory BoxSnapshot.fromJson(Map<String, dynamic> json) {
    return BoxSnapshot(
      revision: json['revision'] as int,
      checksum: json['checksum'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revision': revision,
      'checksum': checksum,
      'items': items,
    };
  }
}
