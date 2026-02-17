import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';

/// Igris-themed bottom sheet styled with Igris theme system
/// Uses surfaceContainer background, rounded top corners
class IgrisBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool showDragHandle = true,
    bool enableDrag = true,
    double? initialChildSize,
    double? minChildSize,
    double? maxChildSize,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignSystem.radius24),
            topRight: Radius.circular(DesignSystem.radius24),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.neonBlue.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              Padding(
                padding: EdgeInsets.symmetric(vertical: DesignSystem.spacing8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (title != null)
              Padding(
                padding: DesignSystem.paddingAll16,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  /// Scrollable bottom sheet with list of items
  static Future<T?> showList<T>({
    required BuildContext context,
    required String title,
    required List<IgrisBottomSheetItem<T>> items,
  }) {
    return show<T>(
      context: context,
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          color: AppColors.border.withOpacity(0.2),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: item.icon != null
                ? Icon(
                    item.icon,
                    color: item.isDestructive 
                        ? AppColors.bloodRed 
                        : AppColors.neonBlue,
                    size: DesignSystem.iconLarge,
                  )
                : null,
            title: Text(
              item.label,
              style: TextStyle(
                color: item.isDestructive 
                    ? AppColors.bloodRed 
                    : AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            subtitle: item.subtitle != null
                ? Text(
                    item.subtitle!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  )
                : null,
            onTap: () {
              Navigator.of(context).pop(item.value);
              item.onTap?.call();
            },
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesignSystem.spacing16,
              vertical: DesignSystem.spacing8,
            ),
          );
        },
      ),
    );
  }
}

class IgrisBottomSheetItem<T> {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;
  final T? value;
  final bool isDestructive;

  const IgrisBottomSheetItem({
    required this.label,
    this.subtitle,
    this.icon,
    this.onTap,
    this.value,
    this.isDestructive = false,
  });
}
