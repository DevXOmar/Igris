import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/task_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../widgets/grace_tokens_display.dart';
import '../../widgets/domain_progress_bar.dart';
import '../../widgets/domain_tasks_bottom_sheet.dart';

/// Home content showing today's progress per domain as horizontal bars
/// 
/// Visual Design:
/// - ListView with horizontal progress bars
/// - Each row shows a horizontal progress bar for one domain
/// - Bars fill from left to right based on completion percentage
/// - Tapping a bar opens bottom sheet with tasks
/// 
/// Data Flow:
/// - Watches todayProgressProvider (Map<Domain, double>)
/// - Provider auto-recalculates when:
///   * Tasks are completed/uncompleted
///   * Tasks are added/removed
///   * Domains are activated/deactivated
/// - UI rebuilds automatically via Riverpod
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch progress map - rebuilds when any task completion changes
    final progressMap = ref.watch(todayProgressProvider);
    
    final today = app_date_utils.DateUtils.today;
    final todayFormatted = app_date_utils.DateUtils.formatDateLong(today);
    
    // Get domains sorted by name for consistent grid layout
    final domains = progressMap.keys.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
            
            // Progress bars grid
            Expanded(
              child: domains.isEmpty
                  ? _buildEmptyState(context)
                  : _buildProgressList(context, ref, domains, progressMap),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state when no active domains
  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            'No active domains',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create domains in the Domains tab',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  /// List of horizontal progress bars
  /// One bar per domain, stacked vertically
  Widget _buildProgressList(
    BuildContext context,
    WidgetRef ref,
    List domains,
    Map progressMap,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: domains.length,
      itemBuilder: (context, index) {
        final domain = domains[index];
        final progress = progressMap[domain] ?? 0.0;
        
        return DomainProgressBar(
          domain: domain,
          progress: progress,
          onTap: () {
            // Show tasks bottom sheet when bar is tapped
            _showDomainTasks(context, domain);
          },
        );
      },
    );
  }

  /// Show bottom sheet with tasks for the selected domain
  /// Changes made in bottom sheet update UI instantly via Riverpod
  void _showDomainTasks(BuildContext context, domain) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DomainTasksBottomSheet(domain: domain),
    );
  }
}
