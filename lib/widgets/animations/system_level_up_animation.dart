// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart';

import '../../core/theme/app_theme.dart';

// ── Auto-dismiss timing ──────────────────────────────────────────────────────
const _kRiveDuration = Duration(milliseconds: 3200);
const _kFadeOut = Duration(milliseconds: 400);
const _kFallbackDuration = Duration(milliseconds: 2600);

/// Full-screen overlay shown when the hunter's level increases.
///
/// ── Asset: assets/rive/level_up_shadow.riv ──────────────────────────────────
///   StateMachine : 'LevelMachine'
///   SMI inputs   : 'level'  (Number)  — drives visual intensity
///                  'rankUp' (Trigger) — starts the shadow-rise sequence
///
/// ── Behaviour ───────────────────────────────────────────────────────────────
///   1. Dark scrim fades in (70 % opacity).
///   2. Rive artboard loads; 'level' input is set; 'rankUp' fires.
///   3. "SYSTEM UPDATE" + "LEVEL X ACHIEVED" text block animates in.
///   4. After [_kRiveDuration] the whole overlay fades out and [onComplete]
///      is called exactly once.
///
/// Wrapped in [IgnorePointer] — no user interaction while visible.
class LevelUpOverlay extends StatefulWidget {
  final int newLevel;
  final VoidCallback onComplete;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onComplete,
  });

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  // ── Rive state ─────────────────────────────────────────────────────────────
  StateMachineController? _controller;
  SMINumber? _levelInput;
  SMITrigger? _rankUpTrigger;
  Artboard? _artboard;

  // ── Overlay state ──────────────────────────────────────────────────────────
  bool _riveLoaded = false;
  bool _useFallback = false;
  bool _dismissing = false;
  bool _completed = false;

  // ── Rive animation size (dp) ───────────────────────────────────────────────
  static const double _riveSize = 260;

  @override
  void initState() {
    super.initState();
    _loadRive();
  }

  // ── Load Rive ──────────────────────────────────────────────────────────────

  Future<void> _loadRive() async {
    try {
      final file = await RiveFile.asset('assets/rive/level_up_shadow.riv');
      final artboard = file.mainArtboard.instance();

      // Null-safe: only assign if the StateMachine exists in this .riv file.
      final controller =
          StateMachineController.fromArtboard(artboard, 'LevelMachine');
      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;
        _levelInput =
            controller.findInput<double>('level') as SMINumber?;
        _rankUpTrigger =
            controller.findInput<bool>('rankUp') as SMITrigger?;
      } else {
        // StateMachine absent — run first available simple animation.
        artboard.addController(SimpleAnimation('Animation 1', autoplay: true));
      }

      if (!mounted) return;
      setState(() {
        _artboard = artboard;
        _riveLoaded = true;
      });

      // Fire inputs after the first rendered frame so the artboard is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _levelInput?.value = widget.newLevel.toDouble();
        _rankUpTrigger?.fire();
      });

      Future.delayed(_kRiveDuration, _startDismiss);
    } catch (_) {
      // .riv missing, empty, or not a valid Rive file — use fallback.
      if (!mounted) return;
      setState(() => _useFallback = true);
      Future.delayed(_kFallbackDuration, _startDismiss);
    }
  }

  // ── Dismissal ──────────────────────────────────────────────────────────────

  void _startDismiss() {
    if (_completed || !mounted) return;
    setState(() => _dismissing = true);
    Future.delayed(_kFadeOut, _finish);
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  // ── Disposal ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Nothing to show yet — avoid any flash before the animation is ready.
    if (!_riveLoaded && !_useFallback) return const SizedBox.expand();

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _dismissing ? 0.0 : 1.0,
        duration: _kFadeOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Dark scrim ───────────────────────────────────────────────
            Container(color: Colors.black.withValues(alpha: 0.72))
                .animate()
                .fadeIn(duration: 280.ms),

            // ── 2. Central content ──────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _riveView(),
                  const SizedBox(height: 28),
                  _textBlock(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rive / Fallback view ───────────────────────────────────────────────────

  Widget _riveView() {
    if (_useFallback) return const _FallbackGoldRing();

    return SizedBox(
      width: _riveSize,
      height: _riveSize,
      child: Rive(artboard: _artboard!, fit: BoxFit.contain),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .scaleXY(
          begin: 0.82,
          end: 1.0,
          duration: 520.ms,
          curve: Curves.easeOutBack,
        );
  }

  // ── Text block ─────────────────────────────────────────────────────────────

  Widget _textBlock() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "SYSTEM UPDATE" — neon scan-line header
        Text(
          'SYSTEM UPDATE',
          style: TextStyle(
            color: AppColors.neonBlue.withValues(alpha: 0.88),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
        ).animate().fadeIn(delay: 380.ms, duration: 300.ms),

        const SizedBox(height: 12),

        // Thin gold divider — expands from centre outward
        Container(
          width: 220,
          height: 0.8,
          color: AppColors.royalGold.withValues(alpha: 0.55),
        )
            .animate()
            .fadeIn(delay: 480.ms, duration: 180.ms)
            .scaleX(
              begin: 0.0,
              end: 1.0,
              delay: 480.ms,
              duration: 360.ms,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 16),

        // "LEVEL X ACHIEVED" — gold headline
        Text(
          'LEVEL ${widget.newLevel} ACHIEVED',
          style: TextStyle(
            color: AppColors.royalGold,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: AppColors.royalGold.withValues(alpha: 0.90),
                blurRadius: 20,
              ),
              Shadow(
                color: AppColors.royalGold.withValues(alpha: 0.45),
                blurRadius: 52,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 540.ms, duration: 360.ms)
            .scaleXY(
              begin: 0.72,
              end: 1.0,
              delay: 540.ms,
              duration: 420.ms,
              curve: Curves.easeOutBack,
            ),
      ],
    );
  }
}

// ─── Fallback: gold ring pulse ────────────────────────────────────────────────
/// Shown when the Rive file is absent or fails to parse.
/// Maintains the visual language of the overlay without depending on assets.
class _FallbackGoldRing extends StatelessWidget {
  const _FallbackGoldRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.royalGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.55),
            blurRadius: 44,
            spreadRadius: 14,
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.2, 0.2),
          end: const Offset(1.1, 1.1),
          duration: 640.ms,
          curve: Curves.easeOutExpo,
        )
        .fadeIn(duration: 280.ms);
  }
}

// Back-compat alias so any callsite still using the old class name compiles.
typedef SystemLevelUpAnimation = LevelUpOverlay;
