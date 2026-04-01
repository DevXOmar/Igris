import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import '../services/domain_progress_service.dart';
import '../services/streak_calculator.dart';
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
  final streak = calculateCurrentStreak(
    today: today,
    tasks: taskState.tasks,
    isDomainActive: (domainId) {
      final domain = domainState.getDomainById(domainId);
      return domain != null && domain.isActive;
    },
    getLogForDate: logNotifier.getLogForDate,
  );
  
  return WeeklyStats(
    weeklyProgress: weeklyProgress,
    weeklyScore: weeklyScore,
    currentStreak: streak,
    totalTasksThisWeek: totalTasksThisWeek,
    completedTasksThisWeek: completedTasksThisWeek,
  );
});
