import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/fuel_vault_entry.dart';
import '../../providers/fuel_vault_provider.dart';
import 'edit_fuel_info_bottom_sheet.dart';

class FuelVaultEntryDetailScreen extends ConsumerWidget {
  final FuelVaultEntry entry;

  const FuelVaultEntryDetailScreen({
    super.key,
    required this.entry,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text(
          'Delete Entry',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Remove this image from your vault?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(fuelVaultProvider.notifier).deleteEntry(entry.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestEntry = (() {
      final entries = ref.watch(fuelVaultProvider).entries;
      for (final e in entries) {
        if (e.id == entry.id) return e;
      }
      return entry;
    })();

    final dateText = app_date_utils.DateUtils.formatDateLong(latestEntry.createdAt);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text('Fuel Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => EditFuelInfoBottomSheet(entry: latestEntry),
              );
            },
            tooltip: 'Edit info',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Full image viewer
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Center(
                    child: Hero(
                      tag: 'fuel-vault-${latestEntry.id}',
                      child: kIsWeb
                          ? Image.network(
                              latestEntry.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textMuted,
                                size: 64,
                              ),
                            )
                          : Image.file(
                              File(latestEntry.imagePath),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textMuted,
                                size: 64,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Metadata panel
            Container(
              width: double.infinity,
              padding: DesignSystem.paddingAll16,
              decoration: BoxDecoration(
                color: AppColors.backgroundSurface,
                border: Border(
                  top: BorderSide(
                    color: AppColors.neonBlue.withOpacity(0.2),
                    width: DesignSystem.borderThin,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (latestEntry.title != null) ...[
                    Text(
                      latestEntry.title!,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: DesignSystem.spacing8),
                  ],
                  if (latestEntry.category != null) ...[
                    Text(
                      latestEntry.category!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.neonBlue,
                            letterSpacing: 0.6,
                          ),
                    ),
                    SizedBox(height: DesignSystem.spacing8),
                  ],
                  if (latestEntry.note != null && latestEntry.note!.trim().isNotEmpty) ...[
                    Text(
                      latestEntry.note!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    SizedBox(height: DesignSystem.spacing12),
                  ],
                  Text(
                    'Added: $dateText',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
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

