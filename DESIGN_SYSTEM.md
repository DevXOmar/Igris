# Igris Design System

**Status:** 🔒 **LOCKED** - All values are standardized and enforced

This document defines the complete design system for the Igris app. **All hardcoded values must use these constants** - no exceptions.

---

## 📏 Spacing Scale

**Location:** `lib/core/theme/design_system.dart`

### Available Spacing Values

```dart
DesignSystem.spacing4   // 4px  - Micro spacing
DesignSystem.spacing8   // 8px  - Compact spacing
DesignSystem.spacing12  // 12px - Small spacing
DesignSystem.spacing16  // 16px - BASE UNIT (default)
DesignSystem.spacing24  // 24px - Medium spacing
DesignSystem.spacing32  // 32px - Large spacing
DesignSystem.spacing48  // 48px - Extra large (rare)
```

### Common Padding Shortcuts

```dart
DesignSystem.paddingAll4   // EdgeInsets.all(4)
DesignSystem.paddingAll8   // EdgeInsets.all(8)
DesignSystem.paddingAll12  // EdgeInsets.all(12)
DesignSystem.paddingAll16  // EdgeInsets.all(16) ← Most common
DesignSystem.paddingAll24  // EdgeInsets.all(24)
DesignSystem.paddingAll32  // EdgeInsets.all(32)

DesignSystem.paddingH16    // EdgeInsets.symmetric(horizontal: 16)
DesignSystem.paddingV16    // EdgeInsets.symmetric(vertical: 16)
DesignSystem.paddingH24    // EdgeInsets.symmetric(horizontal: 24)
DesignSystem.paddingV24    // EdgeInsets.symmetric(vertical: 24)
```

### Usage Examples

```dart
// ✅ CORRECT
padding: DesignSystem.paddingAll16
padding: EdgeInsets.symmetric(horizontal: DesignSystem.spacing24)
SizedBox(height: DesignSystem.spacing12)

// ❌ WRONG - Never hardcode values
padding: const EdgeInsets.all(16)
padding: const EdgeInsets.symmetric(horizontal: 20)
SizedBox(height: 15)
```

---

## 🔘 Border Radius

### Available Radius Values

```dart
DesignSystem.radius12   // 12px - Small elements
DesignSystem.radius16   // 16px - STANDARD (use by default)
DesignSystem.radius24   // 24px - Large elements (modals, dialogs)

// Convenience BorderRadius objects
DesignSystem.radiusSmall     // BorderRadius.circular(12)
DesignSystem.radiusStandard  // BorderRadius.circular(16) ← Default
DesignSystem.radiusLarge     // BorderRadius.circular(24)
```

### Usage Guidelines

- **Standard (16px):** Cards, buttons, inputs, most UI elements
- **Small (12px):** Nested elements, compact items, badges
- **Large (24px):** Modal dialogs, large cards, bottom sheets

### Usage Examples

```dart
// ✅ CORRECT
borderRadius: DesignSystem.radiusStandard
borderRadius: BorderRadius.circular(DesignSystem.radius16)
BorderRadius.only(
  topLeft: Radius.circular(DesignSystem.radius24),
  topRight: Radius.circular(DesignSystem.radius24),
)

// ❌ WRONG
borderRadius: BorderRadius.circular(14)
borderRadius: BorderRadius.circular(18)
```

---

## 📝 Typography Scale

**Always use Theme-based text styles** instead of hardcoded font sizes.

### Display Scale (Hero text, page titles)

```dart
Theme.of(context).textTheme.displayLarge   // 32px, bold
Theme.of(context).textTheme.displayMedium  // 28px, bold
```

### Headline Scale (Major section headers)

```dart
Theme.of(context).textTheme.headlineLarge   // 24px, semi-bold
Theme.of(context).textTheme.headlineMedium  // 20px, semi-bold
```

### Title Scale (Card titles, widget headers)

```dart
Theme.of(context).textTheme.titleLarge   // 18px, semi-bold
Theme.of(context).textTheme.titleMedium  // 16px, medium
Theme.of(context).textTheme.titleSmall   // 14px, medium
```

### Body Scale (Main content)

```dart
Theme.of(context).textTheme.bodyLarge   // 16px, regular ← Reading text
Theme.of(context).textTheme.bodyMedium  // 14px, regular ← Most common
Theme.of(context).textTheme.bodySmall   // 12px, regular ← Metadata
```

### Label Scale (Buttons, tags, metadata)

