import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';

/// Igris-themed card styled with Igris theme system
/// Uses Igris surface color, thin neon border, locked border radius
class IgrisCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final IgrisCardVariant variant;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showGlow;

  const IgrisCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = IgrisCardVariant.elevated,
    this.onTap,
    this.showBorder = true,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: padding ?? DesignSystem.paddingAll16,
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: DesignSystem.radiusStandard,
        border: showBorder ? _getBorder() : null,
        boxShadow: showGlow ? _getGlowEffect(colorScheme) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: DesignSystem.radiusStandard,
                child: child,
              )
            : child,
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case IgrisCardVariant.elevated:
        return AppColors.backgroundElevated;
      case IgrisCardVariant.surface:
        return AppColors.surfaceContainer;
      case IgrisCardVariant.transparent:
        return Colors.transparent;
    }
  }

  Border? _getBorder() {
    if (!showBorder) return null;
    
    switch (variant) {
      case IgrisCardVariant.elevated:
        return Border.all(
          color: AppColors.neonBlue.withOpacity(0.2),
          width: 1.0,
        );
      case IgrisCardVariant.surface:
        return Border.all(
          color: AppColors.border.withOpacity(0.3),
          width: 1.0,
        );
      case IgrisCardVariant.transparent:
        return null;
    }
  }

  List<BoxShadow>? _getGlowEffect(ColorScheme colorScheme) {
    if (!showGlow) return null;
    return colorScheme.blueGlowSubtle;
  }
}

enum IgrisCardVariant {
  elevated,     // Elevated background with neon border
  surface,      // Surface container with subtle border
  transparent,  // Transparent background, no border
}
