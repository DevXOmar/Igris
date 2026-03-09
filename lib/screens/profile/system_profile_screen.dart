import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/feat.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';

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
    final profile = ref.watch(progressionProvider);
    final xpProgress = ref.watch(xpProgressProvider);
    final xpRequired = ref.watch(xpRequiredProvider);

    return IgrisScreenScaffold(
      title: '◆  SYSTEM PROFILE',
      applyPadding: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── 1. Rank Badge ─────────────────────────────────────────────────
          _RankBadge(rank: profile.rank),
          const SizedBox(height: 28),

          // ── 2. Hunter Stats ───────────────────────────────────────────────
          _StatsCard(
            level: profile.level,
            currentXP: profile.currentXP,
            xpRequired: xpRequired,
            xpProgress: xpProgress,
            totalTasks: profile.totalTasksCompleted,
            longestStreak: profile.longestStreak,
          ),
          const SizedBox(height: 24),

          // ── 3. Active Titles ──────────────────────────────────────────────
          _SectionHeader(title: 'ACTIVE TITLES'),
          const SizedBox(height: 8),
          _ActiveTitlesRow(activeTitleIds: profile.activeTitleIds),
          const SizedBox(height: 24),

          // ── 4. All Titles ─────────────────────────────────────────────────
          _SectionHeader(title: 'HUNTER TITLES'),
          const SizedBox(height: 8),
          _AllTitlesList(
            unlockedTitleIds: profile.unlockedTitleIds,
            activeTitleIds: profile.activeTitleIds,
          ),
          const SizedBox(height: 28),

          // ── 5. Hall of Feats ──────────────────────────────────────────────
          Row(
            children: [
              _SectionHeader(title: 'HALL OF FEATS'),
              const Spacer(),
              _AddFeatButton(),
            ],
          ),
          const SizedBox(height: 8),
          _HallOfFeats(feats: profile.feats),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RANK BADGE
// ─────────────────────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final String rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = _rankColor(rank);

    return Center(
      child: Column(
        children: [
          // Hexagonal-ish badge using a rounded diamond
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _rankLabel(rank),
                  style: TextStyle(
                    color: color,
                    fontSize: rank.length > 1 ? 22 : 44,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RANK',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Next rank condition hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              _rankNextCondition(rank),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scaleXY(begin: 0.92, end: 1.0, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final int level;
  final int currentXP;
  final int xpRequired;
  final double xpProgress;
  final int totalTasks;
  final int longestStreak;

  const _StatsCard({
    required this.level,
    required this.currentXP,
    required this.xpRequired,
    required this.xpProgress,
    required this.totalTasks,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level + XP numbers
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LVL $level',
                style: const TextStyle(
                  color: AppColors.royalGold,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '$currentXP / $xpRequired XP',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // XP progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xpProgress),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.backgroundElevated,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.royalGold),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          Row(
            children: [
              _QuickStat(
                icon: Icons.check_circle_outline,
                label: 'Tasks',
                value: '$totalTasks',
                color: AppColors.neonBlue,
              ),
              const SizedBox(width: 24),
              _QuickStat(
                icon: Icons.local_fire_department,
                label: 'Best Streak',
                value: '${longestStreak}d',
                color: AppColors.bloodRedActive,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05, end: 0, duration: 400.ms);
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.neonBlue,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.neonBlue,
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
// ACTIVE TITLES ROW
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveTitlesRow extends ConsumerWidget {
  final List<String> activeTitleIds;
  const _ActiveTitlesRow({required this.activeTitleIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (activeTitleIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Text(
          'No titles equipped — unlock and equip titles below.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: activeTitleIds.map((id) {
        final def = TitleDefinitions.findById(id);
        final name = def?.name ?? id;
        return Chip(
          label: Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: AppColors.royalGold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: AppColors.backgroundElevated,
          side: const BorderSide(color: AppColors.royalGoldDark, width: 1),
          avatar: Icon(
            def?.icon ?? Icons.star,
            color: AppColors.royalGold,
            size: 14,
          ),
          deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
          onDeleted: () {
            ref.read(progressionProvider.notifier).unequipTitle(id);
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALL TITLES LIST
// ─────────────────────────────────────────────────────────────────────────────

class _AllTitlesList extends ConsumerWidget {
  final List<String> unlockedTitleIds;
  final List<String> activeTitleIds;
  const _AllTitlesList({required this.unlockedTitleIds, required this.activeTitleIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: TitleDefinitions.all.asMap().entries.map((entry) {
        final i = entry.key;
        final title = entry.value;
        final isUnlocked = unlockedTitleIds.contains(title.id);
        final isActive = activeTitleIds.contains(title.id);

        return _TitleRow(
          definition: title,
          isUnlocked: isUnlocked,
          isActive: isActive,
          delay: Duration(milliseconds: 60 * i),
        );
      }).toList(),
    );
  }
}

class _TitleRow extends ConsumerWidget {
  final TitleDefinition definition;
  final bool isUnlocked;
  final bool isActive;
  final Duration delay;

  const _TitleRow({
    required this.definition,
    required this.isUnlocked,
    required this.isActive,
    required this.delay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColor =
        isUnlocked ? AppColors.royalGold : AppColors.textMuted.withValues(alpha: 0.4);
    final nameColor = isUnlocked ? AppColors.textPrimary : AppColors.textMuted;
    final descColor = isUnlocked ? AppColors.textSecondary : AppColors.textMuted.withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.backgroundSurface
            : AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUnlocked
              ? AppColors.royalGoldDark.withValues(alpha: 0.3)
              : AppColors.dividerColor,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isUnlocked
                    ? AppColors.royalGoldDark.withValues(alpha: 0.4)
                    : AppColors.dividerColor,
              ),
            ),
            child: Icon(definition.icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // Name + unlock condition
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.name,
                  style: TextStyle(
                    color: nameColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked ? definition.description : definition.unlockCondition,
                  style: TextStyle(
                    color: descColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Lock / Equip button
          if (isUnlocked)
            GestureDetector(
              onTap: () {
                if (isActive) {
                  ref.read(progressionProvider.notifier).unequipTitle(definition.id);
                } else {
                  ref.read(progressionProvider.notifier).equipTitle(definition.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.royalGold.withValues(alpha: 0.15)
                      : AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? AppColors.royalGold : AppColors.dividerColor,
                  ),
                ),
                child: Text(
                  isActive ? 'EQUIPPED' : 'EQUIP',
                  style: TextStyle(
                    color: isActive ? AppColors.royalGold : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            Icon(Icons.lock_outline, color: AppColors.textMuted.withValues(alpha: 0.4), size: 18),
        ],
      ),
    ).animate(delay: delay).fadeIn(duration: 350.ms).slideX(begin: 0.04, end: 0, duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HALL OF FEATS
// ─────────────────────────────────────────────────────────────────────────────

class _HallOfFeats extends StatelessWidget {
  final List<Feat> feats;
  const _HallOfFeats({required this.feats});

  @override
  Widget build(BuildContext context) {
    if (feats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Center(
          child: Text(
            'Your feats will be recorded here.\nRecord real-world achievements to fill this hall.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final sorted = [...feats]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: sorted.asMap().entries.map((entry) {
        final i = entry.key;
        final feat = entry.value;
        return _FeatRow(feat: feat, delay: Duration(milliseconds: 60 * i));
      }).toList(),
    );
  }
}

class _FeatRow extends StatelessWidget {
  final Feat feat;
  final Duration delay;
  const _FeatRow({required this.feat, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.shadowPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diamond bullet
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.diamond, color: AppColors.shadowPurple, size: 16),
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
                  const SizedBox(height: 3),
                  Text(
                    feat.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM d, yyyy').format(feat.timestamp),
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ).animate(delay: delay).fadeIn(duration: 350.ms).slideX(begin: -0.04, end: 0, duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD FEAT BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _AddFeatButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showAddFeatDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.shadowPurple.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.shadowPurple.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: AppColors.shadowPurple, size: 14),
            const SizedBox(width: 4),
            Text(
              'RECORD FEAT',
              style: TextStyle(
                color: AppColors.shadowPurple,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddFeatDialog(BuildContext context, WidgetRef ref) async {
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
                focusedBorder: UnderlineInputBorder(
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
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.shadowPurple),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
            child: Text(
              'Record',
              style: TextStyle(color: AppColors.shadowPurple),
            ),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();
  }
}