```dart
Theme.of(context).textTheme.labelLarge   // 14px, semi-bold
Theme.of(context).textTheme.labelMedium  // 12px, medium
Theme.of(context).textTheme.labelSmall   // 10px, medium
```

---

## 🎨 Icon Sizes

```dart
DesignSystem.iconSmall   // 16px - Small inline icons
DesignSystem.iconMedium  // 24px - Standard UI icons ← Default
DesignSystem.iconLarge   // 32px - Prominent icons
DesignSystem.iconXLarge  // 48px - Feature icons
DesignSystem.iconHero    // 64px - Empty states, hero sections
```

### Usage Examples

```dart
// ✅ CORRECT
Icon(Icons.check, size: DesignSystem.iconMedium)
Icon(Icons.dashboard, size: DesignSystem.iconHero)

// ❌ WRONG
Icon(Icons.check, size: 20)
Icon(Icons.dashboard, size: 60)
```

---

## 📐 Borders & Dividers

```dart
DesignSystem.borderThin    // 1px - Standard borders ← Most common
DesignSystem.borderMedium  // 2px - Emphasized borders
DesignSystem.borderThick   // 3px - Strong borders (rare)
```

---

## 🏔️ Elevation & Glow System

**Igris Philosophy:** Prefer **FLAT (elevation: 0) + COLORED GLOWS** over traditional Material shadows for the cold, mysterious system-UI aesthetic.

### Elevation Levels

```dart
DesignSystem.elevation0  // 0dp - Flat elements (DEFAULT)
DesignSystem.elevation1  // 1dp - Subtle lift (rare)
DesignSystem.elevation2  // 2dp - Standard elevation (rare)
DesignSystem.elevation4  // 4dp - Floating elements (FAB)
DesignSystem.elevation8  // 8dp - Modals, dialogs
```

### When to Use Each Level

**elevation0 (Flat - Default)**
- ✅ Cards (use borders instead)
- ✅ Buttons (use glow effects)
- ✅ List items
- ✅ Most UI elements

**elevation1 (Subtle)**
- ⚠️ Hover states (prefer glows)
- ⚠️ Nested cards (rare)

**elevation2 (Standard)**
- ⚠️ Resting cards (if needed)
- ⚠️ App bar (if not transparent)

**elevation4 (Floating)**
- ✅ Floating Action Button
- ✅ Active dragged elements

**elevation8 (Modal)**
- ✅ Dialogs
- ✅ Modal bottom sheets
- ✅ Dropdown menus
- ✅ Navigation drawer

### Glow Effects (Preferred over shadows)

```dart
// Blue glows - Progress & completion
AppTheme.blueGlowSubtle   // Active/hover, 90-99% progress
AppTheme.blueGlowStrong   // 100% completion, focused states

// Red glows - Warnings & intensity
AppTheme.redGlowSubtle    // Warnings, errors, intensity

// Purple glows - Shadow/Igris themes
AppTheme.purpleGlowSubtle   // Shadow domains, Igris elements
AppTheme.purpleGlowStrong   // Transformations, special states
AppTheme.softGlow           // Generic soft purple glow

// Gold glow - Premium (VERY RARE)
AppTheme.goldGlow         // Achievements, rare excellence

// Standard shadow (use sparingly)
AppTheme.elevationShadow  // Traditional Material shadow
```

### Usage Examples

```dart
// ✅ CORRECT - Flat with glow
Container(
  decoration: BoxDecoration(
    color: AppTheme.backgroundSurface,
    borderRadius: DesignSystem.radiusStandard,
    boxShadow: AppTheme.blueGlowSubtle, // Glow instead of elevation
  ),
)

// ✅ CORRECT - Progress-based glow
Container(
  decoration: BoxDecoration(
    boxShadow: progress >= 1.0 
      ? AppTheme.blueGlowStrong 
      : progress >= 0.9 
        ? AppTheme.blueGlowSubtle 
        : AppTheme.elevationShadow,
  ),
)

// ❌ WRONG - Don't use Material elevation property
Card(
  elevation: 4, // Don't do this
  child: ...
)

// ✅ CORRECT - Use elevation property but with value 0
Card(
  elevation: DesignSystem.elevation0, // Flat
  child: ...
)
```

### Glow Selection Guide

| Use Case | Glow Effect |
|----------|-------------|
| Progress 90-99% | `blueGlowSubtle` |
| Progress 100% | `blueGlowStrong` |
| Hover/Active state | `blueGlowSubtle` |
| Error/Warning | `redGlowSubtle` |
| Shadow domain | `purpleGlowSubtle` |
| Transformation | `purpleGlowStrong` |
| Achievement | `goldGlow` |
| Default/Neutral | `elevationShadow` |

