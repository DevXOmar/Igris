import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_system.dart';
import '../core/theme/igris_animations.dart';

/// Widget displaying a horizontal progress bar for a domain
/// 
/// Visual structure:
/// - Fixed height horizontal bar (50px)
/// - Background bar (elevated surface) with thin neon blue border
/// - Foreground bar fills from left, color based on domain index
/// - Domain name displayed INSIDE bar (left side)
/// - Percentage displayed INSIDE bar (right side)
/// - Subtle glow at >= 90% progress, stronger glow at 100%
/// 
/// Animations (flutter_animate):
/// - Initial fade-in + subtle slide (staggered via index)
/// - Tap scale down to 0.96 then back to 1.0
/// - One-time glow pulse when reaching 100%
/// - Progress bar animates with AnimatedContainer (600ms)
/// 
/// Progress Calculation:
/// - Shows WEEKLY CUMULATIVE progress (not just today)
/// - Progress = CompletedOccurrencesSoFar / ExpectedOccurrencesSoFar
/// - "Expected" is dynamic (recurring active days + one-time scheduling)
/// - Bars reflect "weekly progress (so far)" rather than time-based fill
/// 
/// Each domain gets a unique color from the theme's color cycle
class DomainProgressBar extends StatefulWidget {
  final Domain domain;
  final double progress; // 0.0 to 1.0
  final int domainIndex; // For color assignment and stagger
  final VoidCallback onTap;
  final bool enableInitialAnimation; // Control first-mount animation

  const DomainProgressBar({
    super.key,
    required this.domain,
    required this.progress,
    required this.domainIndex,
    required this.onTap,
    this.enableInitialAnimation = true,
  });

  @override
  State<DomainProgressBar> createState() => _DomainProgressBarState();
}

class _DomainProgressBarState extends State<DomainProgressBar> {
  bool _isPressed = false;
  bool _hasReached100 = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(DomainProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detect when progress reaches 100% for the first time
    if (!_hasReached100 && 
        widget.progress >= 1.0 && 
        oldWidget.progress < 1.0) {
      _hasReached100 = true;
      // Trigger one-time glow pulse via setState
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Clamp progress to valid range
    final clampedProgress = widget.progress.clamp(0.0, 1.0);
    
    // Get domain-specific color from color cycle
    final domainColor = AppTheme.getDomainColor(widget.domainIndex);
    
    // Determine glow effect based on progress
    final bool hasSubtleGlow = clampedProgress >= 0.9;
    final bool hasStrongGlow = clampedProgress >= 1.0;
    
    // Intentionally no debug printing here; this widget may rebuild frequently.
    
    // Core bar widget with tap scale animation
    Widget barWidget = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: DesignSystem.spacing8 + 2, // 10px
            horizontal: DesignSystem.spacing16,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: DesignSystem.radiusStandard,
              boxShadow: hasStrongGlow
                  ? AppTheme.blueGlowStrong
                  : hasSubtleGlow
                      ? AppTheme.blueGlowSubtle
                      : AppTheme.elevationShadow,
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background bar with thin neon border
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: colorScheme.backgroundElevated,
                    borderRadius: DesignSystem.radiusStandard,
                    border: Border.all(
                      color: colorScheme.neonBlue.withOpacity(0.3),
                      width: DesignSystem.borderThin,
                    ),
                  ),
                ),
                
                // Foreground progress bar (fills from left with animation)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clampedProgress,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 50,
                    decoration: BoxDecoration(
                      color: domainColor,
                      borderRadius: DesignSystem.radiusStandard,
                    ),
                  ),
                ),
                
                // Content overlay - Domain name and percentage
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSystem.spacing16 + 4, // 20px
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Domain name on the left
                        Expanded(
                          child: Text(
                            widget.domain.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Percentage on the right (always show)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DesignSystem.spacing12,
                            vertical: DesignSystem.spacing4 + 2, // 6px
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(DesignSystem.spacing8 + 2), // 10px
                          ),
                          child: Text(
                            '${(clampedProgress * 100).toInt()}%',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Apply one-time glow pulse when reaching 100%
    if (_hasReached100) {
      barWidget = barWidget.igrisGlowPulse(
        glowColor: colorScheme.bloodRed,
        maxIntensity: 0.6,
      );
    }

    // Apply initial fade-in + slide animation (only on first mount)
    if (widget.enableInitialAnimation) {
      final animationKey = 'domain_bar_${widget.domain.id}';
      
      if (AnimationStateTracker.shouldAnimate(animationKey)) {
        barWidget = barWidget.igrisSlideUpSubtle(
          delayMs: getStaggerDelay(widget.domainIndex),
        );
      }
    }

    return barWidget;
  }
}

