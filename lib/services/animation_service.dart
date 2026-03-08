import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// All animation events that the Igris system can trigger.
///
/// Events are intentionally rare — each corresponds to a meaningful user
/// achievement rather than a routine interaction. Motion must feel like a
/// system response, not a celebration ticker.
enum AnimationEvent {
  none,

  /// Hunter level increased.
  /// Triggers: SystemLevelUpAnimation (Rive / gold-glow fallback) + confetti.
  levelUp,

  /// All tasks in a domain are completed for today.
  /// Triggers: SystemEventAnimation (Lottie / neon-blue fallback).
  questComplete,

  /// A new domain has been activated/unlocked.
  /// Triggers: SystemLevelUpAnimation (same visual as levelUp, distinct event).
  domainUnlocked,

  /// Weekly score reached 100% (all tasks, all 7 days complete).
  /// Triggers: SystemEventAnimation + confetti.
  weeklyGoal,

  /// Streak crossed a milestone (7 / 14 / 21 / 30 consecutive days).
  /// Triggers: confetti only — brief, subtle.
  streakMilestone,
}

/// Immutable snapshot for the animation broker.
///
/// [version] increments with every fire so the overlay detects a repeated
/// event of the same type as a distinct trigger, not a no-op state update.
@immutable
class AnimationTrigger {
  final AnimationEvent event;
  final int version;

  /// The new level number — only meaningful for [AnimationEvent.levelUp].
  final int level;

  const AnimationTrigger({
    this.event = AnimationEvent.none,
    this.version = 0,
    this.level = 0,
  });

  bool get isActive => event != AnimationEvent.none;
}

/// Centralized animation event bus.
///
/// All widgets that need to trigger an animation import this provider and call
/// the appropriate method:
///
/// ```dart
/// // Inside a widget callback (not during build):
/// ref.read(animationServiceProvider.notifier).onLevelUp();
/// ```
///
/// The [AnimationOverlay] (mounted above HomeScreen in _IgrisRoot) watches this
/// provider and renders the correct animation widget for the active event. When
/// the animation completes it calls [clear()] to reset the state.
class AnimationService extends Notifier<AnimationTrigger> {
  int _version = 0;

  @override
  AnimationTrigger build() => const AnimationTrigger();

  /// Level increased — gold glow hero animation + confetti.
  ///
  /// Pass [level] so the overlay can display "LEVEL X ACHIEVED".
  void onLevelUp([int level = 1]) => state = AnimationTrigger(
        event: AnimationEvent.levelUp,
        version: ++_version,
        level: level,
      );

  /// All tasks in a domain completed today — neon quest overlay.
  void onQuestComplete() =>
      state = AnimationTrigger(event: AnimationEvent.questComplete, version: ++_version);

  /// New domain unlocked — same visual weight as levelUp.
  void onDomainUnlocked() =>
      state = AnimationTrigger(event: AnimationEvent.domainUnlocked, version: ++_version);

  /// Weekly score hit 100% — quest overlay + confetti.
  void onWeeklyCompletion() =>
      state = AnimationTrigger(event: AnimationEvent.weeklyGoal, version: ++_version);

  /// Streak milestone crossed (7 / 14 / 21 / 30 days) — brief confetti.
  void onStreakMilestone() =>
      state = AnimationTrigger(event: AnimationEvent.streakMilestone, version: ++_version);

  /// Called by [AnimationOverlay] after the animation widget finishes.
  void clear() => state = const AnimationTrigger();
}

/// Global provider — import this wherever an animation needs to be triggered.
final animationServiceProvider =
    NotifierProvider<AnimationService, AnimationTrigger>(AnimationService.new);
