import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/player_profile.dart';
import '../../../providers/progression_provider.dart';
import '../../../providers/weekly_stats_provider.dart';
import '../../../widgets/ui/igris_bottom_sheet.dart';

/// Premium Solo Leveling-style Hunter Titles panel.
///
/// - Shows unlocked titles in-grid
/// - Provides a "SEE ALL" button that opens a bottom sheet with ALL titles
///   (locked titles greyed out)
///
/// NOTE: This widget intentionally does NOT implement unlock logic.
/// It reads `profile.unlockedTitleIds` and `TitleDefinitions.all`.
class HunterTitlesSection extends ConsumerStatefulWidget {
  const HunterTitlesSection({super.key});

  @override
  ConsumerState<HunterTitlesSection> createState() =>
      _HunterTitlesSectionState();
}

class _HunterTitlesSectionState extends ConsumerState<HunterTitlesSection> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(progressionProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);

    final all = TitleDefinitions.all;
    final unlockedIds = profile.unlockedTitleIds.toSet();
    final activeIds = profile.activeTitleIds.toSet();

    final unlockedTitles = <TitleDefinition>[];
    final lockedTitles = <TitleDefinition>[];
    for (final t in all) {
      if (unlockedIds.contains(t.id)) {
        unlockedTitles.add(t);
      } else {
        lockedTitles.add(t);
      }
    }

    // Profile panel focuses on achieved/unlocked titles only.
    final visibleTitles = unlockedTitles;
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 760 ? 3 : 2;

    return Semantics(
      container: true,
      label: 'Hunter titles',
      child: Stack(
        children: [
          // Subtle holographic mist behind the grid (no assets required).
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.2, -0.6),
                    radius: 1.2,
                    colors: [
                      AppColors.shadowPurple.withValues(alpha: 0.10),
                      AppColors.neonBlue.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c)
                  .fadeIn(duration: 420.ms)
                  .shimmer(
                    duration: 2200.ms,
                    delay: 200.ms,
                    color: AppColors.neonBlue.withValues(alpha: 0.12),
                    angle: 0.9,
                  ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                onSeeAll: () => _openAllTitlesSheet(
                  context: context,
                  profile: profile,
                  weeklyStats: weeklyStats,
                ),
              ),
              const SizedBox(height: 12),

              if (visibleTitles.isEmpty) ...[
                const _EmptyUnlockedState(),
              ] else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: width >= 760 ? 1.05 : 1.12,
                  ),
                  itemCount: visibleTitles.length,
                  itemBuilder: (_, index) {
                    final def = visibleTitles[index];
                    final isUnlocked = unlockedIds.contains(def.id);
                    final isEquipped = activeIds.contains(def.id);
                    final progress = _inferProgress(def, profile, weeklyStats);

                    // Stagger by row rather than by absolute index.
                    final row = index ~/ crossAxisCount;
                    final col = index % crossAxisCount;
                    final delay = (row * 110 + col * 45).ms;

                    return _HunterTitleCard(
                      definition: def,
                      isUnlocked: isUnlocked,
                      isEquipped: isEquipped,
                      progress: progress,
                      onTap: isUnlocked
                          ? () {
                              final notifier =
                                  ref.read(progressionProvider.notifier);
                              if (isEquipped) {
                                notifier.unequipTitle(def.id);
                              } else {
                                notifier.equipTitle(def.id);
                              }
                            }
                          : null,
                    )
                        .animate(delay: delay)
                        .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                        .moveY(begin: 12, end: 0, duration: 320.ms);
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openAllTitlesSheet({
    required BuildContext context,
    required PlayerProfile profile,
    required WeeklyStats weeklyStats,
  }) async {
    final unlockedIds = profile.unlockedTitleIds.toSet();
    final activeIds = profile.activeTitleIds.toSet();
    final all = TitleDefinitions.all;

    await IgrisBottomSheet.show<void>(
      context: context,
      title: 'ALL TITLES',
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.74,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap an unlocked title to equip it.',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 760 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio:
                              constraints.maxWidth >= 760 ? 1.05 : 1.12,
                        ),
                        itemCount: all.length,
                        itemBuilder: (context, index) {
                          final def = all[index];
                          final isUnlocked = unlockedIds.contains(def.id);
                          final isEquipped = activeIds.contains(def.id);
                          final progress = _inferProgress(def, profile, weeklyStats);

                          final row = index ~/ crossAxisCount;
                          final col = index % crossAxisCount;
                          final delay = (row * 90 + col * 35).ms;

                          return _HunterTitleCard(
                            definition: def,
                            isUnlocked: isUnlocked,
                            isEquipped: isEquipped,
                            progress: progress,
                            onTap: isUnlocked
                                ? () {
                                    final notifier =
                                        ref.read(progressionProvider.notifier);
                                    if (isEquipped) {
                                      notifier.unequipTitle(def.id);
                                    } else {
                                      notifier.equipTitle(def.id);
                                    }
                                  }
                                : null,
                          )
                              .animate(delay: delay)
                              .fadeIn(duration: 240.ms)
                              .moveY(begin: 10, end: 0, duration: 300.ms);
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

class _HeaderRow extends StatelessWidget {
  final VoidCallback onSeeAll;

  const _HeaderRow({required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final title = 'HUNTER TITLES';
    final accent = AppColors.neonBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.orbitron(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.6,
              shadows: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.shadowPurple.withValues(alpha: 0.22),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 420.ms)
              .scale(
                begin: const Offset(0.99, 0.99),
                end: const Offset(1, 1),
                duration: 420.ms,
                curve: Curves.easeOut,
              )
              // Subtle holographic flicker/shimmer on load.
              .then(delay: 90.ms)
              .shimmer(
                duration: 1200.ms,
                color: AppColors.shadowPurple.withValues(alpha: 0.24),
                angle: 0.2,
              )
              .then(delay: 120.ms)
              .fade(
                begin: 1,
                end: 0.88,
                duration: 70.ms,
              )
              .fade(
                begin: 0.88,
                end: 1,
                duration: 90.ms,
              ),
        ),

        const SizedBox(width: 12),
        _SeeAllButton(onPressed: onSeeAll),
      ],
    );
  }
}

class _SeeAllButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SeeAllButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'See all titles',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonBlue.withValues(alpha: 0.10),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SEE ALL',
                style: TextStyle(
                  color: AppColors.neonBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: AppColors.neonBlue.withValues(alpha: 0.92),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 350.ms).moveX(begin: 6, end: 0),
    );
  }
}

