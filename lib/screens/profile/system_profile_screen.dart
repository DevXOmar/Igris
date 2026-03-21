import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/feat.dart';
import '../../models/player_profile.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/hunter_radar_chart.dart';
import '../settings/settings_screen.dart';
import 'stats_allocation_screen.dart';
import 'widgets/hunter_titles_section.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RANK DISPLAY HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Color _rankColor(String rank) {
  switch (rank) {
    case 'E':
      return AppColors.textMuted;
    case 'D':
      return const Color(0xFF4ECDC4);
    case 'C':
      return AppColors.neonBlue;
    case 'B':
      return const Color(0xFF7EB3FF);
    case 'A':
      return AppColors.shadowPurple;
    case 'S':
      return AppColors.royalGold;
    case 'National':
      return AppColors.bloodRedActive;
    case 'Monarch':
      return AppColors.royalGold;
    default:
      return AppColors.textMuted;
  }
}

String _rankLabel(String rank) {
  switch (rank) {
    case 'National':
      return 'NATIONAL';
    case 'Monarch':
      return 'MONARCH';
    default:
      return rank;
  }
}

String _rankNextCondition(String rank) {
  switch (rank) {
    case 'E':
      return 'Complete 50 tasks to reach Rank D';
    case 'D':
      return '14-day streak to reach Rank C';
    case 'C':
      return 'Complete 3 weekly campaigns to reach Rank B';
    case 'B':
      return 'Reach Level 20 to reach Rank A';
    case 'A':
      return '30-day streak to reach Rank S';
    case 'S':
      return 'A major real-world achievement to reach National';
    case 'National':
      return 'Exceptional mastery to reach Monarch';
    case 'Monarch':
      return 'Peak of human achievement. No higher rank exists.';
    default:
      return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM PROFILE SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SystemProfileScreen extends ConsumerWidget {
  const SystemProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Pinned app bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              '♦  SYSTEM  PROFILE',
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.neonBlue,
                iconSize: 22,
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: AppColors.neonBlue.withValues(alpha: 0.2),
              ),
            ),
          ),

          // ── All content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Rank Badge
                  const _RankBadgeSection(),
                  const SizedBox(height: 20),

                  // 2. Hunter Identity
                  const _HunterIdentitySection(),
                  const SizedBox(height: 24),

                  // 3. Holographic Level Card
                  const _LevelCardSection(),
                  const SizedBox(height: 28),

                  // 3b. Hunter Stats (radar + allocation entry)
                  const _HunterStatsSection(),
                  const SizedBox(height: 28),

                  // 4. Active Titles
                  const _SectionLabel(text: 'ACTIVE TITLES'),
                  const SizedBox(height: 10),
                  const _ActiveTitlesSection(),
                  const SizedBox(height: 28),

                  // 5. Hunter Titles
                  const HunterTitlesSection(),
                  const SizedBox(height: 32),

                  // 6. Shadow Archives
                  Row(
                    children: [
                      const _SectionLabel(
                        text: 'SHADOW ARCHIVES',
                        color: AppColors.shadowPurple,
                      ),
                      const Spacer(),
                      const _RecordFeatButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _ShadowArchivesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER-ISOLATED SECTION WRAPPERS
// ─────────────────────────────────────────────────────────────────────────────

class _RankBadgeSection extends ConsumerWidget {
  const _RankBadgeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rank = ref.watch(progressionProvider.select((p) => p.rank));
    return GlowingRankBadge(rank: rank);
  }
}

class _HunterIdentitySection extends ConsumerWidget {
  const _HunterIdentitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(progressionProvider.select((p) => p.name));
    final equippedTitleIds =
      ref.watch(progressionProvider.select((p) => p.equippedTitleIds));
    final activeTitleName = equippedTitleIds.isNotEmpty
      ? TitleDefinitions.findById(equippedTitleIds.first)?.name
        : null;
    return HunterIdentityCard(name: name, activeTitleName: activeTitleName);
  }
}

class _LevelCardSection extends ConsumerWidget {
  const _LevelCardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(progressionProvider.select((p) => p.level));
    final currentXP = ref.watch(progressionProvider.select((p) => p.currentXP));
    final xpRequired = ref.watch(xpRequiredProvider);
    final xpProgress = ref.watch(xpProgressProvider);
    final totalTasks =
        ref.watch(progressionProvider.select((p) => p.totalTasksCompleted));
    final longestStreak =
        ref.watch(progressionProvider.select((p) => p.longestStreak));
    return HolographicLevelCard(
      level: level,
      currentXP: currentXP,
      xpRequired: xpRequired,
      xpProgress: xpProgress,
      totalTasks: totalTasks,
      longestStreak: longestStreak,
    );
  }
}

