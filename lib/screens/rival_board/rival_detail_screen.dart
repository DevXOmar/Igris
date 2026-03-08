import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../models/rival.dart';
import '../../providers/rival_provider.dart';
import '../../widgets/ui/igris_button.dart';
import '../../widgets/ui/igris_card.dart';
import 'add_rival_bottom_sheet.dart';

/// Full detail view for a single rival.
///
/// Shows description, last achievement, last updated, threat level,
/// and provides Edit / Delete actions.
class RivalDetailScreen extends ConsumerWidget {
  final Rival rival;

  const RivalDetailScreen({super.key, required this.rival});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep card in sync if the user edits while on this screen.
    final currentRival = ref.watch(rivalProvider).rivals.firstWhere(
          (r) => r.id == rival.id,
          orElse: () => rival,
        );

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Rival Board',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.neonBlue.withValues(alpha: 0.2),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.neonBlue),
            onPressed: () => _openEdit(context),
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.bloodRed),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: DesignSystem.paddingAll16,
          children: [
            // -- Header card: name + domain + threat
            IgrisCard(
              variant: IgrisCardVariant.elevated,
              padding: DesignSystem.paddingAll16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          currentRival.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      if (currentRival.threatLevel != null) ...[
                        SizedBox(width: DesignSystem.spacing12),
                        _ThreatBadge(level: currentRival.threatLevel!),
                      ],
                    ],
                  ),
                  SizedBox(height: DesignSystem.spacing8),
                  _DomainTag(label: currentRival.domain),
                ],
              ),
            ),

            SizedBox(height: DesignSystem.spacing12),

            // -- Description / why they matter
            if (currentRival.description.trim().isNotEmpty) ...[
              _SectionLabel(label: 'Why they matter'),
              SizedBox(height: DesignSystem.spacing8),
              IgrisCard(
                variant: IgrisCardVariant.elevated,
                padding: DesignSystem.paddingAll16,
                child: Text(
                  currentRival.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                ),
              ),
              SizedBox(height: DesignSystem.spacing12),
            ],

            // -- Last achievement
            _SectionLabel(label: 'Last Achievement'),
            SizedBox(height: DesignSystem.spacing8),
            IgrisCard(
              variant: IgrisCardVariant.elevated,
              padding: DesignSystem.paddingAll16,
              child: currentRival.lastAchievement.trim().isEmpty
                  ? Text(
                      'No achievement recorded yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                    )
                  : Text(
                      currentRival.lastAchievement,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                    ),
            ),

            SizedBox(height: DesignSystem.spacing12),

            // -- Metadata row
            IgrisCard(
              variant: IgrisCardVariant.surface,
              padding: DesignSystem.paddingAll16,
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: DesignSystem.iconSmall,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: DesignSystem.spacing8),
                  Text(
                    'Updated ${DateFormat('MMM d, yyyy').format(currentRival.lastUpdated)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),

            SizedBox(height: DesignSystem.spacing24),

            // -- Actions
            Row(
              children: [
                Expanded(
                  child: IgrisButton(
                    text: 'Edit',
                    variant: IgrisButtonVariant.outline,
                    icon: Icons.edit_outlined,
                    fullWidth: true,
                    onPressed: () => _openEdit(context),
                  ),
                ),
                SizedBox(width: DesignSystem.spacing12),
                Expanded(
                  child: IgrisButton(
                    text: 'Delete',
                    variant: IgrisButtonVariant.destructive,
                    icon: Icons.delete_outline,
                    fullWidth: true,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddRivalBottomSheet(existing: rival),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text(
          'Remove Rival?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          '${rival.name} will be permanently removed from your board.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(rivalProvider.notifier).deleteRival(rival.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.bloodRed)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small shared sub-widgets used only by this screen (and the board screen).
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _DomainTag extends StatelessWidget {
  final String label;
  const _DomainTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing12,
        vertical: DesignSystem.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.neonBlue.withValues(alpha: 0.10),
        borderRadius: DesignSystem.radiusSmall,
        border: Border.all(
          color: AppColors.neonBlue.withValues(alpha: 0.35),
          width: DesignSystem.borderThin,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.neonBlue,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _ThreatBadge extends StatelessWidget {
  final int level; // 1-5
  const _ThreatBadge({required this.level});

  Color get _color {
    if (level <= 2) return AppColors.deepBlue;
    if (level == 3) return AppColors.royalGold;
    return AppColors.bloodRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing8,
        vertical: DesignSystem.spacing4,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: DesignSystem.radiusSmall,
        border: Border.all(
          color: _color.withValues(alpha: 0.5),
          width: DesignSystem.borderThin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: DesignSystem.iconSmall, color: _color),
          SizedBox(width: DesignSystem.spacing4),
          Text(
            '$level / 5',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
