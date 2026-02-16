import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../core/theme/app_theme.dart';

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
/// Progress Calculation:
/// - Shows WEEKLY CUMULATIVE progress (not just today)
/// - Progress = CompletedInstancesThisWeek / TotalScheduledInstancesThisWeek
/// - Bars gradually fill as tasks are completed throughout the week
/// - 100% reached only when ALL task instances for ENTIRE week are done
/// 
/// Each domain gets a unique color from the theme's color cycle
class DomainProgressBar extends StatelessWidget {
  final Domain domain;
  final double progress; // 0.0 to 1.0
  final int domainIndex; // For color assignment
  final VoidCallback onTap;

  const DomainProgressBar({
    super.key,
    required this.domain,
    required this.progress,
    required this.domainIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Clamp progress to valid range
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Get domain-specific color from color cycle
    final domainColor = AppTheme.getDomainColor(domainIndex);
    
    // Determine glow effect based on progress
    final bool hasSubtleGlow = clampedProgress >= 0.9;
    final bool hasStrongGlow = clampedProgress >= 1.0;
    
    // Debug print - shows weekly cumulative progress
    print('📊 ${domain.name}: ${(clampedProgress * 100).toStringAsFixed(1)}% (Weekly Cumulative)');
    
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.neonBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              
              // Foreground progress bar (fills from left)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedProgress,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 50,
                  decoration: BoxDecoration(
                    color: domainColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              
              // Content overlay - Domain name and percentage
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Domain name on the left
                      Expanded(
                        child: Text(
                          domain.name,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
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
    );
  }
}

