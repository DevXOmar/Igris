import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../models/rival.dart';
import '../../providers/rival_provider.dart';
import '../../widgets/ui/igris_button.dart';
import '../../widgets/ui/igris_input_field.dart';

/// Reusable bottom sheet for both adding and editing a rival.
///
/// Pass [existing] to pre-populate all fields for edit mode.
class AddRivalBottomSheet extends ConsumerStatefulWidget {
  final Rival? existing;

  const AddRivalBottomSheet({super.key, this.existing});

  @override
  ConsumerState<AddRivalBottomSheet> createState() => _AddRivalBottomSheetState();
}

class _AddRivalBottomSheetState extends ConsumerState<AddRivalBottomSheet> {
  final _nameCtrl = TextEditingController();
  final _domainCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _achievementCtrl = TextEditingController();
  int? _threatLevel;
  RivalCategory _category = RivalCategory.proximal;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final r = widget.existing!;
      _nameCtrl.text = r.name;
      _domainCtrl.text = r.domain;
      _descCtrl.text = r.description;
      _achievementCtrl.text = r.lastAchievement;
      _threatLevel = r.threatLevel;
      _category = r.category;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _domainCtrl.dispose();
    _descCtrl.dispose();
    _achievementCtrl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.existing != null;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final domain = _domainCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final achievement = _achievementCtrl.text.trim();

    if (name.isEmpty || domain.isEmpty) return;

    setState(() => _saving = true);

    final notifier = ref.read(rivalProvider.notifier);

    if (_isEdit) {
      await notifier.updateRival(
        widget.existing!.copyWith(
          name: name,
          domain: domain,
          description: description.isEmpty ? '' : description,
          lastAchievement: achievement.isEmpty ? '' : achievement,
          lastUpdated: DateTime.now(),
          threatLevel: _threatLevel,
          category: _category,
          clearThreatLevel: _threatLevel == null,
        ),
      );
    } else {
      await notifier.addRival(
        Rival(
          id: const Uuid().v4(),
          name: name,
          domain: domain,
          description: description,
          lastAchievement: achievement,
          lastUpdated: DateTime.now(),
          threatLevel: _threatLevel,
          categoryKey: _category.key,
        ),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignSystem.radius24),
            topRight: Radius.circular(DesignSystem.radius24),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.neonBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // drag handle
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // title
            Padding(
              padding: EdgeInsets.fromLTRB(
                DesignSystem.spacing16,
                DesignSystem.spacing4,
                DesignSystem.spacing16,
                DesignSystem.spacing16,
              ),
              child: Text(
                _isEdit ? 'Edit Rival' : 'Add Rival',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // form – scrollable so keyboard doesn't clip content
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  DesignSystem.spacing16,
                  0,
                  DesignSystem.spacing16,
                  DesignSystem.spacing16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IgrisInputField(
                      label: 'Name *',
                      hint: 'e.g. John Doe',
                      controller: _nameCtrl,
                      autofocus: !_isEdit,
                    ),
                    SizedBox(height: DesignSystem.spacing12),
                    IgrisInputField(
                      label: 'Domain *',
                      hint: 'e.g. AI, Fitness, Career',
                      controller: _domainCtrl,
                    ),
                    SizedBox(height: DesignSystem.spacing12),
                    IgrisInputField(
                      label: 'Why they matter',
                      hint: 'Private note — why you track this person.',
                      controller: _descCtrl,
                      maxLines: 3,
                    ),
                    SizedBox(height: DesignSystem.spacing12),
                    IgrisInputField(
                      label: 'Last Achievement',
                      hint: 'Raised Series A, ran a marathon...',
                      controller: _achievementCtrl,
                      maxLines: 2,
                    ),
                    SizedBox(height: DesignSystem.spacing16),

                    // Category
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: DesignSystem.spacing8),
                    _CategoryPicker(
                      value: _category,
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    SizedBox(height: DesignSystem.spacing16),

                    // Threat level
                    Text(
                      'Threat Level (optional)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    SizedBox(height: DesignSystem.spacing8),
                    _ThreatLevelPicker(
                      value: _threatLevel,
                      onChanged: (v) => setState(() => _threatLevel = v),
                    ),
                    SizedBox(height: DesignSystem.spacing24),

                    IgrisButton(
                      text: _isEdit ? 'Save Changes' : 'Add Rival',
                      variant: IgrisButtonVariant.primary,
                      icon: _isEdit ? Icons.check : Icons.add,
                      fullWidth: true,
                      isLoading: _saving,
                      onPressed: _save,
                    ),
                    SizedBox(height: DesignSystem.spacing8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of five tappable intensity bars — the selected level and everything
/// below it are lit in a blood-red-to-neon-blue gradient of urgency.
class _ThreatLevelPicker extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const _ThreatLevelPicker({required this.value, required this.onChanged});

  static const _labels = ['Low', '', 'Mid', '', 'High'];

  Color _barColor(int level) {
    switch (level) {
      case 1:
        return AppColors.deepBlue;
      case 2:
        return AppColors.neonBlue;
      case 3:
        return AppColors.royalGold;
      case 4:
        return AppColors.bloodRedActive;
      default:
        return AppColors.bloodRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final level = i + 1;
        final isActive = value != null && level <= value!;
        final color = isActive ? _barColor(level) : AppColors.backgroundElevated;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value == level ? null : level),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 28,
                  margin: EdgeInsets.symmetric(horizontal: DesignSystem.spacing4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: DesignSystem.radiusSmall,
                    border: Border.all(
                      color: isActive
                          ? color
                          : AppColors.textMuted.withValues(alpha: 0.3),
                      width: DesignSystem.borderThin,
                    ),
                  ),
                ),
                SizedBox(height: DesignSystem.spacing4),
                Text(
                  _labels[i],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isActive ? color : AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final RivalCategory value;
  final ValueChanged<RivalCategory> onChanged;

  const _CategoryPicker({required this.value, required this.onChanged});

  Color _accent(RivalCategory c) {
    return switch (c) {
      RivalCategory.proximal => AppColors.neonBlue,
      RivalCategory.apex => AppColors.shadowPurple,
      RivalCategory.mythic => AppColors.royalGold,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignSystem.spacing8,
      runSpacing: DesignSystem.spacing8,
      children: RivalCategory.values.map((c) {
        final selected = c == value;
        final accent = _accent(c);

        return ChoiceChip(
          label: Text(c.label),
          selected: selected,
          onSelected: (_) => onChanged(c),
          selectedColor: accent.withValues(alpha: 0.18),
          backgroundColor: AppColors.backgroundElevated,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? accent : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
          side: BorderSide(
            color: selected
                ? accent.withValues(alpha: 0.75)
                : AppColors.textMuted.withValues(alpha: 0.25),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }).toList(),
    );
  }
}
