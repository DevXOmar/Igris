import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// percent_indicator: CircularPercentIndicator renders the XP ring around the
// level number. Used here (not for histogram bars — those stay custom).
import 'package:percent_indicator/percent_indicator.dart';

import '../core/theme/app_theme.dart';
import '../services/animation_service.dart';

/// XP / Level visual indicator for the Igris system.
///
/// Derives level + XP from [weeklyScore] (0–100) and [streak] (days).
///
/// Formula:
///   totalPoints = weeklyScore × 1  +  streak × 5
///   pointsPerLevel = 50
///   level = (totalPoints ÷ pointsPerLevel).floor() + 1
///   xpPercent = (totalPoints % pointsPerLevel) / pointsPerLevel
///
/// Animations (flutter_animate):
///   - Initial fade-in + slight scale on first mount.
///   - Level-up pulse: brief scale spike + gold glow BoxShadow that fades out.
///     Triggered only when [weeklyScore] or [streak] pushes the level up.
///
/// Colors: IgrisThemeColors ThemeExtension — no hardcoded colors.
class XpLevelWidget extends ConsumerStatefulWidget {
  final double weeklyScore; // 0.0 → 100.0
  final int streak; // consecutive days

  const XpLevelWidget({
    super.key,
    required this.weeklyScore,
    required this.streak,
  });

  @override
  ConsumerState<XpLevelWidget> createState() => _XpLevelWidgetState();
}

class _XpLevelWidgetState extends ConsumerState<XpLevelWidget> {
  static const int _pointsPerLevel = 50;

  int _prevLevel = 0;
  bool _levelUpPulse = false;

  int _calcLevel(double score, int streak) {
    final points = score.toInt() + streak * 5;
    return (points ~/ _pointsPerLevel) + 1;
  }

  double _calcXpPercent(double score, int streak) {
    final points = score.toInt() + streak * 5;
    return ((points % _pointsPerLevel) / _pointsPerLevel).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _prevLevel = _calcLevel(widget.weeklyScore, widget.streak);
  }

  @override
  void didUpdateWidget(XpLevelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLevel = _calcLevel(widget.weeklyScore, widget.streak);
    if (newLevel > _prevLevel) {
      // Level increased → local glow pulse (flutter_animate)
      setState(() => _levelUpPulse = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _levelUpPulse = false);
      });
      // Fire the global system animation (AnimationOverlay picks it up)
      // addPostFrameCallback avoids triggering Riverpod state inside build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(animationServiceProvider.notifier).onLevelUp();
        }
      });
    }
    _prevLevel = newLevel;
  }

  @override
  Widget build(BuildContext context) {
    // Access our palette via IgrisThemeColors ThemeExtension
    final igris = Theme.of(context).extension<IgrisThemeColors>()!;

    final level = _calcLevel(widget.weeklyScore, widget.streak);
    final xpPercent = _calcXpPercent(widget.weeklyScore, widget.streak);

    // Gold glow applied on level-up pulse; otherwise no shadow.
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
      // percent_indicator — CircularPercentIndicator for the XP ring.
      // radius: 36, lineWidth: 5 → compact enough to fit in the stat row.
      child: CircularPercentIndicator(
        radius: 36.0,
        lineWidth: 5.0,
        percent: xpPercent,
        animation: true,
        animationDuration: 700,
        circularStrokeCap: CircularStrokeCap.round,
        // XP ring uses Royal Gold to feel premium/rare
        progressColor: igris.royalGold,
        backgroundColor: igris.backgroundElevated,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$level',
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

    // flutter_animate: scale pulse on level-up (controlled, intentional).
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

    // flutter_animate: initial fade-in on first mount
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
