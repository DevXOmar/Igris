import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../models/fuel_vault_entry.dart';
import '../../providers/fuel_vault_provider.dart';

class EditFuelInfoBottomSheet extends ConsumerStatefulWidget {
  final FuelVaultEntry entry;

  const EditFuelInfoBottomSheet({
    super.key,
    required this.entry,
  });

  @override
  ConsumerState<EditFuelInfoBottomSheet> createState() => _EditFuelInfoBottomSheetState();
}

class _EditFuelInfoBottomSheetState extends ConsumerState<EditFuelInfoBottomSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _categoryCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.entry.title ?? '');
    _noteCtrl = TextEditingController(text: widget.entry.note ?? '');
    _categoryCtrl = TextEditingController(text: widget.entry.category ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    String? toNullable(String v) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final updated = FuelVaultEntry(
      id: widget.entry.id,
      imagePath: widget.entry.imagePath,
      title: toNullable(_titleCtrl.text),
      note: toNullable(_noteCtrl.text),
      category: toNullable(_categoryCtrl.text),
      createdAt: widget.entry.createdAt,
    );

    await ref.read(fuelVaultProvider.notifier).updateEntry(updated);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_isSaving;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.45,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      'Edit Info',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppColors.dividerColor),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildField(
                        controller: _titleCtrl,
                        label: 'Title (optional)',
                        hint: 'e.g. Power',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _noteCtrl,
                        label: 'Note (optional)',
                        hint: 'A reminder or thought...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: _categoryCtrl,
                        label: 'Category (optional)',
                        hint: 'e.g. Mind, Power, Revenge',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: canSave ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSave
                                ? AppColors.neonBlue.withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: BorderSide(
                              color: canSave ? AppColors.neonBlue : AppColors.dividerColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: DesignSystem.radiusStandard,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonBlue,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: const BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: const BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
