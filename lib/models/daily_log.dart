import 'package:hive/hive.dart';

part 'daily_log.g.dart';

/// DailyLog model tracks daily task completion and grace usage
/// Stores which tasks were completed on a specific date
@HiveType(typeId: 2)
class DailyLog extends HiveObject {
  @HiveField(0)
  late DateTime date;
  
  @HiveField(1)
  late List<String> completedTaskIds;
  
  @HiveField(2)
  late bool graceUsed;
  
  DailyLog({
    required this.date,
    List<String>? completedTaskIds,
    this.graceUsed = false,
  }) : completedTaskIds = completedTaskIds ?? [];
  
  /// Check if a task is completed on this day
  bool isTaskCompleted(String taskId) {
    return completedTaskIds.contains(taskId);
  }
  
  /// Add a completed task
  void addCompletedTask(String taskId) {
    if (!completedTaskIds.contains(taskId)) {
      completedTaskIds.add(taskId);
    }
  }
  
  /// Remove a completed task
  void removeCompletedTask(String taskId) {
    completedTaskIds.remove(taskId);
  }
  
  /// Create a copy of this daily log with modified fields
  DailyLog copyWith({
    DateTime? date,
    List<String>? completedTaskIds,
    bool? graceUsed,
  }) {
    return DailyLog(
      date: date ?? this.date,
      completedTaskIds: completedTaskIds ?? List.from(this.completedTaskIds),
      graceUsed: graceUsed ?? this.graceUsed,
    );
  }
  
  /// Convert daily log to JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'completedTaskIds': completedTaskIds,
      'graceUsed': graceUsed,
    };
  }
  
  /// Create daily log from JSON
  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      date: DateTime.parse(json['date'] as String),
      completedTaskIds: (json['completedTaskIds'] as List?)
          ?.map((e) => e as String)
          .toList(),
      graceUsed: json['graceUsed'] as bool? ?? false,
    );
  }
}
