import 'package:flutter/material.dart';
import 'design_system.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IGRIS THEME - SOLO LEVELING INSPIRED SYSTEM UI
/// ═══════════════════════════════════════════════════════════════════════════
///
/// VISUAL PHILOSOPHY:
/// A high-end dark command interface inspired by Solo Leveling's mysterious
/// system UI. This is NOT a game - it's a premium, cold, precise control panel.
///
/// DESIGN PILLARS:
/// • Deep black base with cold neon blues
/// • Blood red accents for intensity (#70020F)
/// • Royal gold for rare premium highlights (#FFD700)
/// • Subtle glow effects (never overdone)
/// • Clean, controlled, powerful aesthetic
///
/// COLOR PSYCHOLOGY:
/// - Black/Deep Navy: Mystery, control, professional power
/// - Neon Blue: Precision, system alerts, cold intelligence
/// - Blood Red: Danger, focus, intensity (sparingly)
/// - Gold: Premium achievements, rare excellence
///
/// RULES:
/// - No gradients
/// - No glassmorphism
/// - No heavy animations
/// - No playful elements
/// - Consistent BorderRadius: 14-18
/// - Slight letter spacing for headings
/// - Breathing room and spacing
///
/// INSPIRATION:
/// Solo Leveling system UI, high-end command interfaces, premium dark tools.
/// Cold. Mysterious. Controlled. Premium.
///
/// ═══════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._(); // Private constructor

  /// ═══════════════════════════════════════════════════════════════════════
  /// CORE COLOR PALETTE (EXACT HEX VALUES)
  /// ═══════════════════════════════════════════════════════════════════════

  // Base Backgrounds - Deep black system
  static const Color backgroundPrimary = Color(0xFF0A0F1C);    // Primary deep black
  static const Color backgroundSurface = Color(0xFF121A2A);    // Surface cards
  static const Color backgroundElevated = Color(0xFF182235);   // Elevated elements

  // Primary Accent Blues - Cold neon system
  static const Color neonBlue = Color(0xFF81D8F0);             // Light neon blue (glow lines)
  static const Color deepBlue = Color(0xFF4DA6C5);             // Deep cyan-blue (active)

  // Blood Red - Intensity accent
  static const Color bloodRed = Color(0xFF70020F);             // Primary red
  static const Color bloodRedActive = Color(0xFF8C0A18);       // Active red state

  // Royal Gold - Premium highlight (rare use only)
  static const Color royalGold = Color(0xFFFFD700);            // Gold accent

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFE6EDF3);          // Primary text
  static const Color textSecondary = Color(0xFF9FB3C8);        // Secondary text
  static const Color textMuted = Color(0xFF5C6B7A);            // Muted text

  // UI Elements
  static const Color dividerColor = Color(0xFF1E293B);         // Dividers

  /// ═══════════════════════════════════════════════════════════════════════
  /// DOMAIN BAR COLORS - Multi-color histogram system
  /// ═══════════════════════════════════════════════════════════════════════
  /// Each domain gets a unique color from this cycle for visual distinction.
  /// Colors are carefully selected to maintain premium dark aesthetic.

  static const List<Color> domainBarColors = [
    Color(0xFF4DA6C5),   // Deep cyan-blue
    Color(0xFF81D8F0),   // Light neon blue
    Color(0xFF70020F),   // Blood red
    Color(0xFFFFD700),   // Royal gold
    Color(0xFF1F3A8A),   // Deep navy blue
    Color(0xFF0F3460),   // Darker navy blue
  ];

  /// Get domain color by index (cycles through colors)
  static Color getDomainColor(int index) {
    return domainBarColors[index % domainBarColors.length];
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// GLOW EFFECTS - Subtle elevation system
  /// ═══════════════════════════════════════════════════════════════════════

  /// Subtle blue glow for active/hover states
  static List<BoxShadow> get blueGlowSubtle => [
    BoxShadow(
      color: neonBlue.withOpacity(0.35),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Stronger blue glow for 100% completion
  static List<BoxShadow> get blueGlowStrong => [
    BoxShadow(
      color: neonBlue.withOpacity(0.5),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Subtle red glow for warnings/intensity
  static List<BoxShadow> get redGlowSubtle => [
    BoxShadow(
      color: bloodRed.withOpacity(0.4),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  /// Default elevation shadow (no glow)
  static List<BoxShadow> get elevationShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  /// ═══════════════════════════════════════════════════════════════════════
  /// MATERIAL 3 THEME CONFIGURATION
  /// ═══════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      /// COLOR SCHEME
      colorScheme: const ColorScheme.dark(
        // Primary: Neon blue system
        primary: deepBlue,
        primaryContainer: neonBlue,

        // Secondary: Blood red accent
        secondary: bloodRed,
        secondaryContainer: bloodRedActive,

        // Tertiary: Royal gold (rare use)
        tertiary: royalGold,
        tertiaryContainer: Color(0xFFB8860B), // Darker gold

        // Surfaces
        surface: backgroundSurface,
        surfaceContainerHighest: backgroundElevated,

        // Error: Red accent
        error: bloodRedActive,

        // On colors
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,

        // Additional
        outline: dividerColor,
        shadow: Colors.black,
      ),

      /// SCAFFOLD
      scaffoldBackgroundColor: backgroundPrimary,

      /// APP BAR - Transparent with neon blue underline
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
        iconTheme: IconThemeData(color: neonBlue),
      ),

      /// CARD - Deep surface with border
      cardTheme: CardThemeData(
        color: backgroundSurface,
        elevation: DesignSystem.elevation0,
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.radiusStandard,
          side: BorderSide(
            color: dividerColor,
            width: DesignSystem.borderThin,
          ),
        ),
      ),

      /// ELEVATED BUTTON - Primary action
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundElevated,
          foregroundColor: textPrimary,
          elevation: DesignSystem.elevation0,
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing24,
            vertical: DesignSystem.spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignSystem.radiusStandard,
            side: const BorderSide(color: neonBlue, width: DesignSystem.borderThin),
          ),
        ),
      ),

      /// OUTLINED BUTTON - Secondary action
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: neonBlue, width: DesignSystem.borderThin),
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing24,
            vertical: DesignSystem.spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignSystem.radiusStandard,
          ),
        ),
      ),

      /// TEXT BUTTON - Minimal action
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonBlue,
          padding: EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing16,
            vertical: DesignSystem.spacing12,
          ),
        ),
      ),

      /// INPUT DECORATION - Form fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundElevated,
        border: OutlineInputBorder(
          borderRadius: DesignSystem.radiusStandard,
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignSystem.radiusStandard,
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignSystem.radiusStandard,
          borderSide: const BorderSide(color: neonBlue, width: DesignSystem.borderMedium),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DesignSystem.radiusStandard,
          borderSide: const BorderSide(color: bloodRed),
        ),
        contentPadding: DesignSystem.paddingAll16,
        hintStyle: const TextStyle(color: textMuted),
      ),

      /// BOTTOM NAVIGATION BAR
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundSurface,
        selectedItemColor: neonBlue,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),

      /// DIVIDER
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      /// TEXT THEME - Typography system
      textTheme: const TextTheme(
        // Display - Large headings
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.3,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.2,
        ),

        // Headings
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 1.1,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        // Titles
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),

        // Body text
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textMuted,
        ),

        // Labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),

      /// ICON THEME
      iconTheme: const IconThemeData(
        color: neonBlue,
        size: 24,
      ),

      /// FLOATING ACTION BUTTON
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepBlue,
        foregroundColor: textPrimary,
        elevation: 4,
      ),

      /// DIALOG
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundSurface,
        elevation: DesignSystem.elevation8,
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.radiusLarge,
          side: const BorderSide(color: dividerColor),
        ),
      ),

      /// SNACK BAR
      snackBarTheme: SnackBarThemeData(
        backgroundColor: backgroundElevated,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: DesignSystem.radiusStandard,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      /// SWITCH
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonBlue;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return neonBlue.withOpacity(0.3);
          }
          return dividerColor;
        }),
      ),

      /// CHECKBOX
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonBlue;
          return Colors.transparent;
        }),
        side: const BorderSide(color: dividerColor, width: DesignSystem.borderMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.spacing4)),
      ),

      /// RADIO
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return neonBlue;
          return textMuted;
        }),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CUSTOM COLOR EXTENSION - Quick access to special colors
/// ═══════════════════════════════════════════════════════════════════════════
/// Use: Theme.of(context).colorScheme.bloodRed

extension IgrisColors on ColorScheme {
  /// Blood red accent - Use sparingly for intensity
  Color get bloodRed => const Color(0xFF70020F);

  /// Light neon blue - Glow lines and active states
  Color get neonBlue => const Color(0xFF81D8F0);

  /// Deep cyan blue - Primary interactive elements
  Color get deepBlue => const Color(0xFF4DA6C5);

  /// Royal gold - Premium highlights only (very rare)
  Color get royalGold => const Color(0xFFFFD700);

  /// Background colors
  Color get backgroundPrimary => const Color(0xFF0A0F1C);
  Color get backgroundSurface => const Color(0xFF121A2A);
  Color get backgroundElevated => const Color(0xFF182235);

  /// Text colors
  Color get textPrimary => const Color(0xFFE6EDF3);
  Color get textSecondary => const Color(0xFF9FB3C8);
  Color get textMuted => const Color(0xFF5C6B7A);
}
