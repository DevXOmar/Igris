import 'package:flutter/material.dart';
import 'design_system.dart';

/// Centralized color palette.
///
/// Keep ALL app colors here to ensure consistency across widgets, screens,
/// and the ThemeData configuration.
class AppColors {
  AppColors._();

  // Base Backgrounds - Deep black system with subtle purple undertones
  static const Color backgroundPrimary = Color(0xFF0A0F1C);
  static const Color backgroundSurface = Color(0xFF121A2A);
  static const Color backgroundElevated = Color(0xFF182235);

  // Primary Accent Blues - Enhanced neon for motivational glow
  static const Color neonBlue = Color(0xFF5BCFFF); // was 0xFF81D8F0
  static const Color deepBlue = Color(0xFF4DA6C5);

  // Deep Navies - Supporting structure tones
  static const Color navyDeep = Color(0xFF1F3A8A);
  static const Color navyDarker = Color(0xFF0F3460);

  // Blood Red - Intensity accent (slightly brighter)
  static const Color bloodRed = Color(0xFF8B0000); // was 0xFF70020F
  static const Color bloodRedActive = Color(0xFF9E1A28); // was 0xFF8C0A18

  // Royal Gold - Premium highlight (rare use only)
  static const Color royalGold = Color(0xFFFFD700);
  static const Color royalGoldDark = Color(0xFFB8860B);

