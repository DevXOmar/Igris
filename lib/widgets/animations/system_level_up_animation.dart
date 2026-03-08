import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart';

import '../../core/theme/app_theme.dart';

/// Overlay animation for major Igris system events: level-up, domain-unlock.
///
/// ── Asset path ──────────────────────────────────────────────────────────────
///   assets/rive/level_up_system.riv
///
///   The .riv file should contain either:
///   • A StateMachine named "LevelUp" (preferred — allows input control), or
///   • A simple animation named "Animation 1" as a one-shot fallback.
///
/// ── Graceful fallback ───────────────────────────────────────────────────────
///   If the .riv asset is absent, empty, or fails to parse, a pure
///   flutter_animate fallback renders instead: an expanding gold ring +
///   "LEVEL UP / SYSTEM RESPONSE" text with glow. The visual language matches
///   the Igris dark palette and feels like a system notification, not a game.
///
/// ── Dismissal ───────────────────────────────────────────────────────────────
///   [onComplete] is called after 2.5 s (Rive) or 1.8 s (fallback).
///   The [AnimationOverlay] uses this to remove the layer from the Stack.
///
/// No interaction is possible while the overlay is visible ([IgnorePointer]).
class SystemLevelUpAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const SystemLevelUpAnimation({super.key, required this.onComplete});

  @override
  State<SystemLevelUpAnimation> createState() => _SystemLevelUpAnimationState();
}

class _SystemLevelUpAnimationState extends State<SystemLevelUpAnimation> {
  // Whether the Rive file loaded successfully
  bool _riveLoaded = false;
  // Whether we gave up on Rive and switched to fallback
  bool _useFallback = false;
  // Guard: fire onComplete exactly once
  bool _completed = false;

  Artboard? _artboard;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  Future<void> _loadRive() async {
    try {
      final file = await RiveFile.asset('assets/rive/level_up_system.riv');
      final artboard = file.mainArtboard.instance();

      // Prefer a StateMachine named "LevelUp"; fall back to any simple animation
      final smCtrl = StateMachineController.fromArtboard(artboard, 'LevelUp');
      if (smCtrl != null) {
        artboard.addController(smCtrl);
        smCtrl.isActive = true;
      } else {
        artboard.addController(SimpleAnimation('Animation 1', autoplay: true));
      }

      if (!mounted) return;
      setState(() {
        _artboard = artboard;
        _riveLoaded = true;
      });

      // Auto-dismiss after 2.5 s regardless of artboard animation length
      Future.delayed(const Duration(milliseconds: 2500), _finish);
    } catch (_) {
      // .riv not present, not a valid Rive file, or asset not bundled yet —
      // fall through to the flutter_animate gold-glow implementation.
      if (!mounted) return;
      setState(() => _useFallback = true);
      Future.delayed(const Duration(milliseconds: 1800), _finish);
    }
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Still loading — show nothing (avoids flash before the animation starts)
    if (!_riveLoaded && !_useFallback) return const SizedBox.expand();

    if (_riveLoaded && _artboard != null) {
      // ── Rive path ───────────────────────────────────────────────────────
      return IgnorePointer(
        child: Rive(artboard: _artboard!, fit: BoxFit.contain)
            .animate()
            .fadeIn(duration: 200.ms)
            .then(delay: 2000.ms)
            .fadeOut(duration: 300.ms),
      );
    }

    // ── Flutter-Animate fallback (gold system pulse) ─────────────────────
    return const _LevelUpFallback();
  }
}

// ─── Flutter-Animate fallback ────────────────────────────────────────────────
// Shown when the Rive asset is absent. Feels like a "system notification":
//
//   1. Subtle dark flash (fade in / out)
//   2. Expanding gold ring with glow
//   3. "LEVEL UP" text scales in from centre
//   4. "SYSTEM RESPONSE" subtitle fades below
//
// All timing is below 1.8 s total so onComplete fires promptly after.
class _LevelUpFallback extends StatelessWidget {
  const _LevelUpFallback();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Dim overlay ─────────────────────────────────────────────────
          // A brief darkening of the screen signals system takeover.
          Container()
              .animate()
              .custom(
                duration: 250.ms,
                builder: (_, value, child) => Container(
                  color: Colors.black.withValues(alpha: value * 0.40),
                  child: child,
                ),
              )
              .then(delay: 900.ms)
              .custom(
                duration: 500.ms,
                builder: (_, value, child) => Container(
                  color: Colors.black.withValues(alpha: (1 - value) * 0.40),
                  child: child,
                ),
              ),

          // ── Expanding gold ring ──────────────────────────────────────────
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.royalGold,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalGold.withValues(alpha: 0.55),
                  blurRadius: 52,
                  spreadRadius: 14,
                ),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.25, 0.25),
                end: const Offset(1.15, 1.15),
                duration: 650.ms,
                curve: Curves.easeOutExpo,
              )
              .fadeIn(duration: 280.ms)
              .then(delay: 450.ms)
              .fadeOut(duration: 380.ms),

          // ── "LEVEL UP" headline ──────────────────────────────────────────
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL UP',
                style: TextStyle(
                  color: AppColors.royalGold,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 7,
                  shadows: [
                    Shadow(
                      color: AppColors.royalGold.withValues(alpha: 0.85),
                      blurRadius: 24,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 280.ms, duration: 350.ms)
                  .scaleXY(
                    begin: 0.65,
                    end: 1.0,
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  )
                  .then(delay: 600.ms)
                  .fadeOut(duration: 350.ms),

              const SizedBox(height: 8),

              // Subtitle — smaller, neon blue, spaced out
              Text(
                'SYSTEM RESPONSE',
                style: TextStyle(
                  color: AppColors.neonBlue.withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 480.ms, duration: 300.ms)
                  .then(delay: 520.ms)
                  .fadeOut(duration: 350.ms),
            ],
          ),
        ],
      ),
    );
  }
}
