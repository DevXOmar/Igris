import 'package:flutter/material.dart';
import '../models/domain.dart';

/// Widget displaying a horizontal progress bar for a domain
/// 
/// Visual structure:
/// - Domain name label on top
/// - Fixed height horizontal bar (40px)
/// - Background bar (grey) with foreground bar (colored) on top
/// - Foreground bar fills from left to right based on progress
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
    
    // Debug print to verify values
    print("Domain: ${domain.name}, Progress: $clampedProgress");
    
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Domain name label
            Text(
              domain.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Horizontal progress bar
            SizedBox(
              height: 40, // fixed height for horizontal bar
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background bar (grey, full width)
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Foreground bar (colored, fills from left)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: clampedProgress, // double between 0 and 1
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: clampedProgress == 1.0 
                            ? Colors.greenAccent 
                            : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // Percentage overlay
                  if (clampedProgress > 0.05)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${(clampedProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

