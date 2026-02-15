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
  
  Task({
    required this.id,
    required this.domainId,
    required this.title,
    this.isRecurring = false,
  });
  
  /// Create a copy of this task with modified fields
  Task copyWith({
    String? id,
    String? domainId,
    String? title,
    bool? isRecurring,
  }) {
    return Task(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      title: title ?? this.title,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
  
  /// Convert task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domainId': domainId,
      'title': title,
      'isRecurring': isRecurring,
    };
  }
  
  /// Create task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      domainId: json['domainId'] as String,
      title: json['title'] as String,
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }
}
