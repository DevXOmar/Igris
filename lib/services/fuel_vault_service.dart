import 'package:hive/hive.dart';

import '../models/fuel_vault_entry.dart';

/// Hive-backed storage for Fuel Vault entries + PIN management.
class FuelVaultService {
  static const String _boxName = 'fuelVaultBox';
  static const String _settingsBoxName = 'settingsBox';

  /// Migration flag: clears legacy asset-path seeded entries on first V2 launch.
  static const String _migrationKey = 'fuelVaultV2';
  static const String _pinKey = 'vaultPin';

  Box<FuelVaultEntry> get _box => Hive.box<FuelVaultEntry>(_boxName);
  Box get _settingsBox => Hive.box(_settingsBoxName);

  /// Clears any legacy asset-path-based entries from V1 on first V2 launch.
  Future<void> migrateIfNeeded() async {
    if (_settingsBox.get(_migrationKey) == true) return;
    await _box.clear();
    await _settingsBox.put(_migrationKey, true);
  }

  List<FuelVaultEntry> getAllEntries() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> addEntry(FuelVaultEntry entry) async {
    await _box.put(entry.id, entry);
  }

  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  // ── PIN management ─────────────────────────────────────────────────────────

  bool get isPinSet => _settingsBox.get(_pinKey) != null;

  bool verifyPin(String pin) => _settingsBox.get(_pinKey) == pin;

  Future<void> setPin(String pin) async {
    await _settingsBox.put(_pinKey, pin);
  }
}
