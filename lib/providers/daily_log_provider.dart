import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log.dart';
import '../services/daily_log_service.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import 'domain_provider.dart';
import 'progression_provider.dart';

/// State class for DailyLog management
/// Tracks today's log and provides quick access methods
class DailyLogState {
  final DailyLog? todayLog;
  final DateTime today;
  
  DailyLogState({
    this.todayLog,
    required this.today,
  });
  
  DailyLogState copyWith({
    DailyLog? todayLog,
    DateTime? today,
  }) {
    return DailyLogState(
      todayLog: todayLog ?? this.todayLog,
      today: today ?? this.today,
    );
  }
  
  /// Quick check if a task is completed today
  bool isTaskCompletedToday(String taskId) {
    return todayLog?.isTaskCompleted(taskId) ?? false;
  }
}

/// Notifier for managing DailyLog state
/// Handles daily task completion tracking and grace usage
/// 
/// Data flow:
/// 1. User toggles task -> toggleTaskCompletion called
/// 2. Update log in Hive -> Update domain strength
/// 3. Reload today's log -> UI rebuilds
class DailyLogNotifier extends Notifier<DailyLogState> {
  final DailyLogService _service = DailyLogService();
  
  @override
  DailyLogState build() {
    // Initialize with today's date and load today's log
    final today = app_date_utils.DateUtils.today;
    final todayLog = _service.getOrCreateLogForDate(today);
    return DailyLogState(
      todayLog: todayLog,
      today: today,
    );
  }
  
  /// Reload today's log from storage
  void loadTodayLog() {
    final today = app_date_utils.DateUtils.today;
    final todayLog = _service.getOrCreateLogForDate(today);
    state = state.copyWith(todayLog: todayLog, today: today);
  }
  
  /// Get log for a specific date
  DailyLog? getLogForDate(DateTime date) {
    return _service.getLogForDate(date);
  }
  
  /// Toggle task completion for today
  /// Also updates domain strength
  Future<void> toggleTaskCompletion(String taskId, String domainId) async {
    final today = state.today;
    final wasCompleted = state.isTaskCompletedToday(taskId);
    
    // Toggle completion in daily log
    await _service.toggleTaskCompletion(today, taskId);
    
    // Update domain strength
    if (wasCompleted) {
      // Task was completed, now uncompleting -> reduce strength
      ref.read(domainProvider.notifier).decrementDomainStrength(domainId);
    } else {
      // Task was not completed, now completing -> increase strength
      ref.read(domainProvider.notifier).incrementDomainStrength(domainId);
      // Award XP for task completion
      ref.read(progressionProvider.notifier).recordTaskCompleted();
    }
    
    // Reload today's log
    loadTodayLog();
  }
  
  /// Mark task as completed for today
  Future<void> completeTask(String taskId, String domainId) async {
    if (!state.isTaskCompletedToday(taskId)) {
      await _service.completeTask(state.today, taskId);
      ref.read(domainProvider.notifier).incrementDomainStrength(domainId);
      loadTodayLog();
    }
  }
  
  /// Mark task as incomplete for today
  Future<void> uncompleteTask(String taskId, String domainId) async {
    if (state.isTaskCompletedToday(taskId)) {
      await _service.uncompleteTask(state.today, taskId);
      ref.read(domainProvider.notifier).decrementDomainStrength(domainId);
      loadTodayLog();
    }
  }
  
  /// Check if task is completed on a specific date
  bool isTaskCompletedOnDate(DateTime date, String taskId) {
    return _service.isTaskCompleted(date, taskId);
  }
  
  /// Use grace for today
  /// Grace prevents streak breaks (stored as graceUsed = true in log)
  Future<void> useGraceForToday() async {
    await _service.useGrace(state.today);
    loadTodayLog();
  }
  
  /// Get count of grace tokens used this week
  int getGraceUsedThisWeek() {
    return _service.getGraceUsedThisWeek();
  }
}

/// Global provider for DailyLog state management
final dailyLogProvider = NotifierProvider<DailyLogNotifier, DailyLogState>(() {
  return DailyLogNotifier();
});
