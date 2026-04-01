import '../models/daily_log.dart';
import '../models/task.dart';
import '../providers/task_provider.dart' show isTaskActiveOnDate;

/// Calculates the current streak ending on [today].
///
/// A streak day qualifies when:
/// - Grace is used for that day, OR
/// - At least one eligible task for that day is completed.
///
/// Eligibility is date-aware:
/// - Task's domain must be active (via [isDomainActive])
/// - Recurring tasks must be scheduled for that weekday and only count on/after
///   their [Task.createdAt]
/// - One-time tasks are eligible only on their scheduled/created day
///
/// Days with zero eligible tasks are skipped (neutral) and do not break the
/// streak.
int calculateCurrentStreak({
  required DateTime today,
  required List<Task> tasks,
  required bool Function(String domainId) isDomainActive,
  required DailyLog? Function(DateTime date) getLogForDate,
}) {
  final activeTasks = tasks
      .where((t) => isDomainActive(t.domainId))
      .toList(growable: false);

  if (activeTasks.isEmpty) return 0;

  var streak = 0;
  var checkDate = DateTime(today.year, today.month, today.day);

  const int maxLookbackDays = 3660; // ~10 years
  var lookedBack = 0;

  while (true) {
    if (lookedBack++ >= maxLookbackDays) break;

    final eligibleTasks = activeTasks
        .where((t) => isTaskActiveOnDate(t, checkDate))
        .toList(growable: false);

    // No expected work on this day; treat as neutral.
    if (eligibleTasks.isEmpty) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      continue;
    }

    final log = getLogForDate(checkDate);
    if (log == null) break;

    if (log.graceUsed) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      continue;
    }

    final anyCompleted = eligibleTasks.any((t) => log.isTaskCompleted(t.id));
    if (anyCompleted) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      continue;
    }

    break;
  }

  return streak;
}
