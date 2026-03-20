import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../providers/rival_provider.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';
import 'add_rival_bottom_sheet.dart';
import 'widgets/rival_network_view.dart';

/// Main Rival Board screen — strategic intelligence dashboard.
///
/// Shows all rivals as scrollable cards sorted by last-updated date.
/// FAB opens the Add Rival sheet.
class RivalBoardScreen extends ConsumerWidget {
  const RivalBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rivalProvider);

    return IgrisScreenScaffold(
      title: 'Rival Network',
      applyPadding: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        backgroundColor: AppColors.backgroundElevated,
        foregroundColor: AppColors.neonBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.radiusStandard,
          side: BorderSide(
            color: AppColors.neonBlue.withValues(alpha: 0.6),
            width: DesignSystem.borderThin,
          ),
        ),
        label: const Text(
          'Add Rival',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        icon: const Icon(Icons.add, size: 20),
      ),
      child: state.rivals.isEmpty
          ? _buildEmpty(context)
          : Padding(
              padding: EdgeInsets.fromLTRB(
                DesignSystem.spacing12,
                DesignSystem.spacing12,
                DesignSystem.spacing12,
                DesignSystem.spacing12 + 72, // clear FAB
              ),
              child: RivalNetworkView(rivals: state.rivals),
            ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: DesignSystem.paddingAll32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar,
              size: DesignSystem.iconHero,
              color: AppColors.textMuted,
            ),
            SizedBox(height: DesignSystem.spacing16),
            Text(
              'No rivals tracked',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
            SizedBox(height: DesignSystem.spacing8),
            Text(
              'Add people who push you to be better.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AddRivalBottomSheet(),
    );
  }
}
