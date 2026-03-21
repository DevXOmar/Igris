import 'package:hive/hive.dart';
import '../models/daily_log.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

/// Service for managing DailyLog data in Hive
class DailyLogService {
  static const String _boxName = 'dailyLogsBox';
  
  /// Get the daily logs box
  Box<DailyLog> get _box => Hive.box<DailyLog>(_boxName);
  
  /// Get all daily logs
  List<DailyLog> getAllLogs() {
    return _box.values.toList();
  }
  
  /// Get log for a specific date
  DailyLog? getLogForDate(DateTime date) {
    final key = app_date_utils.DateUtils.getDateKey(date);
    return _box.get(key);
  }
  
  /// Get or create log for a specific date
  DailyLog getOrCreateLogForDate(DateTime date) {
    final log = getLogForDate(date);
    if (log != null) {
      return log;
    }
    
    // Create new log for this date
    final newLog = DailyLog(
      date: date,
      completedTaskIds: [],
      graceUsed: false,
    );
    return newLog;
  }
  
  /// Save a daily log
  Future<void> saveLog(DailyLog log) async {
    final key = app_date_utils.DateUtils.getDateKey(log.date);
    await _box.put(key, log);
  }
  
  /// Toggle task completion for a date
  Future<void> toggleTaskCompletion(DateTime date, String taskId) async {
    final log = getOrCreateLogForDate(date);
    
    if (log.isTaskCompleted(taskId)) {
      log.removeCompletedTask(taskId);
    } else {
      log.addCompletedTask(taskId);
    }
    
    await saveLog(log);
  }

  /// Marks [taskId] as having granted rewards for [date].
  ///
  /// Returns true if this is the first time the reward is granted for this
  /// task on this day, otherwise false.
  Future<bool> markTaskRewarded(DateTime date, String taskId) async {
    final log = getOrCreateLogForDate(date);
    final already = log.hasGrantedRewardForTask(taskId);
    if (already) return false;

    final updated = log.copyWith(
      rewardedTaskIds: [...log.rewardedTaskIds, taskId],
    );
    await saveLog(updated);
    return true;
  }
  
  /// Mark task as completed for a date
  Future<void> completeTask(DateTime date, String taskId) async {
    final log = getOrCreateLogForDate(date);
    log.addCompletedTask(taskId);
    await saveLog(log);
  }
  
  /// Mark task as incomplete for a date
  Future<void> uncompleteTask(DateTime date, String taskId) async {
    final log = getOrCreateLogForDate(date);
    log.removeCompletedTask(taskId);
    await saveLog(log);
  }
  
  /// Check if a task is completed on a date
  bool isTaskCompleted(DateTime date, String taskId) {
    final log = getLogForDate(date);
    return log?.isTaskCompleted(taskId) ?? false;
  }
  
  /// Use grace for a date
  Future<void> useGrace(DateTime date) async {
    final log = getOrCreateLogForDate(date);
    final updated = log.copyWith(graceUsed: true);
    await saveLog(updated);
  }
  
  /// Get logs for current week
  List<DailyLog> getCurrentWeekLogs() {
    final today = app_date_utils.DateUtils.today;
    return getWeekLogsForDate(today);
  }

  /// Get logs for the week containing [date] (Monday → Sunday).
  List<DailyLog> getWeekLogsForDate(DateTime date) {
    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(date);
    
    final logs = <DailyLog>[];
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final log = getLogForDate(date);
      if (log != null) {
        logs.add(log);
      }
    }
    
    return logs;
  }
  
  /// Count grace tokens used this week
  int getGraceUsedThisWeek() {
    final weekLogs = getCurrentWeekLogs();
    return weekLogs.where((log) => log.graceUsed).length;
  }

  /// Count grace tokens used in the week containing [date].
  int getGraceUsedInWeek(DateTime date) {
    final weekLogs = getWeekLogsForDate(date);
    return weekLogs.where((log) => log.graceUsed).length;
  }
  
  /// Clear all logs (for testing/reset)
  Future<void> clearAll() async {
    await _box.clear();
  }
}
