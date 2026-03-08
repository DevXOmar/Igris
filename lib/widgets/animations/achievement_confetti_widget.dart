import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Rare confetti burst for major Igris achievements.
///
/// ── When to use ─────────────────────────────────────────────────────────────
///   • Level-up (combined with SystemLevelUpAnimation)
///   • Weekly goal 100% (combined with SystemEventAnimation)
///   • Streak milestone (stand-alone)
///
///   Not triggered for routine task ticks — motion must feel rare.
///
/// ── Design principles ───────────────────────────────────────────────────────
///   • Palette-locked colors: neon blue, royal gold, blood red — no rainbow
///   • 18 particles maximum — deliberate, not frantic
///   • Runs for [duration] then stops automatically
///   • All particles fall downward from the top-center of the screen
///   • [IgnorePointer] — user interaction is never blocked
///
/// ── Dismissal ───────────────────────────────────────────────────────────────
///   [onComplete] fires [duration] + 800 ms after mount, giving falling
///   particles time to settle off-screen before the overlay is removed.
class AchievementConfettiWidget extends StatefulWidget {
  final VoidCallback onComplete;

  /// How long the emitter fires. Particles continue falling after this ends.
  final Duration duration;

  const AchievementConfettiWidget({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AchievementConfettiWidget> createState() =>
      _AchievementConfettiWidgetState();
}

class _AchievementConfettiWidgetState extends State<AchievementConfettiWidget> {
  late ConfettiController _controller;

  /// Palette-based colors only — no bright saturated defaults.
  static const List<Color> _palette = [
    AppColors.neonBlue,
    AppColors.royalGold,
    AppColors.bloodRedActive,
    AppColors.deepBlue,
    AppColors.royalGoldDark,
  ];

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: widget.duration);
    _controller.play();

    // Dismiss after the burst ends + settling time for falling particles.
    Future.delayed(
      widget.duration + const Duration(milliseconds: 800),
      () {
        if (mounted) widget.onComplete();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _controller,

          // Fire downward from a single point at screen top-center.
          // π/2 = straight down. A spread of ± 90° (total 180°) fans
          // the burst naturally without going sideways off-screen.
          blastDirection: math.pi / 2,
          blastDirectionality: BlastDirectionality.directional,

          // Force: enough to reach mid-screen on a phone
          maxBlastForce: 20,
          minBlastForce: 7,

          // Emission: rare feel — not a blizzard
          emissionFrequency: 0.045,
          numberOfParticles: 18,

          // Physics
          gravity: 0.45,
          particleDrag: 0.06,

          // Appearance: small uniform squares — system-like, not cartoon
          minimumSize: const Size(5, 5),
          maximumSize: const Size(11, 11),
          colors: _palette,
          shouldLoop: false,
        ),
      ),
    );
  }
}
