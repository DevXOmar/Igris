import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/domain_provider.dart';
import '../../providers/task_provider.dart';
import '../../models/domain.dart';
import '../../models/task.dart';

/// Domains screen for managing life domains and their tasks
/// Users can create, edit domains and add tasks to each domain
class DomainsScreen extends ConsumerWidget {
  const DomainsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(domainProvider);
    final taskState = ref.watch(taskProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Domains'),
      ),
      body: domainState.domains.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 64,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No domains yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a domain to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: domainState.domains.length,
              itemBuilder: (context, index) {
                final domain = domainState.domains[index];
                final domainTasks = taskState.getTasksByDomain(domain.id);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Row(
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
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Strength: ${domain.strength}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            domain.isActive ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: domain.isActive 
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            domain.isActive ? 'Active' : 'Inactive',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${domainTasks.length} tasks',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    children: [
                      const Divider(height: 1),
                      // Domain actions
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toggle active button
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ref.read(domainProvider.notifier)
                                          .toggleDomainActive(domain.id);
                                    },
                                    icon: Icon(domain.isActive ? Icons.pause : Icons.play_arrow),
                                    label: Text(domain.isActive ? 'Deactivate' : 'Activate'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showDeleteDomainDialog(context, ref, domain),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Tasks list
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tasks',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddTaskDialog(context, ref, domain),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Task'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (domainTasks.isEmpty)
                              Text(
                                'No tasks yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            else
                              ...domainTasks.map((task) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(task.title),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (task.isRecurring)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Recurring',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          onPressed: () => _showDeleteTaskDialog(context, ref, task),
                                        ),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDomainDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDomainDialog(BuildContext context, WidgetRef ref) {
    // Predefined domain options
    final predefinedDomains = [
      'DS',
      'Fitness',
      'pHysiquE',
      'Boxing',
      'Vachan',
      'PR',
      'Academics',
      'Internships',
      'Face',
      'Stocks & Market',
      'Hackathons',
    ];
    
    final nameController = TextEditingController();
    bool showCustomInput = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Domain'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showCustomInput) ...[
                    const Text(
                      'Select a preset or add custom:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    // Predefined domain chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: predefinedDomains.map((name) {
                        return ActionChip(
                          label: Text(name),
                          onPressed: () {
                            final domain = Domain(
                              id: const Uuid().v4(),
                              name: name,
                              strength: 0,
                              isActive: true,
                            );
                            ref.read(domainProvider.notifier).addDomain(domain);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Custom domain button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Custom Domain'),
                        onPressed: () {
                          setState(() {
                            showCustomInput = true;
                          });
                        },
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Enter custom domain name:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Domain Name',
                        hintText: 'e.g., Health, Work, Learning',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          final domain = Domain(
                            id: const Uuid().v4(),
                            name: value.trim(),
                            strength: 0,
                            isActive: true,
                          );
                          ref.read(domainProvider.notifier).addDomain(domain);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to presets'),
                      onPressed: () {
                        setState(() {
                          showCustomInput = false;
                          nameController.clear();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (showCustomInput)
              TextButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    final domain = Domain(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      strength: 0,
                      isActive: true,
                    );
                    ref.read(domainProvider.notifier).addDomain(domain);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref, Domain domain) {
    final titleController = TextEditingController();
    bool isRecurring = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Task to ${domain.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g., Exercise for 30 minutes',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Recurring Task'),
                subtitle: const Text('Appears every day'),
                value: isRecurring,
                onChanged: (value) {
                  setState(() {
                    isRecurring = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  final task = Task(
                    id: const Uuid().v4(),
                    domainId: domain.id,
                    title: titleController.text.trim(),
                    isRecurring: isRecurring,
                  );
                  ref.read(taskProvider.notifier).addTask(task);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDomainDialog(BuildContext context, WidgetRef ref, Domain domain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Domain'),
        content: Text('Are you sure you want to delete "${domain.name}" and all its tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTasksByDomain(domain.id);
              ref.read(domainProvider.notifier).deleteDomain(domain.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteTaskDialog(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
