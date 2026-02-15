import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/daily_log_provider.dart';

/// Bottom sheet showing tasks for a specific domain
/// Allows user to toggle task completion
/// Updates are instant via Riverpod
class DomainTasksBottomSheet extends ConsumerWidget {
  final Domain domain;

  const DomainTasksBottomSheet({
    super.key,
    required this.domain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get tasks for this domain
    final taskState = ref.watch(taskProvider);
    final logState = ref.watch(dailyLogProvider);
    
    final domainTasks = taskState.tasks.where((task) => 
      task.domainId == domain.id
    ).toList();
    
    // Calculate completion stats
    final completedCount = domainTasks.where((task) =>
      logState.isTaskCompletedToday(task.id)
    ).length;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        domain.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completedCount / ${domainTasks.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Today\'s Tasks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          
          // Tasks list
          if (domainTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 48,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add tasks in the Domains screen',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: domainTasks.length,
                itemBuilder: (context, index) {
                  final task = domainTasks[index];
                  final isCompleted = logState.isTaskCompletedToday(task.id);
                  
                  return _TaskCheckItem(
                    task: task,
                    isCompleted: isCompleted,
                    onToggle: () {
                      // Toggle task completion
                      // This automatically updates domain strength via provider
                      ref.read(dailyLogProvider.notifier)
                          .toggleTaskCompletion(task.id, task.domainId);
                    },
                  );
                },
              ),
            ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Individual task item with checkbox in bottom sheet
class _TaskCheckItem extends StatelessWidget {
  final Task task;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _TaskCheckItem({
    required this.task,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).textTheme.bodyMedium!.color!,
                  width: 2,
                ),
                color: isCompleted
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSecondary,
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Task title
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  color: isCompleted
                      ? Theme.of(context).textTheme.bodyMedium?.color
                      : null,
                ),
              ),
            ),
            
            // Recurring badge
            if (task.isRecurring)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Daily',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