---

## 🎯 Quick Reference Helpers

### Standard Card Decoration

```dart
// Standard card with border
Container(
  decoration: DesignSystem.cardDecoration(context),
  child: ...
)

// Elevated card
Container(
  decoration: DesignSystem.elevatedCardDecoration(context),
  child: ...
)
```

---

## 🚫 What NOT to Do

### ❌ Never hardcode values

```dart
// WRONG
padding: const EdgeInsets.all(20)
SizedBox(height: 15)
borderRadius: BorderRadius.circular(14)
Icon(Icons.check, size: 28)
```

### ❌ Never use arbitrary spacing

```dart
// WRONG
EdgeInsets.all(18)  // Use spacing16 instead
EdgeInsets.all(22)  // Use spacing24 instead
EdgeInsets.all(14)  // Use spacing12 or spacing16
```

### ❌ Never mix spacing systems

```dart
// WRONG - Inconsistent usage
padding: EdgeInsets.all(DesignSystem.spacing16)
margin: const EdgeInsets.all(20)  // ← Should use DesignSystem
```

---

## ✅ Best Practices

### 1. **Import the design system**

```dart
import '../core/theme/design_system.dart';
```

### 2. **Use predefined constants**

```dart
padding: DesignSystem.paddingAll16,
borderRadius: DesignSystem.radiusStandard,
```

### 3. **Use Theme for text styles**

```dart
Text(
  'Title',
  style: Theme.of(context).textTheme.titleLarge,
)
```

### 4. **Combine spacing values when needed**

```dart
// If you need 20px (not in scale), combine available values
padding: EdgeInsets.all(DesignSystem.spacing16 + 4)  // 20px
```

### 5. **Document non-standard combinations**

```dart
// 20px spacing (not in scale) - Adding 4px to base 16
padding: EdgeInsets.all(DesignSystem.spacing16 + 4)
```

---

## 📋 Migration Checklist

When updating existing code:

- [ ] Replace all `EdgeInsets.all()` with `DesignSystem.paddingAll*`
- [ ] Replace all `EdgeInsets.symmetric()` with DesignSystem spacing
- [ ] Replace all `SizedBox(height/width)` with DesignSystem spacing
- [ ] Replace all `BorderRadius.circular()` with DesignSystem radius
- [ ] Replace all hardcoded icon sizes with DesignSystem icon sizes
- [ ] Verify all text uses `Theme.of(context).textTheme.*`
- [ ] Remove unused imports after cleanup

---

## 🔍 Code Review Guidelines

Reviewers should reject any PR that:

1. Uses hardcoded spacing values (e.g., `20`, `15`, `32`)
2. Uses arbitrary border radius (e.g., `14`, `18`, `22`)
3. Uses hardcoded font sizes (e.g., `fontSize: 16`)
4. Uses hardcoded icon sizes (e.g., `size: 28`)
5. Creates custom spacing not from the scale

---

## 📦 Files Updated

The following files have been updated to use the design system:

### Core Theme
- ✅ `lib/core/theme/design_system.dart` (NEW - Design system constants)
- ✅ `lib/core/theme/app_theme.dart` (Updated to use DesignSystem)

### Screens
- ✅ `lib/screens/home/home_content.dart`
- ✅ `lib/screens/calendar/calendar_screen.dart`
- ✅ `lib/screens/domains/domains_screen.dart`
- ✅ `lib/screens/settings/settings_screen.dart`

### Widgets
- ✅ `lib/widgets/domain_progress_bar.dart`
- ✅ `lib/widgets/domain_tasks_bottom_sheet.dart`

### Scroll Behavior
- ✅ `lib/main.dart` (Added global smooth scroll behavior)

---

## 🎨 Design Philosophy

**Igris follows these principles:**

1. **Consistency > Flexibility** - Use the scale, don't invent new values
2. **Predictability** - Same spacing everywhere creates visual rhythm
3. **Professional Polish** - Locked design system = mature product
4. **Easy Maintenance** - Change constants, not 100 files
5. **Scalability** - New features inherit the system automatically

---

## 📞 Questions?

If you need a spacing value not in the scale:
1. Try combining existing values (e.g., `spacing16 + 4`)
2. Question if you really need it
3. If essential, propose adding it to the scale (requires team discussion)

**Remember:** The design system exists to help us, not restrict us. But breaking it should be rare and well-justified.

---

**Last Updated:** February 18, 2026  
**Status:** ✅ Active & Enforced
