import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// State class for Grace token management
/// Tracks weekly grace tokens and reset timing
class GraceState {
  final int weeklyGraceLeft;
  final int maxGraceTokens;
  final DateTime? lastResetDate;
  
  GraceState({
    required this.weeklyGraceLeft,
    required this.maxGraceTokens,
    this.lastResetDate,
  });
  
  GraceState copyWith({
    int? weeklyGraceLeft,
    int? maxGraceTokens,
    DateTime? lastResetDate,
  }) {
    return GraceState(
      weeklyGraceLeft: weeklyGraceLeft ?? this.weeklyGraceLeft,
      maxGraceTokens: maxGraceTokens ?? this.maxGraceTokens,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
  
  /// Check if any grace tokens are available
  bool get hasGraceAvailable => weeklyGraceLeft > 0;
}

/// Notifier for managing Grace token system
/// Handles weekly grace tokens that prevent streak breaks
/// 
/// How weekly reset works:
/// 1. On app start, check if 7+ days have passed since last reset
/// 2. If yes, reset weeklyGraceLeft to max (2) and update lastResetDate
/// 3. Grace tokens are stored in settingsBox (persistent across sessions)
/// 4. Using a grace token: decrements weeklyGraceLeft, marks that day's log as graceUsed
/// 
/// Data flow:
/// Settings Service (Hive) <-> Grace Notifier <-> UI
class GraceNotifier extends Notifier<GraceState> {
  final SettingsService _service = SettingsService();
  
  @override
  GraceState build() {
    // Initialize on first build
    _initializeAndCheckReset();
    
    return GraceState(
      weeklyGraceLeft: _service.getRemainingGraceTokens(),
      maxGraceTokens: _service.getMaxGraceTokens(),
      lastResetDate: _service.getLastResetDate(),
    );
  }
  
  /// Initialize settings and check if weekly reset is needed
  /// Called automatically on provider creation
  Future<void> _initializeAndCheckReset() async {
    await _service.initialize();
    await checkAndResetWeekly();
  }
  
  /// Check if weekly reset is needed and perform it
  /// Weekly reset: Every 7 days, grace tokens reset to max (2)
  Future<void> checkAndResetWeekly() async {
    if (_service.needsWeeklyReset()) {
      await _service.performWeeklyReset();
      _loadState();
    }
  }
  
  /// Reload state from settings service
  void _loadState() {
    state = GraceState(
      weeklyGraceLeft: _service.getRemainingGraceTokens(),
      maxGraceTokens: _service.getMaxGraceTokens(),
      lastResetDate: _service.getLastResetDate(),
    );
  }
  
  /// Use a grace token
  /// Returns true if successfully used, false if none available
  /// Grace usage prevents streak breaks - user can miss a day without penalty
  Future<bool> useGraceToken() async {
    final success = await _service.useGraceToken();
    if (success) {
      _loadState();
      return true;
    }
    return false;
  }
  
  /// Manually trigger weekly reset (for testing/admin)
  Future<void> forceWeeklyReset() async {
    await _service.performWeeklyReset();
    _loadState();
  }
  
  /// Get the number of days until next reset
  int getDaysUntilReset() {
    final lastReset = state.lastResetDate;
    if (lastReset == null) return 0;
    
    final now = DateTime.now();
    final daysSinceReset = now.difference(lastReset).inDays;
    final daysUntilReset = 7 - daysSinceReset;
    
    return daysUntilReset > 0 ? daysUntilReset : 0;
  }
}

/// Global provider for Grace token state management
/// Access in UI with: ref.watch(graceProvider) or ref.read(graceProvider.notifier)
final graceProvider = NotifierProvider<GraceNotifier, GraceState>(() {
  return GraceNotifier();
});
