import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/task.dart';
import '../../providers/grace_provider.dart';
import '../../providers/daily_log_provider.dart';
import '../../providers/progression_provider.dart';
import '../../providers/domain_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/weekly_stats_provider.dart';
import '../fuel_vault/vault_auth_screen.dart';
import '../profile/stats_allocation_screen.dart';
import '../settings/settings_screen.dart';

/// Home tab content — rebuilt to match the premium Igris design spec.
///
/// Sections:
/// 1) Header
/// 2) Weekly Grace
/// 3) System Status
/// 4) Hunter Stats (radar)
/// 5) Weekly Progress (bars + grid)
/// 6) Fuel Vault
class HomeContent extends ConsumerWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = app_date_utils.DateUtils.today;
    final todayFormatted = app_date_utils.DateUtils.formatDateLong(today);

    final now = DateTime.now();
    final after9pm = now.hour >= 21;

    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);
    final endOfWeek = app_date_utils.DateUtils.getEndOfWeek(today);
    final weekRange =
        '${app_date_utils.DateUtils.formatDateShort(startOfWeek)} - ${app_date_utils.DateUtils.formatDateShort(endOfWeek)}';

    final weeklyStats = ref.watch(weeklyStatsProvider);
    final profile = ref.watch(progressionProvider);
    final effectiveStats = ref.watch(effectiveStatsProvider);

    final graceState = ref.watch(graceProvider);
    final logState = ref.watch(dailyLogProvider);
    final domainState = ref.watch(domainProvider);
    final taskState = ref.watch(taskProvider);

    final todayLog = logState.todayLog;
    final graceAlreadyUsedToday = todayLog?.graceUsed ?? false;

    final activeTodayTasks = taskState.tasks.where((task) {
      final domain = domainState.getDomainById(task.domainId);
      return domain != null && domain.isActive;
    }).toList(growable: false);

    final completedActiveTasks = (todayLog == null)
      ? 0
      : activeTodayTasks.where((task) => todayLog.isTaskCompleted(task.id)).length;

    final completionRatio = activeTodayTasks.isEmpty
      ? 1.0
      : (completedActiveTasks / activeTodayTasks.length);

    final lowProgressDetected =
      activeTodayTasks.isNotEmpty && completionRatio < 0.70;

    final canOfferGracePrompt = after9pm &&
      lowProgressDetected &&
      !graceAlreadyUsedToday &&
      graceState.weeklyGraceLeft > 0;

    final domainProgressItems = weeklyStats.weeklyProgress.entries
        .map(
          (e) => _WeeklyProgressItem(
            domainId: e.key.id,
            label: e.key.name,
            percent: e.value.clamp(0.0, 1.0),
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                ),
                child: _Header(
                  dateText: todayFormatted,
                  weekText: 'Week: $weekRange',
                  onOpenSettings: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: DesignSystem.paddingH16,
                child: WeeklyGraceCard(
                  remaining: graceState.weeklyGraceLeft,
                  max: graceState.maxGraceTokens,
                ),
              ),
            ),
            if (canOfferGracePrompt)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacing16,
                    DesignSystem.spacing12,
                    DesignSystem.spacing16,
                    0,
                  ),
                  child: _EndOfDayGracePromptCard(
                    completionPercent: (completionRatio * 100).clamp(0, 100).toDouble(),
                    onApply: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.backgroundSurface,
                          title: Text(
                            'SYSTEM WARNING',
                            style: TextStyle(
                              color: AppColors.bloodRed,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          content: Text(
                            'Low progress detected.\n\nGrace Token will preserve your streak, but you will gain no XP.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Apply Grace',
                                style: TextStyle(
                                  color: AppColors.royalGold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;

                      final ok = await ref
                          .read(dailyLogProvider.notifier)
                          .useGraceForToday();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Weekly grace limit reached (2/2).'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                ),
                child: SystemStatusCard(
                  level: profile.level,
                  xpPercent: ref.watch(xpProgressProvider),
                  streakDays: weeklyStats.currentStreak,
                  weeklyPercent: weeklyStats.weeklyScore,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                ),
                child: HunterStatsCard(
                  presence: (effectiveStats['presence'] ?? 0),
                  strength: (effectiveStats['strength'] ?? 0),
                  agility: (effectiveStats['agility'] ?? 0),
                  endurance: (effectiveStats['endurance'] ?? 0),
                  intelligence: (effectiveStats['intelligence'] ?? 0),
                  discipline: (effectiveStats['discipline'] ?? 0),
                  onAllocate: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StatsAllocationScreen(),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                ),
                child: WeeklyProgressCard(
                  completed: weeklyStats.completedTasksThisWeek,
                  total: weeklyStats.totalTasksThisWeek,
                  items: domainProgressItems,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  DesignSystem.spacing12,
                  DesignSystem.spacing16,
                  DesignSystem.spacing24,
                ),
                child: FuelVaultCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VaultAuthScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _WeeklyProgressItem {
  final String domainId;
  final String label;
  final double percent;

  const _WeeklyProgressItem({
    required this.domainId,
    required this.label,
    required this.percent,
  });
}

class _Header extends StatelessWidget {
  final String dateText;
  final String weekText;
  final VoidCallback onOpenSettings;

  const _Header({
    required this.dateText,
    required this.weekText,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Igris',
                style: GoogleFonts.orbitron(
                  color: AppColors.neonBlue,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: 0.45),
                      blurRadius: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignSystem.spacing4),
              Text(
                dateText,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignSystem.spacing4),
              Text(
                weekText,
                style: TextStyle(
                  color: AppColors.neonBlue.withValues(alpha: 0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _GlowingIconButton(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onTap: onOpenSettings,
        ),
      ],
    );
  }
}

class _GlowingIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlowingIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignSystem.radiusStandard,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: DesignSystem.radiusStandard,
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.30),
              width: DesignSystem.borderThin,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonBlue.withValues(alpha: 0.18),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppColors.neonBlue,
            size: 24,
          ),
        ),
      ).animate().fadeIn(duration: 260.ms).moveY(begin: -4, end: 0),
    );
  }
}

