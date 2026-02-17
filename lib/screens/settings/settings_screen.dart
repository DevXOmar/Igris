import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../providers/grace_provider.dart';
import '../../providers/domain_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/ui/igris_ui.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';

/// Settings screen for app configuration and grace token management
/// Refactored with Igris UI components for consistent styling
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graceState = ref.watch(graceProvider);
    final domainState = ref.watch(domainProvider);
    final taskState = ref.watch(taskProvider);
    
    final daysUntilReset = ref.read(graceProvider.notifier).getDaysUntilReset();

    return IgrisScreenScaffold(
      title: 'Settings',
      applyPadding: false,
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: DesignSystem.paddingAll16,
        children: [
          // Grace System Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'Grace System',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  _buildInfoRow(
                    context,
                    'Weekly Grace Tokens',
                    '${graceState.weeklyGraceLeft} / ${graceState.maxGraceTokens}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Days Until Reset',
                    '$daysUntilReset days',
                  ),
                  if (graceState.lastResetDate != null) ...
                    [
                    SizedBox(height: DesignSystem.spacing8),
                    _buildInfoRow(
                      context,
                      'Last Reset',
                      '${graceState.lastResetDate?.day}/${graceState.lastResetDate?.month}/${graceState.lastResetDate?.year}',
                    ),
                  ],
                  SizedBox(height: DesignSystem.spacing16),
                  Divider(color: AppColors.neonBlue.withValues(alpha: 0.2)),
                  SizedBox(height: DesignSystem.spacing8),
                  const Text(
                    'Grace tokens allow you to skip a day without breaking your streak. They reset every week.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),
          
          // Statistics Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'Statistics',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  _buildInfoRow(
                    context,
                    'Total Domains',
                    '${domainState.domains.length}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Active Domains',
                    '${domainState.activeDomains.length}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Total Tasks',
                    '${taskState.tasks.length}',
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(
                    context,
                    'Recurring Tasks',
                    '${taskState.recurringTasks.length}',
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),
          
          // Domain Strengths Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'Domain Strengths',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  if (domainState.domains.isEmpty)
                    const Text(
                      'No domains yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  else
                    ...domainState.domains.map((domain) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildInfoRow(
                            context,
                            domain.name,
                            'Strength: ${domain.strength}',
                          ),
                        )),
                ],
              ),
            ),
          ),
          
          SizedBox(height: DesignSystem.spacing16),
          
          // App Info Section
          IgrisCard(
            variant: IgrisCardVariant.elevated,
            child: Padding(
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.gold,
                      ),
                      SizedBox(width: DesignSystem.spacing8),
                      Text(
                        'About',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing16),
                  _buildInfoRow(context, 'App Name', 'Igris'),
                  SizedBox(height: DesignSystem.spacing8),
                  _buildInfoRow(context, 'Version', '1.0.0'),
                  SizedBox(height: DesignSystem.spacing16),
                  Divider(color: AppColors.neonBlue.withValues(alpha: 0.2)),
                  SizedBox(height: DesignSystem.spacing8),
                  const Text(
                    'A personal productivity and identity-tracking app.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.neonBlue,
          ),
        ),
      ],
    );
  }
}
