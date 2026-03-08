import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// percent_indicator: CircularPercentIndicator used for weekly score + streak rings.
// Linear bars are NOT percent_indicator — domain bars remain custom widgets.
import 'package:percent_indicator/percent_indicator.dart';
// responsive_framework: breakpoint-aware layout decisions (column count, padding).
import 'package:responsive_framework/responsive_framework.dart';
import '../../providers/weekly_stats_provider.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../widgets/grace_tokens_display.dart';
import '../../widgets/domain_progress_bar.dart';
import '../../widgets/domain_tasks_bottom_sheet.dart';
import '../../widgets/xp_level_widget.dart';
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
            
            // ── STAT RINGS ─────────────────────────────────────────────────
            // Three circular rings in a row:
            //   1. Weekly Score  — neon blue  (percent_indicator)
            //   2. Streak        — blood red   (percent_indicator)
            //   3. Level / XP   — royal gold  (XpLevelWidget, flutter_animate)
            //
            // responsive_framework: on TABLET+ the rings get slightly more
            // padding and larger radius via ResponsiveBreakpoints.of(context).
            SliverToBoxAdapter(
              child: Padding(
                padding: DesignSystem.paddingAll16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSurface,
                    borderRadius: DesignSystem.radiusStandard,
                    border: Border.all(
                      color: AppColors.dividerColor,
                      width: DesignSystem.borderThin,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ── Weekly Score ring (neon blue) ──────────────────
                      _StatRing(
                        label: 'WEEKLY',
                        percent: (weeklyStats.weeklyScore / 100).clamp(0.0, 1.0),
                        centerText: '${weeklyStats.weeklyScore.toInt()}%',
                        progressColor: AppColors.neonBlue,
                      ),

                      // Thin vertical divider
                      Container(
                        width: 1,
                        height: 72,
                        color: AppColors.dividerColor,
                      ),

                      // ── Streak ring (blood red, capped at 7 days) ──────
                      _StatRing(
                        label: 'STREAK',
                        percent: (weeklyStats.currentStreak / 7).clamp(0.0, 1.0),
                        centerText: '${weeklyStats.currentStreak}d',
                        progressColor: AppColors.bloodRedActive,
                      ),

                      // Thin vertical divider
                      Container(
                        width: 1,
                        height: 72,
                        color: AppColors.dividerColor,
                      ),

                      // ── XP / Level ring (royal gold, flutter_animate) ──
                      XpLevelWidget(
                        weeklyScore: weeklyStats.weeklyScore,
                        streak: weeklyStats.currentStreak,
                      ),
                    ],
                  ),
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

// ─── Circular stat ring ─────────────────────────────────────────────────────
// Uses percent_indicator's CircularPercentIndicator to visualise a single
// numeric stat (weekly score or streak) with a colour-coded progress arc.
// The ring animates on first build (animation: true) and on percent change.
class _StatRing extends StatelessWidget {
  final String label;
  final double percent; // 0.0–1.0, already clamped by caller
  final String centerText;
  final Color progressColor;

  const _StatRing({
    required this.label,
    required this.percent,
    required this.centerText,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    // IgrisThemeColors gives typed access to the Igris dark palette without
    // hard-coding hex values. All theme colours should come from here.
    final igris = Theme.of(context).extension<IgrisThemeColors>();
    final bgColor = igris?.backgroundElevated ?? AppColors.backgroundElevated;
    final textMuted = igris?.textMuted ?? AppColors.textMuted;

    // On TABLET+ bump the ring radius slightly so it fills the extra space.
    final bool isTabletPlus =
        ResponsiveBreakpoints.of(context).largerOrEqualTo(TABLET);
    final double ringRadius = isTabletPlus ? 44.0 : 38.0;
    final double lineWidth = isTabletPlus ? 6.0 : 5.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularPercentIndicator(
          radius: ringRadius,
          lineWidth: lineWidth,
          percent: percent.clamp(0.0, 1.0),
          animation: true,
          animationDuration: 700,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: progressColor,
          backgroundColor: bgColor,
          center: Text(
            centerText,
            style: TextStyle(
              color: progressColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


