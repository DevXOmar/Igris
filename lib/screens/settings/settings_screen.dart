import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/grace_provider.dart';
import '../../providers/domain_provider.dart';
import '../../providers/task_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;

/// Settings screen for app configuration and grace token management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graceState = ref.watch(graceProvider);
    final domainState = ref.watch(domainProvider);
    final taskState = ref.watch(taskProvider);
    
    final daysUntilReset = ref.read(graceProvider.notifier).getDaysUntilReset();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Grace System Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Grace System',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Weekly Grace Tokens',
                    '${graceState.weeklyGraceLeft} / ${graceState.maxGraceTokens}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Days Until Reset',
                    '$daysUntilReset days',
                  ),
                  if (graceState.lastResetDate != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Last Reset',
                      app_date_utils.DateUtils.formatDateShort(graceState.lastResetDate!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Grace tokens allow you to skip a day without breaking your streak. They reset every week.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistics Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Total Domains',
                    '${domainState.domains.length}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Active Domains',
                    '${domainState.activeDomains.length}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Total Tasks',
                    '${taskState.tasks.length}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    'Recurring Tasks',
                    '${taskState.recurringTasks.length}',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Domain Strengths Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Domain Strengths',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (domainState.domains.isEmpty)
                    Text(
                      'No domains yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  else
                    ...domainState.domains.map((domain) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildInfoRow(
                            context,
                            domain.name,
                            'Strength: ${domain.strength}',
                          ),
                        )),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(context, 'App Name', 'Igris'),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'Version', '1.0.0'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'A personal productivity and identity-tracking app.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}
