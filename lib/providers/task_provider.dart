import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/domain.dart';
import '../services/task_service.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import '../services/daily_log_service.dart';
import 'domain_provider.dart';
import 'daily_log_provider.dart';

int _weekdayIndex(DateTime date) => date.weekday - 1; // Mon=0 .. Sun=6

/// True when [task] should be visible/interactive on the given [date].
///
/// Rules:
/// - Recurring tasks: show if active on that weekday.
/// - One-time tasks: show only on their scheduled/created date.
bool isTaskActiveOnDate(Task task, DateTime date) {
  if (task.isRecurring) {
    final createdAt = task.createdAt;
    if (createdAt != null) {
      final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
      final checkDay = DateTime(date.year, date.month, date.day);
      if (checkDay.isBefore(createdDay)) return false;
    }
    return task.effectiveActiveDays.contains(_weekdayIndex(date));
  }

  final scheduled = task.scheduledDate;
  if (scheduled == null) {
    // Legacy safety: if we cannot determine a scheduled day, keep it visible.
    return true;
  }
  return app_date_utils.DateUtils.isSameDay(scheduled, date);
}

/// State class for Task management
/// Holds all tasks and provides filtering methods
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  
  TaskState({
    required this.tasks,
    this.isLoading = false,
  });
  
  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
  
  /// Get all recurring tasks
  List<Task> get recurringTasks => tasks.where((t) => t.isRecurring).toList();
  
  /// Get all one-time tasks
  List<Task> get oneTimeTasks => tasks.where((t) => !t.isRecurring).toList();
  
  /// Get task by ID
  Task? getTaskById(String id) {
    try {
      return tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Get tasks by domain ID
  List<Task> getTasksByDomain(String domainId) {
    return tasks.where((t) => t.domainId == domainId).toList();
  }
}

/// Notifier for managing Task state
/// Handles all task-related operations and persists to Hive
class TaskNotifier extends Notifier<TaskState> {
  final TaskService _service = TaskService();
  final DailyLogService _dailyLogService = DailyLogService();
  
  @override
  TaskState build() {
    // Initialize state by loading tasks from Hive
    final tasks = _service.getAllTasks();

    // Backward-compat: older saves may have one-time tasks with no createdAt.
    // Infer a stable date so today-only filtering works without deleting data.
    // ignore: discarded_futures
    Future.microtask(() => _backfillLegacyOneTimeTaskDates(tasks));

    return TaskState(tasks: tasks);
  }

  Future<void> _backfillLegacyOneTimeTaskDates(List<Task> snapshot) async {
    final missing = snapshot
        .where((t) => !t.isRecurring && t.scheduledDate == null)
        .toList(growable: false);
    if (missing.isEmpty) return;

    final missingIds = missing.map((t) => t.id).toSet();
    final logs = _dailyLogService.getAllLogs();

    final earliest = <String, DateTime>{};
    for (final log in logs) {
      for (final id in log.completedTaskIds) {
        if (!missingIds.contains(id)) continue;
        final prev = earliest[id];
        if (prev == null || log.date.isBefore(prev)) {
          earliest[id] = log.date;
        }
      }
    }

    final today = app_date_utils.DateUtils.today;
    var didUpdate = false;
    for (final t in missing) {
      final inferred = earliest[t.id] ?? today;
      final normalized = DateTime(inferred.year, inferred.month, inferred.day);

      // Prefer storing as createdAt (Hive field 5) to keep schema stable.
      await _service.updateTask(t.copyWith(createdAt: normalized));
      didUpdate = true;
    }

    if (didUpdate) {
      loadTasks();
    }
  }
  
  /// Reload tasks from storage
  void loadTasks() {
    final tasks = _service.getAllTasks();
    state = state.copyWith(tasks: tasks);
  }
  
  /// Add a new task
  Future<void> addTask(Task task) async {
    await _service.addTask(task);
    loadTasks();
  }
  
  /// Update an existing task
  Future<void> updateTask(Task task) async {
    await _service.updateTask(task);
    loadTasks();
  }
  
  /// Delete a task
  Future<void> deleteTask(String id) async {
    await _service.deleteTask(id);
    loadTasks();
  }
  
  /// Delete all tasks for a specific domain
  Future<void> deleteTasksByDomain(String domainId) async {
    await _service.deleteTasksByDomain(domainId);
    loadTasks();
  }
}

/// Global provider for Task state management
final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() {
  return TaskNotifier();
});

/// Provider for getting today's tasks
/// This includes:
/// - All recurring tasks (they appear every day)
/// - One-time tasks (for V1, we show all of them)
/// - Only tasks from active domains
/// 
/// Data flow: Watches taskProvider and domainProvider -> Filters tasks -> Returns list
final todayTasksProvider = Provider<List<Task>>((ref) {
  final taskState = ref.watch(taskProvider);
  final domainState = ref.watch(domainProvider);
  final today = app_date_utils.DateUtils.today;
  
  // Get all active domain IDs for filtering
  final activeDomainIds = domainState.activeDomains.map((d) => d.id).toSet();
  
  // Filter tasks:
  // 1. Recurring tasks automatically appear every day
  // 2. For V1, all tasks appear (one-time tasks would have date logic in V2)
  // 3. Exclude tasks from inactive domains
  final todayTasks = taskState.tasks.where((task) {
    if (!activeDomainIds.contains(task.domainId)) return false;
    return isTaskActiveOnDate(task, today);
  }).toList();
  
  // Sort: recurring first, then by title
  todayTasks.sort((a, b) {
    if (a.isRecurring && !b.isRecurring) return -1;
    if (!a.isRecurring && b.isRecurring) return 1;
    return a.title.compareTo(b.title);
  });
  
  return todayTasks;
});

/// Provider for computing today's progress per domain
/// Returns a Map<Domain, double> where double is completion percentage (0.0 to 1.0)
/// 
/// How it works:
/// 1. Gets all active domains
/// 2. For each domain, gets today's tasks for that domain
/// 3. Counts total tasks and completed tasks (from DailyLog)
/// 4. Computes progress = completed / total (or 0 if no tasks)
/// 
/// UI updates automatically when:
/// - User completes/uncompletes a task -> dailyLogProvider changes
/// - User adds/removes tasks -> taskProvider changes
/// - Domain is activated/deactivated -> domainProvider changes
final todayProgressProvider = Provider<Map<Domain, double>>((ref) {
  final domainState = ref.watch(domainProvider);
  final taskState = ref.watch(taskProvider);
  final logState = ref.watch(dailyLogProvider);

  final today = app_date_utils.DateUtils.today;
  
  final progressMap = <Domain, double>{};
  
  // Calculate progress for each active domain
  for (final domain in domainState.activeDomains) {
    // Get all tasks for this domain that should appear today
    final domainTasks = taskState.tasks.where((task) {
      if (task.domainId != domain.id) return false;
      return isTaskActiveOnDate(task, today);
    }).toList();
    
    // If no tasks for today, omit this domain on the Home screen.
    if (domainTasks.isEmpty) {
      continue;
    }
    
    // Count how many tasks are completed today
    final completedCount = domainTasks.where((task) =>
      logState.isTaskCompletedToday(task.id)
    ).length;
    
    // Calculate progress as percentage (0.0 to 1.0)
    final progress = completedCount / domainTasks.length;
    progressMap[domain] = progress;
  }

  return progressMap;
});
