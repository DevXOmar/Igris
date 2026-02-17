import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';

/// Igris-themed button styled with Igris theme system
/// Maintains Igris color palette, spacing, and border radius
class IgrisButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IgrisButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const IgrisButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = IgrisButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget button = Material(
      color: _getBackgroundColor(colorScheme),
      borderRadius: DesignSystem.radiusStandard,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: DesignSystem.radiusStandard,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing16,
            vertical: DesignSystem.spacing12,
          ),
          decoration: BoxDecoration(
            borderRadius: DesignSystem.radiusStandard,
            border: Border.all(
              color: _getBorderColor(colorScheme),
              width: variant == IgrisButtonVariant.outline ? 1.5 : 1.0,
            ),
            boxShadow: variant == IgrisButtonVariant.primary 
              ? colorScheme.blueGlowSubtle
              : null,
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: DesignSystem.iconMedium,
                  height: DesignSystem.iconMedium,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _getTextColor(colorScheme),
                  ),
                )
              else if (icon != null) ...[
                Icon(
                  icon,
                  size: DesignSystem.iconMedium,
                  color: _getTextColor(colorScheme),
                ),
                SizedBox(width: DesignSystem.spacing8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: _getTextColor(colorScheme),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case IgrisButtonVariant.primary:
        return AppColors.neonBlue.withOpacity(0.15);
      case IgrisButtonVariant.destructive:
        return AppColors.bloodRed.withOpacity(0.15);
      case IgrisButtonVariant.outline:
      case IgrisButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    switch (variant) {
      case IgrisButtonVariant.primary:
        return AppColors.neonBlue;
      case IgrisButtonVariant.destructive:
        return AppColors.bloodRed;
      case IgrisButtonVariant.outline:
        return AppColors.neonBlue.withOpacity(0.5);
      case IgrisButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (variant) {
      case IgrisButtonVariant.primary:
        return AppColors.neonBlue;
      case IgrisButtonVariant.destructive:
        return AppColors.bloodRed;
      case IgrisButtonVariant.outline:
        return AppColors.textPrimary;
      case IgrisButtonVariant.ghost:
        return AppColors.textSecondary;
    }
  }
}

enum IgrisButtonVariant {
  primary,      // Neon blue border + glow
  destructive,  // Blood red border
  outline,      // Subtle border, transparent bg
  ghost,        // No border, minimal style
}
