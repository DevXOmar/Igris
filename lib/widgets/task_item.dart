import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/domain.dart';

/// Widget for displaying a single task item
/// Shows task title, domain, completion status, and allows toggling
class TaskItem extends StatelessWidget {
  final Task task;
  final Domain? domain;
  final bool isCompleted;
  final VoidCallback onToggle;

  const TaskItem({
    super.key,
    required this.task,
    required this.domain,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Completion checkbox
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
              
              const SizedBox(width: 16),
              
              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Domain badge
                        if (domain != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              domain!.name,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        
                        // Recurring badge
                        if (task.isRecurring) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.2),
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
                      ],
                    ),
                  ],
                ),
              ),
              
              // Domain strength indicator (optional)
              if (domain != null && domain!.strength > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${domain!.strength}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
