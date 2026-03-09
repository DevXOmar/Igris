import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// percent_indicator: CircularPercentIndicator renders the XP ring around the
// level number. Used here (not for histogram bars — those stay custom).
import 'package:percent_indicator/percent_indicator.dart';

import '../core/theme/app_theme.dart';
import '../providers/progression_provider.dart';
import '../providers/weekly_stats_provider.dart';

/// XP / Level visual indicator driven by the real [PlayerProfile].
///
/// Reads level and XP directly from [progressionProvider].
/// Also watches [weeklyStatsProvider] to keep [PlayerProfile.longestStreak]
/// in sync — this is the safe cross-provider bridge (widgets can watch any
/// combination of providers without circular-import risk).
class XpLevelWidget extends ConsumerStatefulWidget {
  const XpLevelWidget({super.key});

  @override
  ConsumerState<XpLevelWidget> createState() => _XpLevelWidgetState();
}

class _XpLevelWidgetState extends ConsumerState<XpLevelWidget> {
  int _prevLevel = 0;
  bool _levelUpPulse = false;
  int _prevStreak = 0;

  @override
  void initState() {
    super.initState();
    _prevLevel = ref.read(progressionProvider).level;
    _prevStreak = ref.read(weeklyStatsProvider).currentStreak;
  }

  @override
  Widget build(BuildContext context) {
    final igris = Theme.of(context).extension<IgrisThemeColors>()!;

    final profile = ref.watch(progressionProvider);
    final xpPercent = ref.watch(xpProgressProvider);
    final streak = ref.watch(weeklyStatsProvider).currentStreak;

    // Level-up pulse detection
    if (profile.level > _prevLevel) {
      _levelUpPulse = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _levelUpPulse = false);
      });
    }
    _prevLevel = profile.level;

    // Streak sync — bridge weeklyStats streak into the progression model
    if (streak != _prevStreak) {
      _prevStreak = streak;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(progressionProvider.notifier).syncStreak(streak);
        }
      });
    }

    final List<BoxShadow> glowShadow = _levelUpPulse
        ? [
            BoxShadow(
              color: igris.royalGold.withValues(alpha: 0.5),
              blurRadius: 14,
              spreadRadius: 2,
            )
          ]
        : [];

    Widget ring = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glowShadow,
      ),
      child: CircularPercentIndicator(
        radius: 36.0,
        lineWidth: 5.0,
        percent: xpPercent,
        animation: true,
        animationDuration: 700,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: igris.royalGold,
        backgroundColor: igris.backgroundElevated,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${profile.level}',
              style: TextStyle(
                color: igris.royalGold,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Text(
              'LV',
              style: TextStyle(
                color: igris.textMuted,
                fontSize: 8,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

    if (_levelUpPulse) {
      ring = ring
          .animate()
          .scaleXY(
            begin: 1.0,
            end: 1.12,
            duration: 200.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scaleXY(
            begin: 1.12,
            end: 1.0,
            duration: 300.ms,
            curve: Curves.easeInOut,
          );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ring,
        const SizedBox(height: 6),
        Text(
          'LEVEL',
          style: TextStyle(
            color: igris.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

