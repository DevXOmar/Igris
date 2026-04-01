import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:igris/models/fuel_vault_entry.dart';
import 'package:igris/services/fuel_vault_service.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    hiveTestDir = await Directory.systemTemp.createTemp('igris_fuel_vault_test_');
    Hive.init(hiveTestDir.path);

    Hive.registerAdapter(FuelVaultEntryAdapter());

    await Hive.openBox<FuelVaultEntry>('fuelVaultBox');
    await Hive.openBox('settingsBox');
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Best-effort cleanup for tests.
    }
    try {
      if (hiveTestDir.existsSync()) {
        await hiveTestDir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup for tests.
    }
  });

  test('Fuel vault entry info can be updated and cleared', () async {
    final service = FuelVaultService();

    final createdAt = DateTime(2026, 4, 1, 12, 0, 0);

    final entry = FuelVaultEntry(
      id: 'e1',
      imagePath: '/tmp/fuel.jpg',
      title: 'Old Title',
      note: 'Old Note',
      category: 'Old Category',
      createdAt: createdAt,
    );

    await service.addEntry(entry);

    final updated = FuelVaultEntry(
      id: 'e1',
      imagePath: '/tmp/fuel.jpg',
      title: null, // cleared
      note: 'New Note',
      category: null, // cleared
      createdAt: createdAt,
    );

    await service.updateEntry(updated);

    final box = Hive.box<FuelVaultEntry>('fuelVaultBox');
    final stored = box.get('e1');

    expect(stored, isNotNull);
    expect(stored!.id, 'e1');
    expect(stored.imagePath, '/tmp/fuel.jpg');
    expect(stored.createdAt, createdAt);

    expect(stored.title, isNull);
    expect(stored.note, 'New Note');
    expect(stored.category, isNull);
  });
}
