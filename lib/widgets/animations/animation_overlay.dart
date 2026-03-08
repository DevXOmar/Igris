import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/animation_service.dart';
import 'achievement_confetti_widget.dart';
import 'system_event_animation.dart';
import 'system_level_up_animation.dart';

/// Root animation layer for the Igris app.
///
/// Wraps any [child] widget and renders the correct animation overlay on top
/// based on the current [animationServiceProvider] state.
///
/// ── Architecture ────────────────────────────────────────────────────────────
///
///   main.dart → _IgrisRoot
///     └── AnimationOverlay(child: HomeScreen())
///           ├── HomeScreen()       ← always present, always interactive
///           └── _AnimationLayer()  ← appears only when trigger.isActive
///                                     removed as soon as onComplete fires
///
/// ── Non-blocking ─────────────────────────────────────────────────────────────
///   Every animation widget inside is wrapped with [IgnorePointer], so the
///   user can always interact with the underlying screen while an animation
///   is playing.
///
/// ── Event → animation mapping ────────────────────────────────────────────────
///
///   levelUp / domainUnlocked → SystemLevelUpAnimation + AchievementConfetti
///   questComplete            → SystemEventAnimation (Lottie / neon fallback)
///   weeklyGoal               → SystemEventAnimation + AchievementConfetti
///   streakMilestone          → AchievementConfetti only (brief, subtle)
///
class AnimationOverlay extends ConsumerWidget {
  final Widget child;

  const AnimationOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trigger = ref.watch(animationServiceProvider);

    return Stack(
      children: [
        // ── Primary content — always visible and interactive ───────────────
        child,

        // ── Animation layer — present only while an event is active ────────
        //
        // ValueKey(trigger.version) forces Flutter to tear down the previous
        // _AnimationLayer and mount a fresh one each time a new event fires,
        // even if the event type is the same (e.g. two sequential level-ups).
        if (trigger.isActive)
          _AnimationLayer(
            key: ValueKey(trigger.version),
            trigger: trigger,
            onComplete: () =>
                ref.read(animationServiceProvider.notifier).clear(),
          ),
      ],
    );
  }
}

/// The animated content subtree.
///
/// Rebuilt (via ValueKey) for each distinct trigger version, guaranteeing
/// fresh animation state even for repeated events of the same type.
class _AnimationLayer extends StatelessWidget {
  final AnimationTrigger trigger;
  final VoidCallback onComplete;

  const _AnimationLayer({
    super.key,
    required this.trigger,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(child: _buildForEvent(trigger.event));
  }

  Widget _buildForEvent(AnimationEvent event) {
    switch (event) {
      // ── Major system events ───────────────────────────────────────────────
      // Hero Rive animation (gold-glow fallback) + palette confetti burst.
      // SystemLevelUpAnimation drives the dismiss timing (2.5 s / 1.8 s).
      // Confetti runs for 1.4 s, settles, then completes silently.
      case AnimationEvent.levelUp:
      case AnimationEvent.domainUnlocked:
        return Stack(
          children: [
            SystemLevelUpAnimation(onComplete: onComplete),
            AchievementConfettiWidget(onComplete: () {}),
          ],
        );

      // ── Quest / task completion ───────────────────────────────────────────
      // Lottie overlay (neon fallback) — no confetti for a single domain
      // completion. Quiet enough to feel like a system acknowledgement.
      case AnimationEvent.questComplete:
        return SystemEventAnimation(onComplete: onComplete);

      // ── Weekly goal 100% ─────────────────────────────────────────────────
      // Lottie + confetti — weekly completion is a bigger deal.
      // SystemEventAnimation drives timing; confetti completes silently.
      case AnimationEvent.weeklyGoal:
        return Stack(
          children: [
            SystemEventAnimation(onComplete: onComplete),
            AchievementConfettiWidget(onComplete: () {}),
          ],
        );

      // ── Streak milestone ─────────────────────────────────────────────────
      // Confetti only — briefest of the animations. Drives its own timing.
      case AnimationEvent.streakMilestone:
        return AchievementConfettiWidget(onComplete: onComplete);

      case AnimationEvent.none:
        return const SizedBox.shrink();
    }
  }
}
