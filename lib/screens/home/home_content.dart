import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weekly_stats_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/grace_tokens_display.dart';
import '../../widgets/domain_progress_bar.dart';
import '../../widgets/domain_tasks_bottom_sheet.dart';
import '../fuel_vault/vault_auth_screen.dart';

/// Home content showing weekly cumulative progress per domain as horizontal bars
/// 
/// Visual Design:
/// - ListView with horizontal progress bars
/// - Each row shows a horizontal progress bar for one domain
/// - Bars fill GRADUALLY across the week based on cumulative completion
/// - Bars reach 100% only when ALL task instances for ENTIRE week are done
/// - Tapping a bar opens bottom sheet with tasks
/// - Shows weekly score and current streak at top
/// 
/// Progress Formula:
/// - TotalScheduledInstancesThisWeek = (# of tasks in domain) × 7 days
/// - CompletedInstancesThisWeek = count of completed instances (Mon → Today)
/// - Progress % = (CompletedInstancesThisWeek / TotalScheduledInstancesThisWeek) × 100
/// 
/// Data Flow:
/// - Watches weeklyStatsProvider (provides weeklyProgress map)
/// - Provider auto-recalculates when:
///   * Tasks are completed/uncompleted
///   * Tasks are added/removed
///   * Domains are activated/deactivated
/// - UI rebuilds automatically via Riverpod
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch weekly stats - provides weeklyProgress map and stat cards
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.neonBlue.withOpacity(0.0),
                  Theme.of(context).colorScheme.neonBlue.withOpacity(0.6),
                  Theme.of(context).colorScheme.neonBlue.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            // Date header
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: DesignSystem.paddingAll16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayFormatted,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: DesignSystem.spacing4),
                    Text(
                      'Week: $weekRange',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: DesignSystem.spacing12),
                    // Grace tokens display
                    const GraceTokensDisplay(),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: Divider(height: 1)),
            
            // Weekly stats cards
            SliverToBoxAdapter(
              child: Padding(
                padding: DesignSystem.paddingAll16,
                child: Row(
                  children: [
                    // Weekly Score Card
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Weekly Score',
                        '${weeklyStats.weeklyScore.toStringAsFixed(0)}%',
                        Icons.analytics_outlined,
                        AppTheme.deepBlue,
                      ),
                    ),
                    SizedBox(width: DesignSystem.spacing12),
                    // Streak Card  
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Streak',
                        '${weeklyStats.currentStreak} days',
                        Icons.local_fire_department_outlined,
                        AppTheme.bloodRedActive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: Divider(height: 1)),
            
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                  DesignSystem.spacing16,
                  DesignSystem.spacing8,
                ),
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
                        SizedBox(width: DesignSystem.spacing8),
                        Text(
                          '(${weeklyStats.completedTasksThisWeek}/${weeklyStats.totalTasksThisWeek})',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bars fill as you complete tasks across all 7 days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Progress bars list
            domains.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: DesignSystem.spacing24,
                      ),
                      child: _buildEmptyState(context),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final domain = domains[index];
                        final progress = weeklyStats.weeklyProgress[domain] ?? 0.0;

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            DesignSystem.spacing16,
                            index == 0 ? DesignSystem.spacing16 : DesignSystem.spacing8,
                            DesignSystem.spacing16,
                            index == domains.length - 1 ? DesignSystem.spacing16 : DesignSystem.spacing8,
                          ),
                          child: DomainProgressBar(
                            domain: domain,
                            progress: progress,
                            domainIndex: index,
                            onTap: () {
                              _showDomainTasks(context, domain);
                            },
                          ),
                        );
                      },
                      childCount: domains.length,
                    ),
                  ),

            // Fuel Vault locked indicator card
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing16,
                  DesignSystem.spacing16,
                  DesignSystem.spacing16,
                ),
                child: InkWell(
                  borderRadius: DesignSystem.radiusStandard,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VaultAuthScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: DesignSystem.paddingAll16,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      borderRadius: DesignSystem.radiusStandard,
                      border: Border.all(
                        color: AppColors.neonBlue.withValues(alpha: 0.2),
                        width: DesignSystem.borderThin,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          color: AppColors.neonBlue,
                          size: 22,
                        ),
                        SizedBox(width: DesignSystem.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fuel Vault',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to unlock your private vault',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Stat card widget for weekly score and streak
  /// Professional dark design with subtle borders and controlled colors
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(DesignSystem.spacing24 - 4), // 20px
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated,
        borderRadius: DesignSystem.radiusStandard,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: DesignSystem.borderThin,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: DesignSystem.iconLarge,
          ),
          SizedBox(height: DesignSystem.spacing12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Empty state when no active domains
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard,
            size: DesignSystem.iconHero,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          SizedBox(height: DesignSystem.spacing16),
          Text(
            'No active domains',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: DesignSystem.spacing8),
          Text(
            'Create domains in the Domains tab',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
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


