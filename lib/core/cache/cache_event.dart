/// Cache invalidation events for L1/L2 coordination.
class CacheEvent {
  final String boxName;
  final dynamic key;
  final String? vehicleId;
  final CacheEventType type;

  const CacheEvent({
    required this.boxName,
    required this.type,
    this.key,
    this.vehicleId,
  });

  factory CacheEvent.changed(String boxName, dynamic key, {String? vehicleId}) {
    return CacheEvent(
      boxName: boxName,
      type: CacheEventType.changed,
      key: key,
      vehicleId: vehicleId,
    );
  }

  factory CacheEvent.deleted(String boxName, dynamic key, {String? vehicleId}) {
    return CacheEvent(
      boxName: boxName,
      type: CacheEventType.deleted,
      key: key,
      vehicleId: vehicleId,
    );
  }

  factory CacheEvent.cleared(String boxName) {
    return CacheEvent(
      boxName: boxName,
      type: CacheEventType.cleared,
    );
  }

  @override
  String toString() =>
      'CacheEvent(type: $type, box: $boxName, key: $key, vehicleId: $vehicleId)';
}

enum CacheEventType {
  changed,
  deleted,
  cleared,
}
