import 'package:flutter/material.dart';
import '../models/domain.dart';
import '../core/utils/color_utils.dart';

/// Widget displaying a horizontal progress bar for a domain
/// 
/// Visual structure:
/// - Fixed height horizontal bar (50px)
/// - Background bar (grey) with foreground bar (colored) on top
/// - Domain name displayed inside the bar on the left
/// - Percentage displayed inside the bar on the right
/// - Foreground bar fills from left to right based on progress
/// - Each domain gets a unique color based on its ID
/// 
/// Progress calculation happens in provider, this widget just displays it
class DomainProgressBar extends StatelessWidget {
  final Domain domain;
  final double progress; // 0.0 to 1.0
  final VoidCallback onTap;

  const DomainProgressBar({
    super.key,
    required this.domain,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp progress to valid range
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    // Generate unique color for this domain
    final domainColor = ColorUtils.generateDomainColor(domain.id);
    final progressColor = clampedProgress == 1.0 
        ? ColorUtils.getDarkerShade(domainColor)  // Darker shade when complete
        : domainColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          height: 50, // fixed height for horizontal bar
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Background bar (grey, full width)
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Foreground bar (colored, fills from left)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedProgress > 0.05 ? clampedProgress : 0.05, // Minimum width for visibility
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Text overlay - Domain name and percentage
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Domain name on the left
                      Expanded(
                        child: Text(
                          domain.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Percentage on the right
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(clampedProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
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

