import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fuel_vault_entry.dart';
import '../services/fuel_vault_service.dart';

class FuelVaultState {
  final List<FuelVaultEntry> entries;

  /// True when the user has successfully authenticated during this session.
  final bool isUnlocked;

  /// True when a vault PIN has been set (persisted in Hive settingsBox).
  final bool isPinSet;

  const FuelVaultState({
    required this.entries,
    this.isUnlocked = false,
    required this.isPinSet,
  });

  FuelVaultState copyWith({
    List<FuelVaultEntry>? entries,
    bool? isUnlocked,
    bool? isPinSet,
  }) {
    return FuelVaultState(
      entries: entries ?? this.entries,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isPinSet: isPinSet ?? this.isPinSet,
    );
  }
}

class FuelVaultNotifier extends Notifier<FuelVaultState> {
  final FuelVaultService _service = FuelVaultService();

  @override
  FuelVaultState build() {
    // Run V2 migration once (clears old asset-path seeds).
    Future.microtask(() async {
      await _service.migrateIfNeeded();
      _reload();
    });

    return FuelVaultState(
      entries: _service.getAllEntries(),
      isPinSet: _service.isPinSet,
    );
  }

  void _reload() {
    state = state.copyWith(
      entries: _service.getAllEntries(),
      isPinSet: _service.isPinSet,
    );
  }

  // ── Session auth ────────────────────────────────────────────────────────────

  void unlock() => state = state.copyWith(isUnlocked: true);
  void lock() => state = state.copyWith(isUnlocked: false);

  bool verifyPin(String pin) => _service.verifyPin(pin);

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    _reload();
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addEntry(FuelVaultEntry entry) async {
    await _service.addEntry(entry);
    _reload();
  }

  Future<void> updateEntry(FuelVaultEntry entry) async {
    await _service.updateEntry(entry);
    _reload();
  }

  Future<void> deleteEntry(String id) async {
    await _service.deleteEntry(id);
    _reload();
  }
}

final fuelVaultProvider = NotifierProvider<FuelVaultNotifier, FuelVaultState>(() {
  return FuelVaultNotifier();
});
