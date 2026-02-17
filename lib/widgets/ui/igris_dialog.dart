import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import 'igris_button.dart';

/// Igris-themed dialog styled with Igris theme system
/// Uses Igris surface background, gold title accent, IgrisButton for actions
class IgrisDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String description,
    List<IgrisDialogAction>? actions,
    Widget? content,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.radiusLarge,
          side: BorderSide(
            color: AppColors.neonBlue.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignSystem.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: DesignSystem.spacing12),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (content != null) ...[
                SizedBox(height: DesignSystem.spacing16),
                content,
              ],
              if (actions != null && actions.isNotEmpty) ...[
                SizedBox(height: DesignSystem.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions
                      .map(
                        (action) => Padding(
                          padding: EdgeInsets.only(left: DesignSystem.spacing8),
                          child: IgrisButton(
                            text: action.label,
                            onPressed: () {
                              if (action.autoDismiss) {
                                Navigator.of(context).pop(action.result);
                              }
                              action.onPressed?.call();
                            },
                            variant: action.variant,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Confirmation dialog with destructive action
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String description,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      description: description,
      actions: [
        IgrisDialogAction(
          label: cancelLabel,
          variant: IgrisButtonVariant.ghost,
          autoDismiss: true,
          result: false,
        ),
        IgrisDialogAction(
          label: confirmLabel,
          variant: isDestructive 
              ? IgrisButtonVariant.destructive 
              : IgrisButtonVariant.primary,
          autoDismiss: true,
          result: true,
        ),
      ],
    );
  }
}

class IgrisDialogAction<T> {
  final String label;
  final VoidCallback? onPressed;
  final IgrisButtonVariant variant;
  final bool autoDismiss;
  final T? result;

  const IgrisDialogAction({
    required this.label,
    this.onPressed,
    this.variant = IgrisButtonVariant.primary,
    this.autoDismiss = true,
    this.result,
  });
}
