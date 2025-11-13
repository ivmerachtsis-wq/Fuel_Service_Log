import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_service_log/data/models/vehicle.dart';
import 'package:fuel_service_log/data/repo/vehicle_repo.dart';

void main() {
  late VehicleRepo repo;
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    
    // Initialize Hive with temp directory
    Hive.init(tempDir.path);
    
    // Register Vehicle adapter
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(VehicleAdapter());
    }
    
    // Open the vehicles box (VehicleRepo expects this name)
    await Hive.openBox<Vehicle>('vehicles');
    repo = VehicleRepo();
  });

  tearDown(() async {
    // Close all boxes
    await Hive.close();
    
    // Delete temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VehicleRepo CRUD Operations', () {
    test('add() creates a new vehicle with currencyCode', () async {
      final vehicle = Vehicle(
        id: 'v1',
        title: 'Test Car',
        plate: 'ABC-1234',
        currencyCode: 'EUR',
      );

      await repo.add(vehicle);

      final retrieved = repo.getById('v1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Test Car');
      expect(retrieved.plate, 'ABC-1234');
      expect(retrieved.currencyCode, 'EUR');
      expect(retrieved.active, true);
    });

    test('add() vehicle without currencyCode (backward compatibility)', () async {
      final vehicle = Vehicle(
        id: 'v2',
        title: 'Legacy Car',
      );

      await repo.add(vehicle);

      final retrieved = repo.getById('v2');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Legacy Car');
      expect(retrieved.currencyCode, isNull);
    });

    test('update() modifies existing vehicle including currencyCode', () async {
      final vehicle = Vehicle(
        id: 'v3',
        title: 'Original Name',
        currencyCode: 'USD',
      );
      await repo.add(vehicle);

      vehicle.title = 'Updated Name';
      vehicle.plate = 'XYZ-9999';
      vehicle.currencyCode = 'GBP';
      await repo.update(vehicle);

      final retrieved = repo.getById('v3');
      expect(retrieved!.title, 'Updated Name');
      expect(retrieved.plate, 'XYZ-9999');
      expect(retrieved.currencyCode, 'GBP');
    });

    test('delete() removes vehicle from storage', () async {
      final vehicle = Vehicle(
        id: 'v4',
        title: 'To Delete',
        currencyCode: 'EUR',
      );
      await repo.add(vehicle);

      await repo.delete('v4');

      final retrieved = repo.getById('v4');
      expect(retrieved, isNull);
    });

    test('listAll() returns all vehicles with currencyCode', () async {
      final v1 = Vehicle(id: 'v5', title: 'Car 1', currencyCode: 'EUR');
      final v2 = Vehicle(id: 'v6', title: 'Car 2', currencyCode: 'USD');
      final v3 = Vehicle(id: 'v7', title: 'Car 3');
      
      await repo.add(v1);
      await repo.add(v2);
      await repo.add(v3);

      final all = repo.listAll();
      expect(all.length, greaterThanOrEqualTo(3));
      
      final ids = all.map((v) => v.id).toList();
      expect(ids, containsAll(['v5', 'v6', 'v7']));
    });

    test('listActive() returns only active vehicles', () async {
      final v1 = Vehicle(id: 'v8', title: 'Active Car', active: true, currencyCode: 'EUR');
      final v2 = Vehicle(id: 'v9', title: 'Inactive Car', active: false, currencyCode: 'USD');
      
      await repo.add(v1);
      await repo.add(v2);

      final active = repo.listActive();
      final activeIds = active.map((v) => v.id).toList();
      
      expect(activeIds, contains('v8'));
      expect(activeIds, isNot(contains('v9')));
    });

    test('watchAll() stream emits updates on add/update/delete', () async {
      final stream = repo.watchAll();
      final events = <List<Vehicle>>[];
      
      final subscription = stream.listen(events.add);

      // Wait for initial emission
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Add vehicle
      final v1 = Vehicle(id: 'v10', title: 'Stream Test', currencyCode: 'EUR');
      await repo.add(v1);
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Update vehicle
      v1.title = 'Stream Test Updated';
      await repo.update(v1);
      await Future.delayed(const Duration(milliseconds: 200));
      
      await subscription.cancel();
      
      // Verify we got at least initial + add + update = 3 events
      expect(events.length, greaterThanOrEqualTo(3));
      final lastEvent = events.last;
      final found = lastEvent.firstWhere((v) => v.id == 'v10', orElse: () => Vehicle(id: '', title: ''));
      expect(found.title, 'Stream Test Updated');
      expect(found.currencyCode, 'EUR');
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