class _EmptyUnlockedState extends StatelessWidget {
  const _EmptyUnlockedState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.shadowPurple.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.shadowPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock_outline,
              color: AppColors.shadowPurple.withValues(alpha: 0.55),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No titles unlocked yet.\nComplete tasks to awaken your first power.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).moveY(begin: 8, end: 0);
  }
}

class _HunterTitleCard extends StatefulWidget {
  final TitleDefinition definition;
  final bool isUnlocked;
  final bool isEquipped;
  final _InferredProgress? progress;
  final VoidCallback? onTap;

  const _HunterTitleCard({
    required this.definition,
    required this.isUnlocked,
    required this.isEquipped,
    required this.progress,
    required this.onTap,
  });

  @override
  State<_HunterTitleCard> createState() => _HunterTitleCardState();
}

class _HunterTitleCardState extends State<_HunterTitleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isStar = widget.definition.name.contains('★');
    final glow = widget.isUnlocked
        ? (isStar ? AppColors.royalGold : AppColors.neonBlue)
        : AppColors.textMuted.withValues(alpha: 0.18);

    final surface = widget.isUnlocked
        ? AppColors.backgroundSurface
        : AppColors.backgroundPrimary;

    final borderColor = widget.isEquipped
        ? AppColors.shadowPurple
        : widget.isUnlocked
            ? glow.withValues(alpha: isStar ? 0.60 : 0.42)
            : AppColors.dividerColor;

    final titleColor = widget.isUnlocked
        ? (isStar ? AppColors.royalGold : AppColors.textPrimary)
        : AppColors.textMuted;

    Widget content = Stack(
      children: [
        AnimatedContainer(
          duration: 160.ms,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surface,
                AppColors.backgroundElevated.withValues(alpha: 0.94),
              ],
            ),
            border: Border.all(
              color: borderColor.withValues(alpha: widget.isUnlocked ? 1 : 0.7),
              width: widget.isEquipped ? 1.6 : 1.0,
            ),
            boxShadow: widget.isUnlocked
                ? [
                    BoxShadow(
                      color: glow.withValues(
                        alpha: widget.isEquipped ? 0.18 : 0.12,
                      ),
                      blurRadius: widget.isEquipped ? 26 : 18,
                      spreadRadius: widget.isEquipped ? 2 : 1,
                    ),
                    BoxShadow(
                      color: AppColors.shadowPurple.withValues(
                        alpha: widget.isEquipped ? 0.12 : 0.06,
                      ),
                      blurRadius: widget.isEquipped ? 28 : 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),

        // Subtle inner scanline / hologram overlay.
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: widget.isUnlocked ? 0.22 : 0.10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.neonBlue.withValues(alpha: 0.12),
                        Colors.transparent,
                        AppColors.shadowPurple.withValues(alpha: 0.10),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c)
                    .shimmer(
                      duration: 1800.ms,
                      delay: 120.ms,
                      color: AppColors.neonBlue.withValues(alpha: 0.10),
                      angle: 0.85,
                    ),
              ),
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    widget.definition.icon,
                    color: widget.isUnlocked
                        ? (isStar ? AppColors.royalGold : AppColors.neonBlue)
                        : AppColors.textMuted.withValues(alpha: 0.55),
                    size: 20,
                    semanticLabel: '${widget.definition.name} icon',
                  ),
                  const Spacer(),
                  if (!widget.isUnlocked)
                    Icon(
                      Icons.lock_rounded,
                      color: AppColors.textMuted.withValues(alpha: 0.40),
                      size: 18,
                    )
                  else if (widget.isEquipped)
                    _Badge(
                      text: 'EQUIPPED',
                      color: AppColors.shadowPurple,
                    )
                  else if (isStar)
                    _Badge(
                      text: '★',
                      color: AppColors.royalGold,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              Text(
                widget.definition.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.orbitron(
                  color: titleColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  height: 1.15,
                ),
              ),
              const Spacer(),

              Text(
                widget.definition.unlockCondition,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted.withValues(
                    alpha: widget.isUnlocked ? 0.85 : 0.70,
                  ),
                  fontSize: 11,
                  height: 1.3,
                ),
              ),

              if (!widget.isUnlocked && widget.progress != null) ...[
                const SizedBox(height: 10),
                _ProgressBar(
                  value: widget.progress!.fraction,
                  label: widget.progress!.label,
                  accentColor:
                      isStar ? AppColors.royalGold : AppColors.neonBlue,
                ),
              ] else ...[
                const SizedBox(height: 8),
                // Keep layout consistent.
                SizedBox(
                  height: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.dividerColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Locked grayscale + lock overlay.
        if (!widget.isUnlocked)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
      ],
    );

    if (!widget.isUnlocked) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
        child: content,
      );
    }

    return Semantics(
      button: widget.isUnlocked,
      enabled: widget.isUnlocked,
      label: widget.definition.name,
      hint: widget.isUnlocked
          ? (widget.isEquipped
              ? 'Double tap to unequip title'
              : 'Double tap to equip title')
          : 'Locked title',
      child: GestureDetector(
        onTapDown: widget.isUnlocked
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapCancel:
            widget.isUnlocked ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.isUnlocked
            ? (_) => setState(() => _pressed = false)
            : null,
        child: AnimatedScale(
          duration: 120.ms,
          curve: Curves.easeOut,
          scale: _pressed ? 0.985 : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: widget.isUnlocked
                  ? AppColors.neonBlue.withValues(alpha: 0.12)
                  : Colors.transparent,
              highlightColor: Colors.transparent,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 14,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final Color accentColor;

  const _ProgressBar({
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                backgroundColor: AppColors.dividerColor.withValues(alpha: 0.28),
                valueColor: AlwaysStoppedAnimation<Color>(
                  accentColor.withValues(alpha: 0.85),
                ),
                minHeight: 6,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _InferredProgress {
  final int current;
  final int target;

  const _InferredProgress({required this.current, required this.target});

  double get fraction {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  String get label => '${current.clamp(0, target)}/$target';
}

_InferredProgress? _inferProgress(
  TitleDefinition def,
  PlayerProfile profile,
  WeeklyStats weeklyStats,
) {
  // Heuristic progress for common numeric requirements based on unlockCondition.
  // This is ONLY for visual progress; unlocking is handled elsewhere.
  final condition = def.unlockCondition.toLowerCase();

  // Avoid misleading progress for domain-specific or composite conditions.
  if (condition.contains('study') ||
      condition.contains('work/') ||
      condition.contains('fitness') ||
      condition.contains('across all') ||
      condition.contains('balanced') ||
      condition.contains('max out') ||
      condition.contains('milestone') ||
      condition.contains('backlog') ||
      condition.contains('overdue') ||
      condition.contains('without breaking')) {
    return null;
  }

  final match = RegExp(r'(\d+)').firstMatch(condition);
  if (match == null) return null;
  final target = int.tryParse(match.group(1) ?? '');
  if (target == null || target <= 0) return null;

  int current;
  if (condition.contains('level')) {
    current = profile.level;
  } else if (condition.contains('streak')) {
    current = profile.longestStreak;
  } else if (condition.contains('one week') || condition.contains('week')) {
    current = weeklyStats.completedTasksThisWeek;
  } else if (condition.contains('task')) {
    current = profile.totalTasksCompleted;
  } else {
    return null;
  }

  return _InferredProgress(current: current, target: target);
}

const List<double> _greyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];
