import '../core/utils/date_utils.dart' as app_date_utils;
import '../models/daily_log.dart';
import '../models/domain.dart';
import '../models/task.dart';

/// Calculates domain weekly progress based on *expected work so far*.
///
/// Core formula (per domain):
/// progress = completedOccurrencesSoFar / expectedOccurrencesSoFar
///
/// - Recurring tasks: expected occurrences are based on [Task.activeDays]
///   (0–6 for Mon–Sun) that have already passed in the current week.
/// - One-time tasks: expected is 1 only when the task belongs to the current
///   week and is scheduled/created on or before [now].
///
/// This is designed to be pure/testable: no UI logic.
class DomainProgressService {
  final List<Task> _tasks;
  final DailyLog? Function(DateTime date) _getLogForDate;
  final DateTime _now;

  DomainProgressService({
    required List<Task> tasks,
    required DailyLog? Function(DateTime date) getLogForDate,
    required DateTime now,
  })  : _tasks = tasks,
        _getLogForDate = getLogForDate,
        _now = _normalizeDate(now);

  /// Calculates progress in range 0.0..1.0.
  double calculateDomainProgress(Domain domain) {
    final domainTasks = _tasks.where((t) => t.domainId == domain.id).toList();
    if (domainTasks.isEmpty) return 0.0;

    var expected = 0;
    var completed = 0;

    for (final task in domainTasks) {
      expected += getExpectedOccurrences(task, _now);
      completed += getCompletedOccurrences(task, _now);
    }

    if (expected <= 0) return 0.0;

    final ratio = completed / expected;
    return ratio.clamp(0.0, 1.0);
  }

  /// Expected occurrences for [task] from start of week through [now] (inclusive).
  int getExpectedOccurrences(Task task, DateTime now) {
    final today = _normalizeDate(now);
    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);

    if (task.isRecurring) {
      final activeDays = task.effectiveActiveDays;
      if (activeDays.isEmpty) return 0;

      final effectiveStart = getEffectiveStartDate(task, startOfWeek);
      if (effectiveStart.isAfter(today)) return 0;

      var count = 0;
      for (var date = effectiveStart;
          !date.isAfter(today);
          date = date.add(const Duration(days: 1))) {
        final weekdayIndex = date.weekday - DateTime.monday; // Mon=0..Sun=6
        if (activeDays.contains(weekdayIndex)) count++;
      }
      return count;
    }

    // One-time tasks
    final scheduled = _normalizeDate(task.scheduledForOrCreatedAt ?? today);

    // If we don't have any metadata (legacy tasks), treat as immediately
    // expected, matching V1 behavior.
    final hasMetadata = task.scheduledFor != null || task.createdAt != null;
    if (!hasMetadata) return 1;

    if (_isInWeek(scheduled, startOfWeek) && !scheduled.isAfter(today)) {
      return 1;
    }
    return 0;
  }

  /// Completed occurrences for [task] from start of week through [now] (inclusive).
  int getCompletedOccurrences(Task task, DateTime now) {
    final today = _normalizeDate(now);
    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);

    if (task.isRecurring) {
      final activeDays = task.effectiveActiveDays;
      if (activeDays.isEmpty) return 0;

      final effectiveStart = getEffectiveStartDate(task, startOfWeek);
      if (effectiveStart.isAfter(today)) return 0;

      var count = 0;
      for (var date = effectiveStart;
          !date.isAfter(today);
          date = date.add(const Duration(days: 1))) {
        final weekdayIndex = date.weekday - DateTime.monday; // Mon=0..Sun=6
        if (!activeDays.contains(weekdayIndex)) continue;

        final log = _getLogForDate(date);
        if (log != null && log.isTaskCompleted(task.id)) {
          count++;
        }
      }
      return count;
    }

    // One-time tasks
    final expected = getExpectedOccurrences(task, today);
    if (expected <= 0) return 0;

    var completed = 0;
    for (var i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      if (date.isAfter(today)) break;
      final log = _getLogForDate(date);
      if (log != null && log.isTaskCompleted(task.id)) {
        completed = 1;
        break;
      }
    }

    return completed;
  }

  static bool _isInWeek(DateTime date, DateTime startOfWeek) {
    final start = _normalizeDate(startOfWeek);
    final end = start.add(const Duration(days: 6));
    final d = _normalizeDate(date);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  static DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Effective inclusive start date for recurring task expectations.
  ///
  /// Recurring tasks should only count occurrences starting from the day they
  /// were created, but never earlier than [startOfWeek].
  static DateTime getEffectiveStartDate(Task task, DateTime startOfWeek) {
    final weekStart = _normalizeDate(startOfWeek);
    final created = task.createdAt == null ? null : _normalizeDate(task.createdAt!);
    if (created == null) return weekStart;
    return created.isAfter(weekStart) ? created : weekStart;
  }
}
