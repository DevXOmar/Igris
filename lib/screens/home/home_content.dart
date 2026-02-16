import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weekly_stats_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../widgets/grace_tokens_display.dart';
import '../../widgets/domain_progress_bar.dart';
import '../../widgets/domain_tasks_bottom_sheet.dart';

/// Home content showing weekly progress per domain as horizontal bars
/// 
/// Visual Design:
/// - ListView with horizontal progress bars
/// - Each row shows a horizontal progress bar for one domain
/// - Bars fill from left to right based on weekly completion percentage
/// - Tapping a bar opens bottom sheet with tasks
/// - Shows weekly score and current streak
/// 
/// Data Flow:
/// - Watches weeklyStatsProvider (WeeklyStats)
/// - Provider auto-recalculates when:
///   * Tasks are completed/uncompleted
///   * Tasks are added/removed
///   * Domains are activated/deactivated
/// - UI rebuilds automatically via Riverpod
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch weekly stats - rebuilds when any task completion changes
    final weeklyStats = ref.watch(weeklyStatsProvider);
    
    final today = app_date_utils.DateUtils.today;
    final todayFormatted = app_date_utils.DateUtils.formatDateLong(today);
    
    // Get start and end of week for display
    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);
    final endOfWeek = app_date_utils.DateUtils.getEndOfWeek(today);
    final weekRange = '${app_date_utils.DateUtils.formatDateShort(startOfWeek)} - ${app_date_utils.DateUtils.formatDateShort(endOfWeek)}';
    
    // Get domains sorted by name for consistent layout
    final domains = weeklyStats.weeklyProgress.keys.toList()
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
                  const SizedBox(height: 4),
                  Text(
                    'Week: $weekRange',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grace tokens display
                  const GraceTokensDisplay(),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Weekly stats cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Weekly Score Card
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Weekly Score',
                      '${weeklyStats.weeklyScore.toStringAsFixed(0)}%',
                      Icons.analytics,
                      Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Streak Card
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Streak',
                      '${weeklyStats.currentStreak} days',
                      Icons.local_fire_department,
                      Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Weekly Progress',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${weeklyStats.completedTasksThisWeek}/${weeklyStats.totalTasksThisWeek})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cumulative across all 7 days of the week',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Progress bars list
            Expanded(
              child: domains.isEmpty
                  ? _buildEmptyState(context)
                  : _buildProgressList(context, ref, domains, weeklyStats.weeklyProgress),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Stat card widget for weekly score and streak
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
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
