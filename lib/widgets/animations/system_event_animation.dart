import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../core/theme/app_theme.dart';

/// Light-weight Lottie overlay for quest/task completion events.
///
/// ── Asset path ──────────────────────────────────────────────────────────────
///   assets/lottie/quest_complete.json
///
///   The .json animation should be ≤ 2 s, dark/transparent background, and
///   avoid bright saturated colors — the dark overlay handles theming.
///
/// ── Graceful fallback ───────────────────────────────────────────────────────
///   If the .json asset is absent, malformed, or virtually empty (< 200 ms),
///   the widget renders a pure flutter_animate fallback instead: expanding
///   neon-blue ring + check icon + "QUEST COMPLETE" label.
///
/// ── Lottie 3.x API ──────────────────────────────────────────────────────────
///   Uses `repeat: false` (play once) with an `onLoaded` callback that
///   schedules _finish() after the exact composition duration. No
///   AnimationController needed — the 2 s safety timeout in initState()
///   also guarantees dismissal if onLoaded never fires.
///
/// ── Overlay opacity ─────────────────────────────────────────────────────────
///   Rendered at 0.85 opacity, centered in a 240×240 SizedBox.
///
/// ── Dismissal ───────────────────────────────────────────────────────────────
///   [onComplete] fires at most once, guarded by [_completed].
class SystemEventAnimation extends StatefulWidget {
  final VoidCallback onComplete;

  const SystemEventAnimation({super.key, required this.onComplete});

  @override
  State<SystemEventAnimation> createState() => _SystemEventAnimationState();
}

class _SystemEventAnimationState extends State<SystemEventAnimation> {
  // true  → asset confirmed present, render Lottie
  // false + _useFallback=false → still verifying (invisible placeholder)
  bool _assetReady = false;
  bool _useFallback = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _checkAsset();
    // Safety: dismiss after 2.5 s even if onLoaded never fires
    Future.delayed(const Duration(milliseconds: 2500), _finish);
  }

  /// Verify the Lottie asset exists before trying to render it.
  /// rootBundle.load() throws PlatformException when the asset isn't bundled.
  Future<void> _checkAsset() async {
    try {
      await rootBundle.load('assets/lottie/quest_complete.json');
      if (mounted) setState(() => _assetReady = true);
    } catch (_) {
      if (mounted) setState(() => _useFallback = true);
    }
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    // Still confirming asset — transparent while loading (no flash)
    if (!_assetReady && !_useFallback) return const SizedBox.expand();

    if (_useFallback) {
      return IgnorePointer(
        child: Center(child: _QuestCompleteFallback(onDone: _finish)),
      );
    }

    // Asset confirmed — render Lottie with lottie 3.x API.
    // .animate() wraps Opacity (not Lottie directly) to avoid type inference
    // issues with LottieBuilder in the flutter_animate extension chain.
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(
            width: 240,
            height: 240,
            child: Lottie.asset(
              'assets/lottie/quest_complete.json',
              repeat: false,
              onLoaded: (composition) {
                if (composition.duration.inMilliseconds < 200) {
                  if (mounted) {
                    setState(() {
                      _assetReady = false;
                      _useFallback = true;
                    });
                  }
                  return;
                }
                Future.delayed(composition.duration, _finish);
              },
            ),
          ),
        ).animate().fadeIn(duration: 250.ms),
      ),
    );
  }
}

// ─── Flutter-Animate fallback ────────────────────────────────────────────────
// Shown when the Lottie asset is absent. Three layers, all IgnorePointer:
//
//   1. Expanding neon-blue ring with subtle glow
//   2. Checkmark icon scales into the ring
//   3. "QUEST COMPLETE" micro-label fades below
//
// Total runtime ≈ 1.5 s. [onDone] is called by the 2 s safety timeout.
class _QuestCompleteFallback extends StatelessWidget {
  final VoidCallback onDone;

  const _QuestCompleteFallback({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Ring ────────────────────────────────────────────────────────
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonBlue, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonBlue.withValues(alpha: 0.35),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.0, 1.0),
                duration: 380.ms,
                curve: Curves.easeOut,
              )
              .fadeIn(duration: 280.ms)
              .then(delay: 750.ms)
              .fadeOut(duration: 380.ms),

          // ── Checkmark ───────────────────────────────────────────────────
          const Icon(Icons.check_rounded, color: AppColors.neonBlue, size: 52)
              .animate()
              .fadeIn(delay: 180.ms, duration: 280.ms)
              .scaleXY(
                begin: 0.4,
                end: 1.0,
                delay: 180.ms,
                duration: 280.ms,
                curve: Curves.easeOut,
              )
              .then(delay: 700.ms)
              .fadeOut(duration: 380.ms),

          // ── Label ────────────────────────────────────────────────────────
          Positioned(
            bottom: 10,
            child: Text(
              'QUEST COMPLETE',
              style: TextStyle(
                color: AppColors.neonBlue.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.8,
              ),
            )
                .animate()
                .fadeIn(delay: 320.ms, duration: 280.ms)
                .then(delay: 650.ms)
                .fadeOut(duration: 380.ms),
          ),
        ],
      ),
    );
  }
}