class _HunterStatsSection extends ConsumerWidget {
  const _HunterStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveStats = ref.watch(effectiveStatsProvider);
    final stats = {
      ...PlayerProfile.defaultStats,
      ...effectiveStats,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonBlue.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel(text: 'HUNTER STATS'),
              const Spacer(),
              _AllocateStatsButton(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StatsAllocationScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HunterRadarChart(
                stats: stats,
                size: 160,
                maxValue: PlayerProfile.defaultMaxStatValue,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _StatLine(label: 'PRESENCE', value: stats['presence'] ?? 0),
                    _StatLine(label: 'STRENGTH', value: stats['strength'] ?? 0),
                    _StatLine(label: 'AGILITY', value: stats['agility'] ?? 0),
                    const SizedBox(height: 10),
                    _StatLine(label: 'ENDURANCE', value: stats['endurance'] ?? 0),
                    _StatLine(
                        label: 'INTELLIGENCE',
                        value: stats['intelligence'] ?? 0),
                    _StatLine(
                        label: 'DISCIPLINE', value: stats['discipline'] ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllocateStatsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AllocateStatsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Allocate stats',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonBlue.withValues(alpha: 0.08),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.neonBlue.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              const Text(
                'ALLOCATE',
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 350.ms).moveX(begin: 6, end: 0),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final int value;

  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.95),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppColors.neonBlue,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTitlesSection extends ConsumerWidget {
  const _ActiveTitlesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equippedTitleIds =
        ref.watch(progressionProvider.select((p) => p.equippedTitleIds));
    return ActiveTitlesRow(equippedTitleIds: equippedTitleIds);
  }
}

class _ShadowArchivesSection extends ConsumerWidget {
  const _ShadowArchivesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feats = ref.watch(progressionProvider.select((p) => p.feats));
    if (feats.isEmpty) return const _ShadowArchivesEmpty();
    final sorted = [...feats]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Column(
      children: sorted.asMap().entries.map((e) {
        return FeatCard(
          feat: e.value,
          delay: Duration(milliseconds: 60 * e.key),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const _SectionLabel({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.neonBlue;
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: c,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLOWING RANK BADGE
// ─────────────────────────────────────────────────────────────────────────────

class GlowingRankBadge extends StatelessWidget {
  final String rank;

  const GlowingRankBadge({required this.rank, super.key});

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);
    final label = _rankLabel(rank);
    final hint = _rankNextCondition(rank);

    return Center(
      child: Column(
        children: [
          // Outer ambient glow shell
          Container(
            width: 162,
            height: 162,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.16),
                  blurRadius: 52,
                  spreadRadius: 18,
                ),
              ],
            ),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.42),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.orbitron(
                      color: color,
                      fontSize: label.length > 1 ? 26 : 54,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RANK',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scaleXY(
            begin: 0.88, end: 1.0, duration: 600.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HUNTER IDENTITY CARD
// ─────────────────────────────────────────────────────────────────────────────

class HunterIdentityCard extends ConsumerWidget {
  final String name;
  final String? activeTitleName;

  const HunterIdentityCard(
      {required this.name, this.activeTitleName, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = name.trim().isEmpty ? 'Hunter' : name.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Row(
        children: [
          // Avatar silhouette
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundElevated,
              border: Border.all(
                color: AppColors.neonBlue.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.neonBlue.withValues(alpha: 0.65),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Name + active title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                if (activeTitleName != null)
                  Text(
                    '"$activeTitleName"',
                    style: const TextStyle(
                      color: AppColors.royalGold,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.2,
                    ),
                  )
                else
                  Text(
                    'No title equipped',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),

          // Edit name button
          IconButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _EditNameDialog(currentName: displayName),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.neonBlue.withValues(alpha: 0.65),
            tooltip: 'Edit name',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 500.ms)
        .slideY(begin: 0.04, end: 0, duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT NAME DIALOG  — owns its own ref; no async ref capture
// ─────────────────────────────────────────────────────────────────────────────

class _EditNameDialog extends ConsumerStatefulWidget {
  final String currentName;
  const _EditNameDialog({required this.currentName});

  @override
  ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentName == 'Hunter' ? '' : widget.currentName,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        '◆  HUNTER NAME',
        style: TextStyle(
          color: AppColors.neonBlue,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Enter your hunter name',
          hintStyle: TextStyle(color: AppColors.textMuted),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.dividerColor),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.neonBlue),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            // State update happens BEFORE pop — synchronous, no async gap,
            // no stale ref. The parent rebuilds cleanly after the route is gone.
            ref
                .read(progressionProvider.notifier)
                .updateName(_ctrl.text.trim());
            Navigator.of(context).pop();
          },
          child: const Text('Save',
              style: TextStyle(color: AppColors.neonBlue)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOLOGRAPHIC LEVEL CARD
// ─────────────────────────────────────────────────────────────────────────────

class HolographicLevelCard extends StatelessWidget {
  final int level;
  final int currentXP;
  final int xpRequired;
  final double xpProgress;
  final int totalTasks;
  final int longestStreak;

  const HolographicLevelCard({
    required this.level,
    required this.currentXP,
    required this.xpRequired,
    required this.xpProgress,
    required this.totalTasks,
    required this.longestStreak,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundSurface,
            Color(0xFF0F1E32),
            AppColors.backgroundElevated,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonBlue.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowPurple.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LVL number + XP label
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LVL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$level',
                style: GoogleFonts.orbitron(
                  color: AppColors.royalGold,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentXP XP',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '/ $xpRequired to next level',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // XP progress bar: neonBlue → shadowPurple gradient
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: xpProgress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  return Stack(
                    children: [
                      Container(
                        height: 8,
                        width: w,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: w * value,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.neonBlue,
                              AppColors.shadowPurple,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: value > 0.01
                              ? [
                                  BoxShadow(
                                    color: AppColors.neonBlue
                                        .withValues(alpha: 0.45),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Stats row — 3 cells with thin vertical dividers
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  icon: Icons.check_circle_outline,
                  label: 'TASKS',
                  value: '$totalTasks',
                  color: AppColors.neonBlue,
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.dividerColor),
              Expanded(
                child: _StatCell(
                  icon: Icons.local_fire_department,
                  label: 'STREAK',
                  value: '${longestStreak}d',
                  color: AppColors.bloodRedActive,
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.dividerColor),
              Expanded(
                child: _StatCell(
                  icon: Icons.timeline,
                  label: 'POWER',
                  value: '—',
                  color: AppColors.shadowPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE TITLES ROW
// ─────────────────────────────────────────────────────────────────────────────

class ActiveTitlesRow extends ConsumerWidget {
  final List<String> equippedTitleIds;

  const ActiveTitlesRow({required this.equippedTitleIds, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (equippedTitleIds.isEmpty) {
      return Text(
        'No titles equipped — unlock and equip titles below.',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: equippedTitleIds.map((id) {
          final def = TitleDefinitions.findById(id);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                (def?.name ?? id).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.royalGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              backgroundColor: AppColors.backgroundElevated,
              side: const BorderSide(color: AppColors.royalGoldDark, width: 1),
              avatar:
                  Icon(def?.icon ?? Icons.star, color: AppColors.royalGold, size: 14),
              deleteIcon:
                  const Icon(Icons.close, size: 14, color: AppColors.textMuted),
              onDeleted: () =>
                  ref.read(progressionProvider.notifier).unequipTitle(id),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECORD FEAT BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _RecordFeatButton extends ConsumerWidget {
  const _RecordFeatButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Record feat',
      child: InkWell(
        onTap: () => _showDialog(context, ref),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.shadowPurple.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowPurple.withValues(alpha: 0.10),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.diamond_outlined,
                size: 16,
                color: AppColors.shadowPurple.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              const Text(
                'RECORD FEAT',
                style: TextStyle(
                  color: AppColors.shadowPurple,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 350.ms).moveX(begin: 6, end: 0),
    );
  }

  Future<void> _showDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '◆  RECORD FEAT',
          style: TextStyle(
            color: AppColors.shadowPurple,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Feat name (e.g. Won Hackathon)',
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.dividerColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.shadowPurple),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.dividerColor),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.shadowPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              ref.read(progressionProvider.notifier).grantFeat(
                    name: name,
                    description: descCtrl.text.trim(),
                  );
              Navigator.of(ctx).pop();
            },
            child:
                Text('Record', style: TextStyle(color: AppColors.shadowPurple)),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOW ARCHIVES
// ─────────────────────────────────────────────────────────────────────────────

class _ShadowArchivesEmpty extends StatelessWidget {
  const _ShadowArchivesEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.shadowPurple.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            color: AppColors.shadowPurple.withValues(alpha: 0.4),
            size: 38,
          ),
          const SizedBox(height: 14),
          const Text(
            'Your legend begins here…\nRise, Hunter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class FeatCard extends StatelessWidget {
  final Feat feat;
  final Duration delay;

  const FeatCard({required this.feat, required this.delay, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.shadowPurple.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowPurple.withValues(alpha: 0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.shadowPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.diamond, color: AppColors.shadowPurple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feat.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (feat.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    feat.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  DateFormat('MMM d, yyyy').format(feat.timestamp),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: delay).fadeIn(duration: 280.ms).moveY(begin: 8, end: 0);
  }
}