class WeeklyGraceCard extends StatelessWidget {
  final int remaining;
  final int max;

  const WeeklyGraceCard({
    required this.remaining,
    required this.max,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _GradientFrame(
      border: LinearGradient(
        colors: [
          AppColors.royalGold.withValues(alpha: 0.55),
          AppColors.royalGold.withValues(alpha: 0.18),
          AppColors.neonBlue.withValues(alpha: 0.10),
        ],
      ),
      glow: AppColors.royalGold.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.spacing16,
          vertical: DesignSystem.spacing12,
        ),
        child: Row(
          children: [
            Text(
              'Weekly Grace',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Row(
              children: List.generate(max, (index) {
                final filled = index < remaining;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 26,
                    color: filled
                        ? AppColors.royalGold
                        : AppColors.royalGold.withValues(alpha: 0.22),
                    shadows: filled
                        ? [
                            BoxShadow(
                              color: AppColors.royalGold.withValues(alpha: 0.35),
                              blurRadius: 14,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            Text(
              '$remaining/$max',
              style: TextStyle(
                color: AppColors.royalGold,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndOfDayGracePromptCard extends StatelessWidget {
  final double completionPercent;
  final VoidCallback onApply;

  const _EndOfDayGracePromptCard({
    required this.completionPercent,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return _GradientFrame(
      border: LinearGradient(
        colors: [
          AppColors.bloodRed.withValues(alpha: 0.55),
          AppColors.royalGold.withValues(alpha: 0.24),
          AppColors.neonBlue.withValues(alpha: 0.10),
        ],
      ),
      glow: AppColors.bloodRed.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.spacing16,
          vertical: DesignSystem.spacing12,
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.royalGold,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Low progress detected',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today: ${completionPercent.toStringAsFixed(0)}% complete. Apply Grace to preserve streak (no XP).',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onApply,
              child: Text(
                'Apply Grace',
                style: TextStyle(
                  color: AppColors.royalGold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SystemStatusCard extends StatelessWidget {
  final int streakDays;
  final int level;
  final double xpPercent;
  final double weeklyPercent;

  const SystemStatusCard({
    required this.streakDays,
    required this.level,
    required this.xpPercent,
    required this.weeklyPercent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final weeklyClamped = (weeklyPercent / 100).clamp(0.0, 1.0);

    return _GradientFrame(
      border: LinearGradient(
        colors: [
          AppColors.neonBlue.withValues(alpha: 0.35),
          AppColors.shadowPurple.withValues(alpha: 0.22),
          AppColors.neonBlue.withValues(alpha: 0.14),
        ],
      ),
      glow: AppColors.shadowPurple.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSystem.spacing16,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left — streak
            SizedBox(
              width: 86,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'STREAK',
                    style: TextStyle(
                      color: AppColors.bloodRedActive.withValues(alpha: 0.70),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 20,
                        color: AppColors.bloodRedActive,
                        shadows: [
                          BoxShadow(
                            color:
                                AppColors.bloodRedActive.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${streakDays}d',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center — LVL + XP bar
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LVL $level',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.orbitron(
                      color: AppColors.neonBlue,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [
                        BoxShadow(
                          color: AppColors.neonBlue.withValues(alpha: 0.40),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 240.ms),
                  const SizedBox(height: DesignSystem.spacing8),
                  _XpBar(percent: xpPercent),
                ],
              ),
            ),

            // Right — weekly %
            SizedBox(
              width: 92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WEEKLY %',
                    style: TextStyle(
                      color: AppColors.neonBlue.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: DesignSystem.spacing8),
                  CircularPercentIndicator(
                    radius: 30,
                    lineWidth: 5,
                    percent: weeklyClamped,
                    backgroundColor:
                        AppColors.dividerColor.withValues(alpha: 0.65),
                    progressColor: AppColors.neonBlue,
                    circularStrokeCap: CircularStrokeCap.round,
                    center: Text(
                      '${weeklyPercent.toInt()}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final double percent;

  const _XpBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0.0, 1.0);

    return Row(
      children: [
        Text(
          'XP',
          style: TextStyle(
            color: AppColors.neonBlue.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.backgroundPrimary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.neonBlue.withValues(alpha: 0.18),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: p,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonBlue.withValues(alpha: 0.45),
                          AppColors.neonBlue,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonBlue.withValues(alpha: 0.30),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HunterStatsCard extends StatelessWidget {
  final int presence;
  final int strength;
  final int agility;
  final int endurance;
  final int intelligence;
  final int discipline;
  final VoidCallback onAllocate;

  const HunterStatsCard({
    required this.presence,
    required this.strength,
    required this.agility,
    required this.endurance,
    required this.intelligence,
    required this.discipline,
    required this.onAllocate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = 99.0;

    return _GradientFrame(
      border: LinearGradient(
        colors: [
          AppColors.neonBlue.withValues(alpha: 0.30),
          AppColors.shadowPurple.withValues(alpha: 0.22),
          AppColors.neonBlue.withValues(alpha: 0.12),
        ],
      ),
      glow: AppColors.neonBlue.withValues(alpha: 0.16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSystem.spacing16,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Hunter Stats',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignSystem.spacing12),
            SizedBox(
              height: 160,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: [
                    RadarDataSet(
                      dataEntries: [
                        RadarEntry(value: presence.clamp(0, 99).toDouble()),
                        RadarEntry(value: strength.clamp(0, 99).toDouble()),
                        RadarEntry(value: agility.clamp(0, 99).toDouble()),
                        RadarEntry(value: endurance.clamp(0, 99).toDouble()),
                        RadarEntry(value: intelligence.clamp(0, 99).toDouble()),
                        RadarEntry(value: discipline.clamp(0, 99).toDouble()),
                      ],
                      borderColor: AppColors.neonBlue.withValues(alpha: 0.85),
                      borderWidth: 2,
                      fillColor: AppColors.neonBlue.withValues(alpha: 0.16),
                      entryRadius: 2.5,
                    ),
                  ],
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  gridBorderData: BorderSide(
                    color: AppColors.dividerColor.withValues(alpha: 0.8),
                    width: 1,
                  ),
                  radarBorderData: BorderSide(
                    color: AppColors.dividerColor.withValues(alpha: 0.9),
                    width: 1,
                  ),
                  titleTextStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return const RadarChartTitle(text: 'Presence');
                      case 1:
                        return const RadarChartTitle(text: 'Strength');
                      case 2:
                        return const RadarChartTitle(text: 'Agility');
                      case 3:
                        return const RadarChartTitle(text: 'Endurance');
                      case 4:
                        return const RadarChartTitle(text: 'Intelligence');
                      case 5:
                        return const RadarChartTitle(text: 'Discipline');
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                  radarTouchData: RadarTouchData(enabled: false),
                ),
                swapAnimationDuration: 420.ms,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(label: 'Presence', value: presence, maxValue: maxV),
                _MiniStat(label: 'Strength', value: strength, maxValue: maxV),
                _MiniStat(label: 'Agility', value: agility, maxValue: maxV),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(label: 'Endurance', value: endurance, maxValue: maxV),
                _MiniStat(
                    label: 'Intelligence', value: intelligence, maxValue: maxV),
                _MiniStat(
                    label: 'Discipline', value: discipline, maxValue: maxV),
              ],
            ),
            const SizedBox(height: DesignSystem.spacing16),
            _NeonOutlineButton(text: 'ALLOCATE', onTap: onAllocate),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final double maxValue;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$label: $value',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _NeonOutlineButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: text,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignSystem.radiusStandard,
        child: Container(
          width: 190,
          padding: const EdgeInsets.symmetric(
            vertical: DesignSystem.spacing12,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            borderRadius: DesignSystem.radiusStandard,
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.75),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonBlue.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.orbitron(
                color: AppColors.neonBlue,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 240.ms).moveY(begin: 4, end: 0),
    );
  }
}

class WeeklyProgressCard extends ConsumerWidget {
  final int completed;
  final int total;
  final List<_WeeklyProgressItem> items;

  const WeeklyProgressCard({
    required this.completed,
    required this.total,
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GradientFrame(
      border: LinearGradient(
        colors: [
          AppColors.neonBlue.withValues(alpha: 0.22),
          AppColors.shadowPurple.withValues(alpha: 0.18),
          AppColors.neonBlue.withValues(alpha: 0.10),
        ],
      ),
      glow: AppColors.neonBlue.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSystem.spacing16,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Progress ($completed/$total)',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bars fill as you complete tasks across all 7 days',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignSystem.spacing16),
            if (items.isEmpty)
              Text(
                'No active domains yet.',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _DomainProgressRow(
                      domainId: items[i].domainId,
                      label: items[i].label,
                      percent: items[i].percent,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _DomainTasksSheet(
                          domainId: items[i].domainId,
                          domainName: items[i].label,
                        ),
                      ),
                    ),
                    if (i != items.length - 1) const SizedBox(height: 14),
                  ]
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DomainProgressRow extends StatelessWidget {
  final String domainId;
  final String label;
  final double percent;
  final VoidCallback onTap;

  const _DomainProgressRow({
    required this.domainId,
    required this.label,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final target = percent.clamp(0.0, 1.0);
    final pctText = '${(target * 100).round()}%';

    return Semantics(
      button: true,
      label: '$label weekly progress $pctText',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: target),
        duration: 420.ms,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          final trackBorderAlpha = (0.22 + (0.55 * t)).clamp(0.0, 1.0);
          final trackGlowAlpha = (0.08 + (0.30 * t)).clamp(0.0, 1.0);
          final fillGlowAlpha = (0.10 + (0.42 * t)).clamp(0.0, 1.0);

          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.orbitron(
                            color: AppColors.textPrimary.withValues(alpha: 0.92),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      Text(
                        '${(t * 100).round()}%',
                        style: GoogleFonts.orbitron(
                          color: AppColors.textPrimary.withValues(alpha: 0.88),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSurface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.neonBlue.withValues(alpha: trackBorderAlpha),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonBlue.withValues(alpha: trackGlowAlpha),
                          blurRadius: 18 + 22 * t,
                          spreadRadius: 0.6 + 1.4 * t,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.neonBlue.withValues(alpha: 0.06),
                                    AppColors.shadowPurple.withValues(alpha: 0.04),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: t.clamp(0.0, 1.0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      AppColors.deepBlue.withValues(alpha: 0.95),
                                      AppColors.neonBlue.withValues(alpha: 0.98),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.neonBlue.withValues(alpha: fillGlowAlpha),
                                      blurRadius: 14 + 18 * t,
                                      spreadRadius: 0.6 + 1.2 * t,
                                    ),
                                  ],
                                ),
                                // Without a child, DecoratedBox can size to 0,
                                // making the fill invisible. Force it to fill.
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 220.ms);
  }
}

class _DomainTasksSheet extends ConsumerWidget {
  final String domainId;
  final String domainName;

  const _DomainTasksSheet({
    required this.domainId,
    required this.domainName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskProvider);
    final logState = ref.watch(dailyLogProvider);

    final domainTasks = taskState.tasks.where((t) => t.domainId == domainId).toList();
    domainTasks.sort((a, b) {
      if (a.isRecurring && !b.isRecurring) return -1;
      if (!a.isRecurring && b.isRecurring) return 1;
      return a.title.compareTo(b.title);
    });

    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignSystem.spacing16,
          DesignSystem.spacing8,
          DesignSystem.spacing16,
          DesignSystem.spacing16,
        ),
        child: _GradientFrame(
          border: LinearGradient(
            colors: [
              AppColors.neonBlue.withValues(alpha: 0.26),
              AppColors.shadowPurple.withValues(alpha: 0.18),
              AppColors.neonBlue.withValues(alpha: 0.10),
            ],
          ),
          glow: AppColors.neonBlue.withValues(alpha: 0.14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: height * 0.78,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignSystem.spacing16,
                    DesignSystem.spacing12,
                    DesignSystem.spacing16,
                    DesignSystem.spacing12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              domainName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.rajdhani(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap tasks to complete',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textMuted,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: AppColors.dividerColor.withValues(alpha: 0.70),
                ),
                if (domainTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(DesignSystem.spacing16),
                    child: Text(
                      'No tasks in this domain yet.',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        DesignSystem.spacing12,
                        DesignSystem.spacing12,
                        DesignSystem.spacing12,
                        DesignSystem.spacing16,
                      ),
                      itemCount: domainTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final task = domainTasks[i];
                        final isDone = logState.isTaskCompletedToday(task.id);
                        return _TaskToggleRow(
                          task: task,
                          isDone: isDone,
                          onTap: () async {
                            await ref
                                .read(dailyLogProvider.notifier)
                                .toggleTaskCompletion(task.id, domainId);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskToggleRow extends StatelessWidget {
  final Task task;
  final bool isDone;
  final VoidCallback onTap;

  const _TaskToggleRow({
    required this.task,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignSystem.spacing16,
          vertical: DesignSystem.spacing12,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDone
                ? AppColors.neonBlue.withValues(alpha: 0.45)
                : AppColors.dividerColor.withValues(alpha: 0.75),
          ),
          boxShadow: [
            BoxShadow(
              color: isDone
                  ? AppColors.neonBlue.withValues(alpha: 0.10)
                  : AppColors.shadowPurple.withValues(alpha: 0.06),
              blurRadius: 14,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.neonBlue.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone
                      ? AppColors.neonBlue
                      : AppColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.neonBlue,
                    )
                  : null,
            ),
            const SizedBox(width: DesignSystem.spacing12),
            Expanded(
              child: Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: isDone ? 0.70 : 0.96),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (task.isRecurring)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'Daily',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FuelVaultCard extends StatelessWidget {
  final VoidCallback onTap;

  const FuelVaultCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return _GradientFrame(
      border: LinearGradient(
        colors: [
          AppColors.shadowPurple.withValues(alpha: 0.22),
          AppColors.dividerColor.withValues(alpha: 0.85),
          AppColors.shadowPurple.withValues(alpha: 0.10),
        ],
      ),
      glow: AppColors.shadowPurple.withValues(alpha: 0.12),
      background: AppColors.backgroundPrimary,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignSystem.radiusStandard,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignSystem.spacing16,
            DesignSystem.spacing16,
            DesignSystem.spacing16,
            DesignSystem.spacing16,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSurface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.shadowPurple.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: AppColors.neonBlue.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(width: DesignSystem.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fuel Vault',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to unlock your private vault',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 260.ms),
    );
  }
}

class _GradientFrame extends StatelessWidget {
  final Widget child;
  final LinearGradient border;
  final Color glow;
  final Color? background;

  const _GradientFrame({
    required this.child,
    required this.border,
    required this.glow,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final r = DesignSystem.radiusStandard;

    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 26,
            spreadRadius: 1,
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: border,
          borderRadius: r,
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background ?? AppColors.backgroundSurface,
              borderRadius: r,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
