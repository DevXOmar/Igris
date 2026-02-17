import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';

/// Igris-themed screen scaffold providing consistent layout across all screens
/// 
/// Features:
/// - Consistent AppBar styling (neon blue accents)
/// - Standard horizontal padding (16px)
/// - SafeArea handling
/// - Background color from theme
/// 
/// Usage:
/// ```dart
/// IgrisScreenScaffold(
///   title: 'Calendar',
///   child: YourContent(),
/// )
/// ```
class IgrisScreenScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool applyPadding;

  const IgrisScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.applyPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: AppColors.backgroundSurface,
        elevation: 0,
        actions: actions,
        // Subtle bottom border for definition
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.neonBlue.withOpacity(0.2),
            height: 1,
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: applyPadding
            ? Padding(
                padding: DesignSystem.paddingH16,
                child: child,
              )
            : child,
      ),
    );
  }
}
