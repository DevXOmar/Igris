import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import '../services/daily_log_service.dart';
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
  final DailyLogService _dailyLogService = DailyLogService();
  
  @override
  GraceState build() {
    // Initialize on first build
    _initializeAndCheckReset();

    final maxTokens = _service.getMaxGraceTokens();
    final usedThisWeek = _dailyLogService.getGraceUsedThisWeek();
    final weeklyLeft = (maxTokens - usedThisWeek).clamp(0, maxTokens);
    
    return GraceState(
      weeklyGraceLeft: weeklyLeft,
      maxGraceTokens: maxTokens,
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
    final maxTokens = _service.getMaxGraceTokens();
    final usedThisWeek = _dailyLogService.getGraceUsedThisWeek();
    final weeklyLeft = (maxTokens - usedThisWeek).clamp(0, maxTokens);

    // Keep the persisted counter in sync so Settings UI stays consistent.
    // (Source of truth for weekly usage is DailyLog.graceUsed within the week.)
    if (_service.getRemainingGraceTokens() != weeklyLeft) {
      // Fire-and-forget; state below is already correct.
      // ignore: discarded_futures
      _service.setRemainingGraceTokens(weeklyLeft);
    }

    state = GraceState(
      weeklyGraceLeft: weeklyLeft,
      maxGraceTokens: maxTokens,
      lastResetDate: _service.getLastResetDate(),
    );
  }
  
  /// Use a grace token
  /// Returns true if successfully used, false if none available
  /// Grace usage prevents streak breaks - user can miss a day without penalty
  Future<bool> useGraceToken() async {
    // Backward-compatible wrapper; prefer applyGraceForToday().
    final today = app_date_utils.DateUtils.today;
    return applyGraceForDate(today);
  }

  /// Apply grace to a specific date (typically today).
  ///
  /// Enforces max 2 grace uses per week by counting [DailyLog.graceUsed]
  /// inside the current week window.
  Future<bool> applyGraceForDate(DateTime date) async {
    await _service.initialize();
    await checkAndResetWeekly();

    final existing = _dailyLogService.getLogForDate(date);
    if (existing?.graceUsed == true) {
      _loadState();
      return true;
    }

    final maxTokens = _service.getMaxGraceTokens();
    final usedThisWeek = _dailyLogService.getGraceUsedThisWeek();
    if (usedThisWeek >= maxTokens) {
      _loadState();
      return false;
    }

    await _dailyLogService.useGrace(date);
    _loadState();
    return true;
  }
  
  /// Manually trigger weekly reset (for testing/admin)
  Future<void> forceWeeklyReset() async {
    await _service.performWeeklyReset();
    _loadState();
  }
  
  /// Get the number of days until next reset
  int getDaysUntilReset() {
    // Grace resets on the next Monday (start of next week).
    final today = app_date_utils.DateUtils.today;
    final startOfThisWeek = app_date_utils.DateUtils.getStartOfWeek(today);
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    final days = startOfNextWeek.difference(today).inDays;
    return days < 0 ? 0 : days;
  }
}

/// Global provider for Grace token state management
/// Access in UI with: ref.watch(graceProvider) or ref.read(graceProvider.notifier)
final graceProvider = NotifierProvider<GraceNotifier, GraceState>(() {
  return GraceNotifier();
});
