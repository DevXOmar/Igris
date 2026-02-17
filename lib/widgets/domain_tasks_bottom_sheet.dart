import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/domain.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/daily_log_provider.dart';
import '../core/theme/design_system.dart';
import '../core/theme/igris_animations.dart';

/// Bottom sheet showing tasks for a specific domain
/// Allows user to toggle task completion
/// Updates are instant via Riverpod
/// 
/// Animations:
/// - Slide-up + fade on open (350ms, easeOutCubic)
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
    
    // Apply slide-up animation to bottom sheet
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignSystem.spacing16 + 4), // 20px
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing16 + 4), // 20px
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
          
          SizedBox(height: DesignSystem.spacing16),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing16 + 4), // 20px
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
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignSystem.spacing12,
                        vertical: DesignSystem.spacing4 + 2, // 6px
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: DesignSystem.radiusSmall,
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
                
                SizedBox(height: DesignSystem.spacing8),
                
                Text(
                  'Today\'s Tasks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),
          const Divider(height: 1),
          
          // Tasks list
          if (domainTasks.isEmpty)
            Padding(
              padding: EdgeInsets.all(DesignSystem.spacing32 + 8), // 40px
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: DesignSystem.iconXLarge,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  SizedBox(height: DesignSystem.spacing12),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  SizedBox(height: DesignSystem.spacing4),
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
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacing16 + 4, // 20px
                  vertical: DesignSystem.spacing8,
                ),
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
          
          SizedBox(height: DesignSystem.spacing8),
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
      borderRadius: DesignSystem.radiusSmall,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: DesignSystem.spacing12,
          horizontal: DesignSystem.spacing8,
        ),
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
            
            SizedBox(width: DesignSystem.spacing12),
            
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
                padding: EdgeInsets.symmetric(
                  horizontal: DesignSystem.spacing8,
                  vertical: DesignSystem.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(DesignSystem.spacing8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat,
                      size: DesignSystem.spacing12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    SizedBox(width: DesignSystem.spacing4),
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
    ).igrisSlideUp(); // Slide-up animation for bottom sheet
  }
}
