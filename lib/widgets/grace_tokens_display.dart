import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/grace_provider.dart';

/// Widget for displaying remaining grace tokens
/// Shows weekly grace tokens with visual indicators
class GraceTokensDisplay extends ConsumerWidget {
  const GraceTokensDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graceState = ref.watch(graceProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            color: Theme.of(context).colorScheme.secondary,
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
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.2),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shield,
                        size: 14,
                        color: index < graceState.weeklyGraceLeft
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.5),
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
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
