import 'package:hive/hive.dart';

part 'task.g.dart';

/// Task model represents a task within a domain
/// Tasks can be one-time or recurring
@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String domainId;
  
  @HiveField(2)
  late String title;
  
  @HiveField(3)
  late bool isRecurring;

  /// For recurring tasks: which weekdays this task is active on.
  ///
  /// Values are 0–6 for Mon–Sun.
  ///
  /// If null/empty for legacy tasks, treated as active every day.
  @HiveField(4)
  List<int>? activeDays;

  /// Creation time (used for one-time weekly expectations).
  ///
  /// May be null for legacy tasks.
  @HiveField(5)
  DateTime? createdAt;

  /// Optional scheduled date for one-time tasks.
  ///
  /// If set and it's later in the week, it should not count toward expected
  /// work until that date.
  @HiveField(6)
  DateTime? scheduledFor;
  
  Task({
    required this.id,
    required this.domainId,
    required this.title,
    this.isRecurring = false,
    this.activeDays,
    this.createdAt,
    this.scheduledFor,
  });

  /// Effective active days for recurring tasks.
  ///
  /// Falls back to all days (Mon–Sun) to preserve V1 "daily" behavior.
  List<int> get effectiveActiveDays {
    final days = activeDays;
    if (days == null || days.isEmpty) {
      return const [0, 1, 2, 3, 4, 5, 6];
    }
    return days;
  }

  /// Scheduled date if present, otherwise createdAt.
  DateTime? get scheduledForOrCreatedAt => scheduledFor ?? createdAt;
  
  /// Create a copy of this task with modified fields
  Task copyWith({
    String? id,
    String? domainId,
    String? title,
    bool? isRecurring,
    List<int>? activeDays,
    DateTime? createdAt,
    DateTime? scheduledFor,
  }) {
    return Task(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      title: title ?? this.title,
      isRecurring: isRecurring ?? this.isRecurring,
      activeDays: activeDays ?? this.activeDays,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
    );
  }
  
  /// Convert task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domainId': domainId,
      'title': title,
      'isRecurring': isRecurring,
      'activeDays': activeDays,
      'createdAt': createdAt?.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
    };
  }
  
  /// Create task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      domainId: json['domainId'] as String,
      title: json['title'] as String,
      isRecurring: json['isRecurring'] as bool? ?? false,
      activeDays: (json['activeDays'] as List?)?.map((e) => (e as num).toInt()).toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      scheduledFor: json['scheduledFor'] == null
          ? null
          : DateTime.tryParse(json['scheduledFor'] as String),
    );
  }
}
