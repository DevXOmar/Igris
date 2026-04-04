import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../core/theme/igris_animations.dart';
import '../../providers/domain_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/daily_log_provider.dart';
import '../../models/domain.dart';
import '../../models/task.dart';
import '../../core/utils/domain_stat_weights.dart';
import '../../widgets/ui/igris_ui.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';

/// Domains screen for managing life domains and their tasks
/// Refactored with Igris UI components for consistent styling
/// 
/// Animations:
/// - Card fade-in on mount
/// - Subtle highlight glow when progress >= 90%
class DomainsScreen extends ConsumerWidget {
  const DomainsScreen({super.key});

  Future<Map<String, double>?> _showAdjustMappingSheet(
    BuildContext context, {
    required Map<String, double> initial,
  }) {
    final initialNormalized = normalizeStatWeights(initial);
    final weights = <String, double>{
      for (final k in kCoreStatKeys) k: 0.0,
      ...initialNormalized,
    };

    return showModalBottomSheet<Map<String, double>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int activeCount() =>
                weights.values.where((v) => v > 0.0).length;

            double sum() =>
                weights.values.fold(0.0, (a, b) => a + b);

            void onChanged(String key, double value) {
              final currentlyActive = weights.entries
                  .where((e) => e.key != key && e.value > 0.0)
                  .length;
              final nextActive = currentlyActive + (value > 0.0 ? 1 : 0);
              if (value > 0.0 && nextActive > 3 && weights[key] == 0.0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Max 3 stats per domain.'),
                  ),
                );
                return;
              }
              setState(() {
                weights[key] = value;
              });
            }

            final total = sum();
            final normalizedPreview = normalizeStatWeights(weights);

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adjust Mapping',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select up to 3 stats. Total should be 1.0 (auto-normalized on save).',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  for (final key in kCoreStatKeys) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 110,
                          child: Text(formatStatKey(key)),
                        ),
                        Expanded(
                          child: Slider(
                            value: weights[key]!.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            label: weights[key]!.toStringAsFixed(2),
                            onChanged: (v) => onChanged(key, v),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            weights[key]!.toStringAsFixed(2),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Selected: ${activeCount()}/3   Raw total: ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: topStatKeys(normalizedPreview).map((k) {
                      final pct =
                          (normalizedPreview[k]! * 100).toStringAsFixed(0);
                      return Chip(
                        label: Text('${formatStatKey(k)} $pct%'),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(normalizeStatWeights(weights));
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(domainProvider);
    final taskState = ref.watch(taskProvider);
    ref.watch(dailyLogProvider); // Listen to daily log updates to refresh task visibility

    return IgrisScreenScaffold(
      title: 'Domains',
      applyPadding: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDomainDialog(context, ref),
        backgroundColor: AppColors.neonBlue,
        foregroundColor: AppColors.backgroundPrimary,
        tooltip: 'Add Domain',
        child: const Icon(Icons.add, size: 28),
      ),
      child: domainState.domains.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.dashboard,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  Text(
                    'No domains yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  Text(
                    'Create a domain to get started',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const ClampingScrollPhysics(),
              padding: DesignSystem.paddingAll16,
              itemCount: domainState.domains.length,
              itemBuilder: (context, index) {
                final domain = domainState.domains[index];
                
                // Get all tasks for domain, but hide completed one-time tasks
                final logNotifier = ref.read(dailyLogProvider.notifier);
                final domainTasks = taskState.getTasksByDomain(domain.id)
                    .where((t) => t.isRecurring || !logNotifier.isTaskCompletedAnyTime(t.id))
                    .toList();
                
                final weeklyScore = (domain.strength / 100.0).clamp(0.0, 1.0);
                final shouldGlow = weeklyScore >= 0.90;
                
                // Wrap card with fade-in animation (staggered)
                return Padding(
                  padding: EdgeInsets.only(bottom: DesignSystem.spacing16),
                  child: IgrisCard(
                    variant: IgrisCardVariant.elevated,
                    showGlow: shouldGlow,
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              domain.name,
                              style: TextStyle(
                                color: AppColors.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignSystem.spacing12,
                              vertical: DesignSystem.spacing8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.neonBlue,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Strength: ${domain.strength}',
                              style: TextStyle(
                                color: AppColors.neonBlue,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: EdgeInsets.only(top: DesignSystem.spacing4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  domain.isActive ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: domain.isActive
                                      ? AppColors.neonBlue
                                      : AppColors.textMuted,
                                ),
                                SizedBox(width: DesignSystem.spacing4),
                                Text(
                                  domain.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: DesignSystem.spacing16),
                                Text(
                                  '${domainTasks.length} tasks',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: DesignSystem.spacing4),
                            Text(
                              'Contributes to: ${topStatKeys(domain.statWeights).map(formatStatKey).join(', ')}',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      children: [
                        Divider(height: 1, color: AppColors.neonBlue.withValues(alpha: 0.2)),
                        // Domain actions
                        Padding(
                          padding: DesignSystem.paddingAll16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Toggle active button
                              Row(
                                children: [
                                  Expanded(
                                    child: IgrisButton(
                                      onPressed: () {
                                        ref.read(domainProvider.notifier)
                                            .toggleDomainActive(domain.id);
                                      },
                                      variant: IgrisButtonVariant.outline,
                                      text: domain.isActive ? 'Deactivate' : 'Activate',
                                      icon: domain.isActive ? Icons.pause : Icons.play_arrow,
                                    ),
                                  ),
                                  SizedBox(width: DesignSystem.spacing8),
                                  Expanded(
                                    child: IgrisButton(
                                      onPressed: () => _showDeleteDomainDialog(context, ref, domain),
                                      variant: IgrisButtonVariant.destructive,
                                      text: 'Delete',
                                      icon: Icons.delete,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: DesignSystem.spacing16),
                              // Tasks list
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tasks',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  IgrisButton(
                                    onPressed: () => _showAddTaskDialog(context, ref, domain),
                                    variant: IgrisButtonVariant.ghost,
                                    text: 'Add Task',
                                    icon: Icons.add,
                                  ),
                                ],
                              ),
                              SizedBox(height: DesignSystem.spacing8),
                              if (domainTasks.isEmpty)
                                Text(
                                  'No tasks yet',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                )
                              else
                                ...domainTasks.map((task) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (task.isRecurring)
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: DesignSystem.spacing8,
                                                vertical: DesignSystem.spacing4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.neonBlue.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppColors.neonBlue,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                'Recurring',
                                                style: TextStyle(
                                                  color: AppColors.neonBlue,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          SizedBox(width: DesignSystem.spacing8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: AppColors.bloodRed,
                                              size: 20,
                                            ),
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
                  ),
                ).igrisFadeIn(delayMs: getStaggerDelay(index)); // Staggered fade-in for cards
              },
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
    String? pendingName;
    Map<String, double>? pendingWeights;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Domain'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pendingName != null && pendingWeights != null) ...[
                    const Text(
                      'This domain contributes to:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topStatKeys(pendingWeights!).map((k) {
                        return Chip(
                          label: Text('${formatStatKey(k)} ↑'),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final adjusted = await _showAdjustMappingSheet(
                                context,
                                initial: pendingWeights!,
                              );
                              if (adjusted == null) return;
                              setState(() {
                                pendingWeights = adjusted;
                              });
                            },
                            child: const Text('Adjust Mapping'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final name = pendingName!.trim();
                              final domain = Domain(
                                id: const Uuid().v4(),
                                name: name,
                                strength: 0,
                                isActive: true,
                                statWeights: pendingWeights,
                              );
                              ref.read(domainProvider.notifier).addDomain(domain);
                              Navigator.pop(context);
                            },
                            child: const Text('Create Domain'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
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
                            setState(() {
                              pendingName = name;
                              pendingWeights = inferStatWeights(name);
                            });
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
                          setState(() {
                            pendingName = value.trim();
                            pendingWeights = inferStatWeights(value.trim());
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final value = nameController.text.trim();
                          if (value.isEmpty) return;
                          setState(() {
                            pendingName = value;
                            pendingWeights = inferStatWeights(value);
                          });
                        },
                        child: const Text('Preview Mapping'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to presets'),
                      onPressed: () {
                        setState(() {
                          showCustomInput = false;
                          nameController.clear();
                          pendingName = null;
                          pendingWeights = null;
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
                    createdAt: DateTime.now(),
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
