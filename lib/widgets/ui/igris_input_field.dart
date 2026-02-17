import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';

/// Igris-themed input field styled with Igris theme system
/// Maintains Igris colors, spacing, and border radius
class IgrisInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool autofocus;

  const IgrisInputField({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: DesignSystem.spacing8),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: autofocus,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.5),
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    size: DesignSystem.iconMedium,
                    color: AppColors.textSecondary,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixIconTap,
                    child: Icon(
                      suffixIcon,
                      size: DesignSystem.iconMedium,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.backgroundElevated,
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesignSystem.spacing16,
              vertical: DesignSystem.spacing12,
            ),
            border: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: BorderSide(
                color: hasError 
                    ? AppColors.bloodRed 
                    : AppColors.border.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: BorderSide(
                color: hasError 
                    ? AppColors.bloodRed 
                    : AppColors.border.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: BorderSide(
                color: hasError 
                    ? AppColors.bloodRed 
                    : AppColors.neonBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: BorderSide(
                color: AppColors.bloodRed,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: BorderSide(
                color: AppColors.bloodRed,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: DesignSystem.spacing4),
          Text(
            errorText!,
            style: TextStyle(
              color: AppColors.bloodRed,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
