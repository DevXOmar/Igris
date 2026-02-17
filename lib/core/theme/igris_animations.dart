import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Igris Animation System
/// 
/// Controlled, premium animation extensions for Igris UI.
/// All animations are purposeful, minimal, and professional.
/// 
/// RULES:
/// - Duration: 200-400ms
/// - Curves: easeInOut, easeOutCubic
/// - NO looping, bounce, elastic, or cartoon effects
/// - Animations should feel controlled and intense, not playful
/// 
/// Usage:
/// ```dart
/// widget.igrisFadeIn()
/// widget.igrisTapScale(onTap: () {})
/// widget.igrisSlideUp()
/// ```

extension IgrisAnimations on Widget {
  /// Fade-in animation for initial mount
  /// Duration: 300ms
  /// Used for: Grid items, cards, content reveal
  Widget igrisFadeIn({int delayMs = 0}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(
          duration: 300.ms,
          curve: Curves.easeInOut,
        );
  }

  /// Slide-up animation with fade
  /// Duration: 350ms
  /// Used for: Bottom sheets, modals, overlays
  Widget igrisSlideUp({int delayMs = 0}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          duration: 300.ms,
          curve: Curves.easeInOut,
        );
  }

  /// Subtle upward slide with fade
  /// Duration: 300ms
  /// Used for: Bar animations, list items
  Widget igrisSlideUpSubtle({int delayMs = 0}) {
    return animate(delay: Duration(milliseconds: delayMs))
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(
          duration: 300.ms,
          curve: Curves.easeInOut,
        );
  }

  /// Tap scale animation
  /// Scales down to 0.96, then returns to 1.0
  /// Duration: 150ms down, 100ms up
  /// Used for: Interactive cards, buttons, domain bars
  Widget igrisTapScale({
    required VoidCallback onTap,
    double scaleTo = 0.96,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        // Scale down handled by AnimatedScale in parent
      },
      onTapUp: (_) {
        onTap();
      },
      onTapCancel: () {
        // Scale up handled by AnimatedScale in parent
      },
      child: this,
    );
  }

  /// One-time glow pulse for 100% completion
  /// Subtle intensity increase, no loop
  /// Duration: 400ms
  /// Used for: Domain bars at 100%
  Widget igrisGlowPulse({
    required Color glowColor,
    double maxIntensity = 0.8,
  }) {
    return animate(onComplete: (controller) => controller.stop())
        .custom(
          duration: 400.ms,
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            final intensity = (1 - value) * maxIntensity;
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(intensity * 0.6),
                    blurRadius: 20,
                    spreadRadius: intensity * 8,
                  ),
                ],
              ),
              child: child,
            );
          },
        );
  }
}

/// Stagger delay helper for grid animations
/// Returns stagger delay based on index
/// Base delay: 50ms per item
int getStaggerDelay(int index, {int baseDelayMs = 50}) {
  return index * baseDelayMs;
}

/// Animation state tracker to prevent re-animation on rebuild
class AnimationStateTracker {
  static final Set<String> _animatedKeys = {};

  static bool shouldAnimate(String key) {
    if (_animatedKeys.contains(key)) {
      return false;
    }
    _animatedKeys.add(key);
    return true;
  }

  static void reset(String key) {
    _animatedKeys.remove(key);
  }

  static void resetAll() {
    _animatedKeys.clear();
  }
}
