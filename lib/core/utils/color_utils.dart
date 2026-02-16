import 'package:flutter/material.dart';
import 'dart:math';

/// Utility class for generating consistent colors for domains
class ColorUtils {
  /// Generate a unique color for a domain based on its ID
  /// Uses the ID's hash to generate a consistent color
  static Color generateDomainColor(String domainId) {
    // Use domain ID hash to generate consistent color
    final hash = domainId.hashCode;
    final random = Random(hash);
    
    // Generate HSL color with:
    // - Hue: 0-360 (full color spectrum)
    // - Saturation: 0.6-0.8 (vibrant but not too intense)
    // - Lightness: 0.5-0.65 (bright enough for dark theme)
    final hue = random.nextDouble() * 360;
    final saturation = 0.6 + random.nextDouble() * 0.2;
    final lightness = 0.5 + random.nextDouble() * 0.15;
    
    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }
  
  /// Generate a darker shade of a color for completed state
  static Color getDarkerShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withLightness((hslColor.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }
  
  /// Generate a lighter shade for incomplete state
  static Color getLighterShade(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withLightness((hslColor.lightness * 1.2).clamp(0.0, 1.0)).toColor();
  }
}
