import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
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
/// - TotalWeeklyTasks = Count of all task instances for ENTIRE week (all 7 days)
/// - CompletedWeeklyTasks = Count of completed task instances up to today
/// - WeeklyScore = (CompletedWeeklyTasks / TotalWeeklyTasks) * 100
/// 
/// This makes progress cumulative - bars gradually fill as you complete tasks
/// throughout the week, reaching 100% only when all tasks are done all 7 days
final weeklyStatsProvider = Provider<WeeklyStats>((ref) {
  final domainState = ref.watch(domainProvider);
  final taskState = ref.watch(taskProvider);
  final logNotifier = ref.watch(dailyLogProvider.notifier);
  
  final today = app_date_utils.DateUtils.today;
  final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);
  
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
    
    // Count TOTAL task instances for ENTIRE WEEK (all 7 days)
    // This is the denominator - it doesn't change as the week progresses
    final domainTotalForWeek = domainTasks.length * 7;
    int domainCompletedThisWeek = 0;
    
    print('\n=== ${domain.name} ===');
    print('Tasks in domain: ${domainTasks.length}');
    print('TotalScheduledInstancesThisWeek: $domainTotalForWeek (${domainTasks.length} tasks × 7 days)');
    
    // Count completed tasks from Monday through today
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      
      // Count all tasks for the full week (for total)
      // But only count completions up to today
      if (date.isAfter(today)) {
        // Don't count completions for future days, but still need to count
        // these tasks toward total
        continue;
      }
      
      // Get log for this date
      final log = logNotifier.getLogForDate(date);
      
      // Count completions for this day
      for (final task in domainTasks) {
        if (log != null && log.isTaskCompleted(task.id)) {
          domainCompletedThisWeek++;
          completedTasksThisWeek++;
        }
      }
    }
    
    print('CompletedInstancesThisWeek: $domainCompletedThisWeek');
    
    // Add this domain's total to overall total
    totalTasksThisWeek += domainTotalForWeek;
    
    // Calculate progress as percentage against FULL WEEK
    final progress = domainTotalForWeek > 0 
        ? domainCompletedThisWeek / domainTotalForWeek 
        : 0.0;
    weeklyProgress[domain] = progress;
    print('Progress: ${(progress * 100).toStringAsFixed(1)}% ($domainCompletedThisWeek/$domainTotalForWeek)');
  }
  
  // Calculate weekly score against FULL WEEK total
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
  
  // Go backwards from today, counting consecutive days that meet criteria
  while (true) {
    final log = logNotifier.getLogForDate(checkDate);
    
    // If no log exists for this date, streak ends
    if (log == null) break;
    
    // Check if grace was used this day
    if (log.graceUsed) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      continue;
    }
    
    // Calculate daily completion percentage
    // Get all tasks from active domains that should be done on this date
    final allTodayTasks = taskState.tasks.where((task) {
      final domain = domainState.getDomainById(task.domainId);
      return domain != null && domain.isActive;
    }).toList();
    
    if (allTodayTasks.isEmpty) {
      // No tasks for this day - don't count it but don't break streak either
      checkDate = checkDate.subtract(const Duration(days: 1));
      continue;
    }
    
    final completedCount = allTodayTasks.where((task) => 
      log.isTaskCompleted(task.id)
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
