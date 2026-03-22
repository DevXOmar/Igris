import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import '../services/domain_progress_service.dart';
import 'domain_provider.dart';
import 'task_provider.dart';
import 'daily_log_provider.dart';

/// Weekly statistics model
class WeeklyStats {
  final Map<Domain, double> weeklyProgress; // 0.0 to 1.0 for each domain
  final double weeklyScore; // 0.0 to 100.0
  final int currentStreak; // Number of consecutive days meeting criteria
  final int totalTasksThisWeek;
  final int completedTasksThisWeek;
  
  WeeklyStats({
    required this.weeklyProgress,
    required this.weeklyScore,
    required this.currentStreak,
    required this.totalTasksThisWeek,
    required this.completedTasksThisWeek,
  });
}

/// Provider for weekly statistics
/// Calculates weekly progress, score, and streak
/// 
/// Formula:
/// - W_start = Monday 00:00
/// - W_end = Sunday 23:59
/// - ExpectedSoFar = Count of task instances expected from Monday..today
/// - CompletedSoFar = Count of completed task instances from Monday..today
/// - WeeklyScore = (CompletedSoFar / ExpectedSoFar) * 100
/// 
/// This makes progress *workload fair* - bars reflect "weekly progress (so far)"
/// instead of assuming evenly distributed daily work.
final weeklyStatsProvider = Provider<WeeklyStats>((ref) {
  final domainState = ref.watch(domainProvider);
  final taskState = ref.watch(taskProvider);
  // Depend on daily log state so weekly stats recompute when tasks are toggled.
  ref.watch(dailyLogProvider);
  final logNotifier = ref.watch(dailyLogProvider.notifier);
  
  final today = app_date_utils.DateUtils.today;
  final progressService = DomainProgressService(
    tasks: taskState.tasks,
    getLogForDate: logNotifier.getLogForDate,
    now: today,
  );
  
  // Calculate weekly progress for each domain
  final weeklyProgress = <Domain, double>{};
  int totalTasksThisWeek = 0;
  int completedTasksThisWeek = 0;
  
  // For each active domain, calculate weekly progress
  for (final domain in domainState.activeDomains) {
    final domainTasks = taskState.tasks.where((task) => task.domainId == domain.id).toList();
    
    if (domainTasks.isEmpty) {
      weeklyProgress[domain] = 0.0;
      continue;
    }

    // Count expected/completed occurrences *so far* (Mon..today).
    var domainExpectedSoFar = 0;
    var domainCompletedSoFar = 0;
    for (final task in domainTasks) {
      domainExpectedSoFar += progressService.getExpectedOccurrences(task, today);
      domainCompletedSoFar += progressService.getCompletedOccurrences(task, today);
    }

    totalTasksThisWeek += domainExpectedSoFar;
    completedTasksThisWeek += domainCompletedSoFar;

    final progress = domainExpectedSoFar > 0
        ? (domainCompletedSoFar / domainExpectedSoFar).clamp(0.0, 1.0)
        : 0.0;
    weeklyProgress[domain] = progress;
  }
  
  // Calculate weekly score against expected-so-far total
  final weeklyScore = totalTasksThisWeek > 0 
      ? (completedTasksThisWeek / totalTasksThisWeek) * 100 
      : 0.0;
  
  // Calculate current streak
  final streak = _calculateStreak(ref, today, taskState, logNotifier);
  
  return WeeklyStats(
    weeklyProgress: weeklyProgress,
    weeklyScore: weeklyScore,
    currentStreak: streak,
    totalTasksThisWeek: totalTasksThisWeek,
    completedTasksThisWeek: completedTasksThisWeek,
  );
});

/// Calculate current streak
/// A day counts toward streak if:
/// - Daily completion >= 70% OR
/// - Grace was used
int _calculateStreak(
  Ref ref,
  DateTime today,
  TaskState taskState,
  DailyLogNotifier logNotifier,
) {
  int streak = 0;
  DateTime checkDate = today;
  
  final domainState = ref.watch(domainProvider);

  // If there are no active tasks at all, streak is defined as 0.
  final activeTasks = taskState.tasks.where((task) {
    final domain = domainState.getDomainById(task.domainId);
    return domain != null && domain.isActive;
  }).toList(growable: false);

  if (activeTasks.isEmpty) return 0;

  // Safety net: prevent unbounded lookback (e.g., malformed data).
  const int maxLookbackDays = 3660; // ~10 years
  var lookedBack = 0;
  
  // Go backwards from today, counting consecutive days that meet criteria
  while (true) {
    if (lookedBack++ >= maxLookbackDays) break;
    // Currently, tasks are treated as scheduled daily for active domains.
    // If scheduling is added later, replace this with per-date logic.
    final allTodayTasks = activeTasks;

    final log = logNotifier.getLogForDate(checkDate);

    // Check if grace was used this day.
    if (log?.graceUsed == true) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      continue;
    }
    
    final completedCount = allTodayTasks.where((task) => 
      log?.isTaskCompleted(task.id) ?? false
    ).length;
    
    final completionPercentage = (completedCount / allTodayTasks.length) * 100;
    
    // Check if completion is >= 70%
    if (completionPercentage >= 70.0) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // Streak ends
      break;
    }
  }
  
  return streak;
}
