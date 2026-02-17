import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';

/// Igris-themed switch styled with Igris theme system
/// Uses neon blue accent color
class IgrisSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const IgrisSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final switchWidget = Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.neonBlue,
      activeTrackColor: AppColors.neonBlue.withOpacity(0.3),
      inactiveThumbColor: AppColors.textSecondary,
      inactiveTrackColor: AppColors.backgroundElevated,
    );

    if (label == null) {
      return switchWidget;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            label!,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(width: DesignSystem.spacing12),
        switchWidget,
      ],
    );
  }
}

/// Igris-themed checkbox styled with Igris theme system
/// Uses neon blue accent color
class IgrisCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const IgrisCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final checkboxWidget = Checkbox(
      value: value,
      onChanged: onChanged != null ? (value) => onChanged!(value!) : null,
      activeColor: AppColors.neonBlue,
      checkColor: AppColors.backgroundPrimary,
      side: BorderSide(
        color: AppColors.border.withOpacity(0.3),
        width: 1.5,
      ),
    );

    if (label == null) {
      return checkboxWidget;
    }

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: Row(
        children: [
          checkboxWidget,
          SizedBox(width: DesignSystem.spacing12),
          Expanded(
            child: Text(
              label!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
