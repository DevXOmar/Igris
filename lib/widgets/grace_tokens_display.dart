import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/grace_provider.dart';
import '../core/theme/app_theme.dart';

/// Widget for displaying remaining grace tokens
/// Shows weekly grace tokens with visual indicators (Golden theme)
class GraceTokensDisplay extends ConsumerWidget {
  const GraceTokensDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graceState = ref.watch(graceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.royalGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            color: colorScheme.royalGold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Weekly Grace:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: List.generate(
                graceState.maxGraceTokens,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < graceState.weeklyGraceLeft
                          ? colorScheme.royalGold
                          : colorScheme.royalGold.withValues(alpha: 0.15),
                      boxShadow: index < graceState.weeklyGraceLeft
                          ? [
                              BoxShadow(
                                color: colorScheme.royalGold.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield,
                        size: 14,
                        color: index < graceState.weeklyGraceLeft
                            ? Colors.black.withValues(alpha: 0.8)
                            : colorScheme.royalGold.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            '${graceState.weeklyGraceLeft}/${graceState.maxGraceTokens}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.royalGold,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
