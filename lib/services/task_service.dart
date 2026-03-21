import 'package:hive/hive.dart';
import '../models/task.dart';

/// Service for managing Task data in Hive
class TaskService {
  static const String _boxName = 'tasksBox';
  
  /// Get the tasks box
  Box<Task> get _box => Hive.box<Task>(_boxName);
  
  /// Get all tasks
  List<Task> getAllTasks() {
    return _box.values.toList();
  }
  
  /// Get tasks by domain ID
  List<Task> getTasksByDomain(String domainId) {
    return _box.values
        .where((task) => task.domainId == domainId)
        .toList();
  }
  
  /// Get a task by ID
  Task? getTaskById(String id) {
    try {
      return _box.values.firstWhere((task) => task.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Get all recurring tasks
  List<Task> getRecurringTasks() {
    return _box.values.where((task) => task.isRecurring).toList();
  }
  
  /// Get all one-time tasks
  List<Task> getOneTimeTasks() {
    return _box.values.where((task) => !task.isRecurring).toList();
  }
  
  /// Add a new task
  Future<void> addTask(Task task) async {
    await _box.put(task.id, task);
  }
  
  /// Update a task
  Future<void> updateTask(Task task) async {
    await _box.put(task.id, task);
  }
  
  /// Delete a task
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }
  
  /// Delete all tasks for a specific domain
  Future<void> deleteTasksByDomain(String domainId) async {
    final tasks = getTasksByDomain(domainId);
    for (final task in tasks) {
      await deleteTask(task.id);
    }
  }
  
  /// Clear all tasks (for testing/reset)
  Future<void> clearAll() async {
    await _box.clear();
  }
}
