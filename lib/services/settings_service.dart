import 'package:hive/hive.dart';

/// Service for managing app settings in Hive
/// Handles grace system settings and other app configurations
class SettingsService {
  static const String _boxName = 'settingsBox';
  static const String _lastResetKey = 'lastWeeklyReset';
  static const String _graceTokensKey = 'remainingGraceTokens';
  static const int _maxGraceTokens = 2;
  
  /// Get the settings box
  Box get _box => Hive.box(_boxName);
  
  /// Get last weekly reset date
  DateTime? getLastResetDate() {
    final timestamp = _box.get(_lastResetKey) as String?;
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }
  
  /// Set last weekly reset date
  Future<void> setLastResetDate(DateTime date) async {
    await _box.put(_lastResetKey, date.toIso8601String());
  }
  
  /// Get remaining grace tokens
  int getRemainingGraceTokens() {
    return _box.get(_graceTokensKey, defaultValue: _maxGraceTokens) as int;
  }
  
  /// Set remaining grace tokens
  Future<void> setRemainingGraceTokens(int count) async {
    await _box.put(_graceTokensKey, count);
  }
  
  /// Use a grace token
  Future<bool> useGraceToken() async {
    final remaining = getRemainingGraceTokens();
    if (remaining > 0) {
      await setRemainingGraceTokens(remaining - 1);
      return true;
    }
    return false;
  }
  
  /// Check if weekly reset is needed
  bool needsWeeklyReset() {
    final lastReset = getLastResetDate();
    if (lastReset == null) return true;
    
    final now = DateTime.now();
    final daysSinceReset = now.difference(lastReset).inDays;
    
    // Reset weekly (7 days)
    return daysSinceReset >= 7;
  }
  
  /// Perform weekly reset of grace tokens
  Future<void> performWeeklyReset() async {
    await setRemainingGraceTokens(_maxGraceTokens);
    await setLastResetDate(DateTime.now());
  }
  
  /// Auto-check and perform weekly reset if needed
  Future<void> checkAndResetWeekly() async {
    if (needsWeeklyReset()) {
      await performWeeklyReset();
    }
  }
  
  /// Get max grace tokens
  int getMaxGraceTokens() {
    return _maxGraceTokens;
  }
  
  /// Initialize settings on first run
  Future<void> initialize() async {
    if (getLastResetDate() == null) {
      await performWeeklyReset();
    }
  }
  
  /// Clear all settings (for testing/reset)
  Future<void> clearAll() async {
    await _box.clear();
  }
}
