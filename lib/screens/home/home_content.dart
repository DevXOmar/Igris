import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';
import '../../providers/daily_log_provider.dart';
import '../../providers/domain_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../widgets/task_item.dart';
import '../../widgets/grace_tokens_display.dart';

/// Home content showing today's tasks and grace tokens
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch today's tasks (automatically includes recurring tasks and filters by active domains)
    final tasks = ref.watch(todayTasksProvider);
    final logState = ref.watch(dailyLogProvider);
    final domainState = ref.watch(domainProvider);
    
    final today = app_date_utils.DateUtils.today;
    final todayFormatted = app_date_utils.DateUtils.formatDateLong(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Igris'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayFormatted,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  // Grace tokens display
                  const GraceTokensDisplay(),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Tasks list
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add tasks in the Domains screen',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final domain = domainState.getDomainById(task.domainId);
                        final isCompleted = logState.isTaskCompletedToday(task.id);
                        
                        return TaskItem(
                          task: task,
                          domain: domain,
                          isCompleted: isCompleted,
                          onToggle: () {
                            // Toggle task completion and update domain strength
                            ref.read(dailyLogProvider.notifier)
                                .toggleTaskCompletion(task.id, task.domainId);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
