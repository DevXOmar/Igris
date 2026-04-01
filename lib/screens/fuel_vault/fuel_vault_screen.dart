import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// responsive_framework: CrossAxisCount adapts to MOBILE / TABLET / DESKTOP
import 'package:responsive_framework/responsive_framework.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../models/fuel_vault_entry.dart';
import '../../providers/fuel_vault_provider.dart';
import '../../widgets/layout/igris_screen_scaffold.dart';
import 'add_fuel_bottom_sheet.dart';
import 'edit_fuel_info_bottom_sheet.dart';
import 'fuel_vault_entry_detail_screen.dart';

class FuelVaultScreen extends ConsumerWidget {
  const FuelVaultScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFuelBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fuelVaultProvider);

    return IgrisScreenScaffold(
      title: 'Fuel Vault',
      applyPadding: false,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        backgroundColor: AppColors.backgroundElevated,
        foregroundColor: AppColors.neonBlue,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      child: state.entries.isEmpty
          ? _EmptyFuelVault(onAdd: () => _openAddSheet(context))
          : Builder(
              builder: (innerContext) {
                // responsive_framework: derive column count from active breakpoint
                //   MOBILE  ( ≤ 480 px ) → 3 columns
                //   TABLET  ( ≤ 1024 px) → 4 columns
                //   DESKTOP ( > 1024 px ) → 5 columns
                final bp = ResponsiveBreakpoints.of(innerContext);
                final crossAxisCount =
                    bp.largerThan(TABLET) ? 5 : bp.largerThan(MOBILE) ? 4 : 3;
                return GridView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.all(DesignSystem.spacing16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: state.entries.length,
                  itemBuilder: (context, index) {
                    final entry = state.entries[index];
                    return _FuelVaultGridTile(
                      entry: entry,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FuelVaultEntryDetailScreen(entry: entry),
                          ),
                        );
                      },
                      onLongPress: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => EditFuelInfoBottomSheet(entry: entry),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptyFuelVault extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyFuelVault({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: DesignSystem.paddingAll16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: DesignSystem.iconHero,
              color: AppColors.textMuted,
            ),
            SizedBox(height: DesignSystem.spacing16),
            Text(
              'Vault is empty',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignSystem.spacing8),
            Text(
              'Add images that lock your mindset in place.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignSystem.spacing24),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add First Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonBlue,
                side: const BorderSide(color: AppColors.neonBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelVaultGridTile extends StatelessWidget {
  final FuelVaultEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FuelVaultGridTile({
    required this.entry,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: DesignSystem.radiusSmall,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.backgroundElevated,
            borderRadius: DesignSystem.radiusSmall,
            border: Border.all(
              color: AppColors.neonBlue.withValues(alpha: 0.2),
              width: DesignSystem.borderThin,
            ),
          ),
          child: ClipRRect(
            borderRadius: DesignSystem.radiusSmall,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'fuel-vault-${entry.id}',
                  child: kIsWeb
                      ? Image.network(
                          entry.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.backgroundElevated,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Image.file(
                          File(entry.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.backgroundElevated,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                ),
                if (entry.category != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: EdgeInsets.all(DesignSystem.spacing8),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignSystem.spacing8,
                          vertical: DesignSystem.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSurface.withValues(alpha: 0.85),
                          borderRadius: DesignSystem.radiusSmall,
                          border: Border.all(
                            color: AppColors.neonBlue.withValues(alpha: 0.15),
                            width: DesignSystem.borderThin,
                          ),
                        ),
                        child: Text(
                          entry.category!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textPrimary,
                                letterSpacing: 0.6,
                              ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