  // Purple Accents - Igris aura
  static const Color shadowPurple = Color(0xFF9450F2);
  static const Color deepPurple = Color(0xFF483C59);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF9FB3C8);
  static const Color textMuted = Color(0xFF5C6B7A);
  static const Color textHighlight = Color(0xFFD1A0F2);

  // UI Elements
  static const Color dividerColor = Color(0xFF1E293B);
  static const Color glowEffect = Color(0xFFEBBAF2);
  
  // Additional UI Colors
  static const Color surfaceContainer = backgroundSurface;
  static const Color border = dividerColor;
  static const Color gold = royalGold;

  /// DOMAIN BAR COLORS - Expanded multi-color histogram system
  static const List<Color> domainBarColors = [
    deepBlue,
    neonBlue,
    bloodRed,
    royalGold,
    navyDeep,
    navyDarker,
    shadowPurple,
    deepPurple,
  ];

  /// Optional helper (not used by default Theme rules).
  static LinearGradient motivationalGradient(Color start, Color end) {
    return LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// IGRIS THEME EXTENSION — ThemeExtension<IgrisThemeColors>
/// ═══════════════════════════════════════════════════════════════════════════
/// Exposes the full Igris palette as a typed ThemeExtension so any widget can
/// access colors without importing AppColors directly:
///
///   final igris = Theme.of(context).extension<IgrisThemeColors>()!;
///   igris.neonBlue, igris.bloodRed, igris.royalGold …
///
/// Registered in AppTheme.darkTheme via extensions: [IgrisThemeColors.dark()]
class IgrisThemeColors extends ThemeExtension<IgrisThemeColors> {
  final Color neonBlue;
  final Color deepBlue;
  final Color bloodRed;
  final Color bloodRedActive;
  final Color royalGold;
  final Color shadowPurple;
  final Color backgroundPrimary;
  final Color backgroundSurface;
  final Color backgroundElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color dividerColor;

  const IgrisThemeColors({
    required this.neonBlue,
    required this.deepBlue,
    required this.bloodRed,
    required this.bloodRedActive,
    required this.royalGold,
    required this.shadowPurple,
    required this.backgroundPrimary,
    required this.backgroundSurface,
    required this.backgroundElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.dividerColor,
  });

  /// Default dark palette — used in AppTheme.darkTheme.
  const IgrisThemeColors.dark()
      : neonBlue = AppColors.neonBlue,
        deepBlue = AppColors.deepBlue,
        bloodRed = AppColors.bloodRed,
        bloodRedActive = AppColors.bloodRedActive,
        royalGold = AppColors.royalGold,
        shadowPurple = AppColors.shadowPurple,
        backgroundPrimary = AppColors.backgroundPrimary,
        backgroundSurface = AppColors.backgroundSurface,
        backgroundElevated = AppColors.backgroundElevated,
        textPrimary = AppColors.textPrimary,
        textSecondary = AppColors.textSecondary,
        textMuted = AppColors.textMuted,
        dividerColor = AppColors.dividerColor;

  @override
  IgrisThemeColors copyWith({
    Color? neonBlue,
    Color? deepBlue,
    Color? bloodRed,
    Color? bloodRedActive,
    Color? royalGold,
    Color? shadowPurple,
    Color? backgroundPrimary,
    Color? backgroundSurface,
    Color? backgroundElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? dividerColor,
  }) {
    return IgrisThemeColors(
      neonBlue: neonBlue ?? this.neonBlue,
      deepBlue: deepBlue ?? this.deepBlue,
      bloodRed: bloodRed ?? this.bloodRed,
      bloodRedActive: bloodRedActive ?? this.bloodRedActive,
      royalGold: royalGold ?? this.royalGold,
      shadowPurple: shadowPurple ?? this.shadowPurple,
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSurface: backgroundSurface ?? this.backgroundSurface,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  IgrisThemeColors lerp(IgrisThemeColors? other, double t) {
    if (other == null) return this;
    return IgrisThemeColors(
      neonBlue: Color.lerp(neonBlue, other.neonBlue, t)!,
      deepBlue: Color.lerp(deepBlue, other.deepBlue, t)!,
      bloodRed: Color.lerp(bloodRed, other.bloodRed, t)!,
      bloodRedActive: Color.lerp(bloodRedActive, other.bloodRedActive, t)!,
      royalGold: Color.lerp(royalGold, other.royalGold, t)!,
      shadowPurple: Color.lerp(shadowPurple, other.shadowPurple, t)!,
      backgroundPrimary: Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSurface: Color.lerp(backgroundSurface, other.backgroundSurface, t)!,
      backgroundElevated: Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
    );
  }
}

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
/// - Consistent BorderRadius: 16
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

  // Base Backgrounds
  static const Color backgroundPrimary = AppColors.backgroundPrimary;
  static const Color backgroundSurface = AppColors.backgroundSurface;
  static const Color backgroundElevated = AppColors.backgroundElevated;

  // Primary Accent Blues
  static const Color neonBlue = AppColors.neonBlue;
  static const Color deepBlue = AppColors.deepBlue;

  // Deep Navies
  static const Color navyDeep = AppColors.navyDeep;
  static const Color navyDarker = AppColors.navyDarker;

  // Blood Red
  static const Color bloodRed = AppColors.bloodRed;
  static const Color bloodRedActive = AppColors.bloodRedActive;

  // Royal Gold
  static const Color royalGold = AppColors.royalGold;
  static const Color royalGoldDark = AppColors.royalGoldDark;

  // Purple Accents
  static const Color shadowPurple = AppColors.shadowPurple;
  static const Color deepPurple = AppColors.deepPurple;

  // Text Hierarchy
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;
  static const Color textHighlight = AppColors.textHighlight;

  // UI Elements
  static const Color dividerColor = AppColors.dividerColor;
  static const Color glowEffect = AppColors.glowEffect;

  /// ═══════════════════════════════════════════════════════════════════════
  /// DOMAIN BAR COLORS - Multi-color histogram system
  /// ═══════════════════════════════════════════════════════════════════════
  /// Each domain gets a unique color from this cycle for visual distinction.
  /// Colors are carefully selected to maintain premium dark aesthetic.

  static const List<Color> domainBarColors = AppColors.domainBarColors;

  /// Get domain color by index (cycles through colors)
  static Color getDomainColor(int index) {
    return domainBarColors[index % domainBarColors.length];
  }

  /// ═══════════════════════════════════════════════════════════════════════
  /// GLOW EFFECTS - Igris-style elevation system
  /// ═══════════════════════════════════════════════════════════════════════
  /// 
  /// Igris prefers FLAT design (elevation: 0) with COLORED GLOWS for depth
  /// instead of traditional Material shadows. This creates the mysterious,
  /// cold, system-UI aesthetic.
  /// 
  /// Usage guidelines:
  /// • blueGlowSubtle: Active/hover states, 90-99% progress
  /// • blueGlowStrong: 100% completion, focused states
  /// • redGlowSubtle: Warnings, errors, intensity indicators
  /// • purpleGlowSubtle: Shadow/Igris-themed domains, transformation states
  /// • purpleGlowStrong: Special achievements, rare effects
  /// • goldGlow: Premium achievements (very rare)
  /// • elevationShadow: Standard Material shadow (use sparingly)

  /// Subtle blue glow for active/hover states (90-99% progress)
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

  /// Subtle purple glow for shadow/Igris domains
  static List<BoxShadow> get purpleGlowSubtle => [
    BoxShadow(
      color: shadowPurple.withOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 1,
    ),
  ];

  /// Strong purple glow for transformations/special states
  static List<BoxShadow> get purpleGlowStrong => [
    BoxShadow(
      color: shadowPurple.withOpacity(0.5),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Soft glow effect (multi-use overlay)
  static List<BoxShadow> get softGlow => [
    BoxShadow(
      color: glowEffect.withOpacity(0.25),
      blurRadius: 10,
      spreadRadius: 1,
    ),
  ];

  /// Gold glow for premium achievements (very rare)
  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: royalGold.withOpacity(0.4),
      blurRadius: 14,
      spreadRadius: 1,
    ),
  ];

  /// Default elevation shadow (no glow) - use sparingly
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

      /// THEME EXTENSIONS — IgrisThemeColors registered here so any widget can
      /// access the palette via Theme.of(context).extension<IgrisThemeColors>()!
      extensions: const [IgrisThemeColors.dark()],

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
        tertiaryContainer: royalGoldDark,

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
  Color get bloodRed => AppTheme.bloodRed;

  /// Active blood red
  Color get bloodRedActive => AppTheme.bloodRedActive;

  /// Light neon blue - Glow lines and active states
  Color get neonBlue => AppTheme.neonBlue;

  /// Deep cyan blue - Primary interactive elements
  Color get deepBlue => AppTheme.deepBlue;

  /// Royal gold - Premium highlights only (very rare)
  Color get royalGold => AppTheme.royalGold;

  /// Darker gold - container/highlight background
  Color get royalGoldDark => AppTheme.royalGoldDark;

  /// Purple accents
  Color get shadowPurple => AppTheme.shadowPurple;
  Color get deepPurple => AppTheme.deepPurple;
  Color get glowEffect => AppTheme.glowEffect;

  /// Background colors
  Color get backgroundPrimary => AppTheme.backgroundPrimary;
  Color get backgroundSurface => AppTheme.backgroundSurface;
  Color get backgroundElevated => AppTheme.backgroundElevated;

  /// Text colors
  Color get textPrimary => AppTheme.textPrimary;
  Color get textSecondary => AppTheme.textSecondary;
  Color get textMuted => AppTheme.textMuted;

  Color get textHighlight => AppTheme.textHighlight;
  
  /// Convenience getters for glow effects
  List<BoxShadow> get blueGlowSubtle => AppTheme.blueGlowSubtle;
  List<BoxShadow> get blueGlowStrong => AppTheme.blueGlowStrong;
  List<BoxShadow> get redGlowSubtle => AppTheme.redGlowSubtle;
  List<BoxShadow> get purpleGlowSubtle => AppTheme.purpleGlowSubtle;
  List<BoxShadow> get purpleGlowStrong => AppTheme.purpleGlowStrong;
  List<BoxShadow> get softGlow => AppTheme.softGlow;
  List<BoxShadow> get goldGlow => AppTheme.goldGlow;
  List<BoxShadow> get elevationShadow => AppTheme.elevationShadow;
}
