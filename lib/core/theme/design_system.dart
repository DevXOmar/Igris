import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IGRIS DESIGN SYSTEM - LOCKED CONSTANTS
/// ═══════════════════════════════════════════════════════════════════════════
///
/// This file defines the ONLY allowed values for:
/// - Spacing (padding, margins, gaps)
/// - Border radius (all rounded corners)
/// - Typography scale (text sizes and weights)
///
/// RULES:
/// 1. Never use hardcoded values - always reference these constants
/// 2. Never create custom spacing - use the scale provided
/// 3. Never use arbitrary border radius - use the standard
/// 4. Maintain consistency across all screens and components
///
/// ═══════════════════════════════════════════════════════════════════════════

class DesignSystem {
  DesignSystem._(); // Private constructor - this is a constants-only class

  /// ═══════════════════════════════════════════════════════════════════════
  /// SPACING SCALE - The ONLY allowed spacing values
  /// ═══════════════════════════════════════════════════════════════════════
  /// Use these for: padding, margins, gaps, SizedBox height/width
  ///
  /// Usage examples:
  /// - padding: EdgeInsets.all(DesignSystem.spacing16)
  /// - SizedBox(height: DesignSystem.spacing12)
  /// - gap: DesignSystem.spacing8

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0; // Extra large (rare use)

  // Common EdgeInsets constants for convenience
  static const EdgeInsets paddingAll4 = EdgeInsets.all(spacing4);
  static const EdgeInsets paddingAll8 = EdgeInsets.all(spacing8);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(spacing12);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(spacing16);
  static const EdgeInsets paddingAll24 = EdgeInsets.all(spacing24);
  static const EdgeInsets paddingAll32 = EdgeInsets.all(spacing32);

  static const EdgeInsets paddingH16 = EdgeInsets.symmetric(horizontal: spacing16);
  static const EdgeInsets paddingV16 = EdgeInsets.symmetric(vertical: spacing16);
  static const EdgeInsets paddingH24 = EdgeInsets.symmetric(horizontal: spacing24);
  static const EdgeInsets paddingV24 = EdgeInsets.symmetric(vertical: spacing24);

  /// ═══════════════════════════════════════════════════════════════════════
  /// BORDER RADIUS - The ONLY allowed border radius values
  /// ═══════════════════════════════════════════════════════════════════════
  /// Standard: 16px for all major UI elements (cards, buttons, inputs)
  /// Small: 12px for compact elements, nested items
  /// Large: 24px for modal dialogs, large cards
  ///
  /// Usage:
  /// - borderRadius: DesignSystem.radiusStandard
  /// - BorderRadius.circular(DesignSystem.radius16)

  static const double radius12 = 12.0;
  static const double radius16 = 16.0;  // STANDARD - Use this by default
  static const double radius24 = 24.0;

  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(radius12));
  static const BorderRadius radiusStandard = BorderRadius.all(Radius.circular(radius16));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(radius24));

  /// ═══════════════════════════════════════════════════════════════════════
  /// TYPOGRAPHY SCALE - Locked text sizes
  /// ═══════════════════════════════════════════════════════════════════════
  /// Use Theme.of(context).textTheme instead of these raw values
  /// These are documented here for reference and consistency
  ///
  /// Display: 32, 28 (Hero/Page titles)
  /// Headline: 24, 20 (Section headers)
  /// Title: 18, 16, 14 (Card/Widget titles)
  /// Body: 16, 14, 12 (Content text)
  /// Label: 14, 12, 10 (Buttons, tags, metadata)

  // Display Scale (Hero text, page titles)
  static const double fontDisplay1 = 32.0; // displayLarge
  static const double fontDisplay2 = 28.0; // displayMedium

  // Headline Scale (Major section headers)
  static const double fontHeadline1 = 24.0; // headlineLarge
  static const double fontHeadline2 = 20.0; // headlineMedium

  // Title Scale (Card titles, widget headers)
  static const double fontTitle1 = 18.0; // titleLarge
  static const double fontTitle2 = 16.0; // titleMedium
  static const double fontTitle3 = 14.0; // titleSmall

  // Body Scale (Main content)
  static const double fontBody1 = 16.0; // bodyLarge
  static const double fontBody2 = 14.0; // bodyMedium
  static const double fontBody3 = 12.0; // bodySmall

  // Label Scale (Buttons, metadata, tags)
  static const double fontLabel1 = 14.0; // labelLarge
  static const double fontLabel2 = 12.0; // labelMedium
  static const double fontLabel3 = 10.0; // labelSmall

  /// ═══════════════════════════════════════════════════════════════════════
  /// ICON SIZES - Standard icon dimensions
  /// ═══════════════════════════════════════════════════════════════════════

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  static const double iconHero = 64.0;

  /// ═══════════════════════════════════════════════════════════════════════
  /// ELEVATION & SHADOWS - Standard elevation levels
  /// ═══════════════════════════════════════════════════════════════════════
  /// 
  /// Elevation creates depth hierarchy in the UI. Use consistently:
  /// 
  /// elevation0 (0dp) - Flat elements
  ///   • Cards flush with background
  ///   • Buttons (use borders instead)
  ///   • List items
  ///   • Most UI elements (Igris style is flat)
  /// 
  /// elevation1 (1dp) - Subtle lift
  ///   • Hover states (rare - prefer glow effects)
  ///   • Nested cards
  /// 
  /// elevation2 (2dp) - Standard elevation
  ///   • Resting cards (if needed)
  ///   • App bar (if not transparent)
  /// 
  /// elevation4 (4dp) - Floating elements
  ///   • FAB (Floating Action Button)
  ///   • Active states
  ///   • Dragged elements
  /// 
  /// elevation8 (8dp) - Modal surfaces
  ///   • Dialogs
  ///   • Modal sheets
  ///   • Dropdown menus
  ///   • Navigation drawer
  /// 
  /// RULE: Igris design prefers FLAT (elevation0) with GLOWS over traditional shadows.
  /// Use AppTheme.blueGlowSubtle/Strong, redGlowSubtle, or purpleGlow* for depth.

  static const double elevation0 = 0.0;  // Flat (default)
  static const double elevation1 = 1.0;  // Subtle
  static const double elevation2 = 2.0;  // Standard
  static const double elevation4 = 4.0;  // Floating
  static const double elevation8 = 8.0;  // Modal

  /// ═══════════════════════════════════════════════════════════════════════
  /// DIVIDER & BORDER WIDTHS - Standard line thicknesses
  /// ═══════════════════════════════════════════════════════════════════════

  static const double borderThin = 1.0;
  static const double borderMedium = 2.0;
  static const double borderThick = 3.0;

  /// ═══════════════════════════════════════════════════════════════════════
  /// QUICK ACCESS HELPERS
  /// ═══════════════════════════════════════════════════════════════════════

  /// Standard card decoration
  static BoxDecoration cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: radiusStandard,
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: borderThin,
      ),
    );
  }

  /// Elevated card decoration
  static BoxDecoration elevatedCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: radiusStandard,
      border: Border.all(
        color: Theme.of(context).dividerColor,
        width: borderThin,
      ),
    );
  }
}
