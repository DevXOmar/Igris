# Igris UI Components

Igris UI is a collection of custom-built components that implement the Igris design system. These components automatically use Igris colors, spacing, border radius, and elevation rules.

## Philosophy

**Built from Material widgets with full Igris styling**
- ✅ Pure Flutter Material widgets as foundation
- ✅ Complete Igris theme integration (colors, spacing, radius)
- ✅ Flat design + colored glows (no Material shadows)
- ❌ Do NOT use hardcoded colors or spacing
- ❌ Do NOT bypass DesignSystem constants

All components follow Igris design system:
- Colors: `AppColors` class (19 centralized colors)
- Spacing: `DesignSystem` scale (4/8/12/16/24/32/48)
- Border Radius: `DesignSystem` constants (12/16/24)
- Elevation: Flat design + colored glows (not Material shadows)

## Installation

```dart
import 'package:igris/widgets/ui/igris_ui.dart';
```

This single import gives you access to all Igris UI components.

---

## Components

### IgrisButton

#### Variants
- `primary` - Neon blue border + glow (default)
- `destructive` - Blood red border
- `outline` - Subtle border, transparent background
- `ghost` - No border, minimal style

#### Usage

```dart
// Primary button
IgrisButton(
  text: 'Add Task',
  onPressed: () {},
  icon: Icons.add,
)

// Destructive button
IgrisButton(
  text: 'Delete',
  variant: IgrisButtonVariant.destructive,
  onPressed: () {},
)

// Loading state
IgrisButton(
  text: 'Saving',
  isLoading: true,
)

// Full width
IgrisButton(
  text: 'Continue',
  fullWidth: true,
  onPressed: () {},
)
```

---

### IgrisCard

#### Variants
- `elevated` - Elevated background with neon border (default)
- `surface` - Surface container with subtle border
- `transparent` - Transparent background, no border

#### Usage

```dart
// Basic card
IgrisCard(
  child: Text('Content'),
)

// Surface variant with glow
IgrisCard(
  variant: IgrisCardVariant.surface,
  showGlow: true,
  child: Column(
    children: [
      Text('Title'),
      Text('Description'),
    ],
  ),
)

// Custom padding
IgrisCard(
  padding: EdgeInsets.all(DesignSystem.paddingAll24),
  child: Text('Content'),
)
```

---

### IgrisDialog

#### Static Methods
- `IgrisDialog.show()` - Custom dialog
- `IgrisDialog.showConfirmation()` - Yes/No dialog

#### Usage

```dart
// Custom dialog
final result = await IgrisDialog.show<String>(
  context: context,
  title: 'Choose Domain',
  description: 'Select which domain to focus on',
  content: DomainList(),
  actions: [
    IgrisDialogAction(
      label: 'Cancel',
      variant: IgrisButtonVariant.ghost,
    ),
    IgrisDialogAction(
      label: 'Select',
      onPressed: () { /* handle */ },
    ),
  ],
);

// Confirmation dialog
final confirmed = await IgrisDialog.showConfirmation(
  context: context,
  title: 'Delete Task',
  description: 'This action cannot be undone',
  isDestructive: true,
);

if (confirmed == true) {
  // Proceed with deletion
}
```

---

### IgrisBottomSheet

#### Static Methods
- `IgrisBottomSheet.show()` - Custom bottom sheet
- `IgrisBottomSheet.showList()` - List of items

#### Usage

```dart
// Custom bottom sheet
await IgrisBottomSheet.show(
  context: context,
  title: 'Task Details',
  child: TaskDetailsWidget(),
);

// List bottom sheet
final selected = await IgrisBottomSheet.showList<String>(
  context: context,
  title: 'Select Domain',
  items: [
    IgrisBottomSheetItem(
      label: 'Fitness',
      subtitle: '5 tasks remaining',
      icon: Icons.fitness_center,
      value: 'fitness',
    ),
    IgrisBottomSheetItem(
      label: 'Learning',
      subtitle: '3 tasks remaining',
      icon: Icons.book,
      value: 'learning',
    ),
    IgrisBottomSheetItem(
      label: 'Delete Domain',
      icon: Icons.delete,
      isDestructive: true,
      value: 'delete',
    ),
  ],
);

if (selected == 'delete') {
  // Handle deletion
}
```

---

### IgrisInputField

#### Usage

```dart
// Basic input
IgrisInputField(
  label: 'Task Name',
  hint: 'Enter task name',
  controller: _controller,
  onChanged: (value) {},
)

// With icons
IgrisInputField(
  label: 'Search',
  prefixIcon: Icons.search,
  suffixIcon: Icons.clear,
  onSuffixIconTap: () => _controller.clear(),
)

// Password field
IgrisInputField(
  label: 'Password',
  obscureText: true,
  suffixIcon: Icons.visibility,
)

// With error
IgrisInputField(
  label: 'Email',
  errorText: 'Invalid email format',
)

// Multiline
IgrisInputField(
  label: 'Notes',
  maxLines: 4,
  hint: 'Enter notes',
)
```

---

### IgrisSwitch

#### Usage

```dart
// Basic switch
IgrisSwitch(
  value: _enabled,
  onChanged: (value) => setState(() => _enabled = value),
)

// With label
IgrisSwitch(
  value: _notifications,
  onChanged: (value) => setState(() => _notifications = value),
  label: 'Enable notifications',
)
```

---

### IgrisCheckbox

#### Usage

```dart
// Basic checkbox
IgrisCheckbox(
  value: _checked,
  onChanged: (value) => setState(() => _checked = value),
)

// With label
IgrisCheckbox(
  value: _agreedToTerms,
  onChanged: (value) => setState(() => _agreedToTerms = value),
  label: 'I agree to the terms and conditions',
)
```

---

## Migration Guide

### Replacing Material Widgets

**Before:**
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Add Task'),
)
```

**After:**
```dart
IgrisButton(
  text: 'Add Task',
  onPressed: () {},
)
```

---

**Before:**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text('Content'),
  ),
)
```

**After:**
```dart
IgrisCard(
  child: Text('Content'),
)
```

---

**Before:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Delete?'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(/* ... */),
      ElevatedButton(/* ... */),
    ],
  ),
);
```

**After:**
```dart
IgrisDialog.showConfirmation(
  context: context,
  title: 'Delete?',
  description: 'Are you sure?',
  isDestructive: true,
);
```

---

## Design Rules

### Colors
**DO:**
- ✅ Use `IgrisButtonVariant.primary` for primary actions
- ✅ Use `IgrisButtonVariant.destructive` for dangerous actions
- ✅ Use `IgrisCardVariant.elevated` for important content

**DON'T:**
- ❌ Manually set colors (use variants instead)
- ❌ Override shadcn theme colors

### Spacing
**DO:**
- ✅ Use default padding (components use `DesignSystem` internally)
- ✅ Add custom padding via `padding` parameter if needed

**DON'T:**
- ❌ Use arbitrary padding values
- ❌ Use `EdgeInsets.all(10)` or other non-standard values

### Border Radius
**DO:**
- ✅ Trust component defaults (all use `DesignSystem.radiusStandard`)

**DON'T:**
- ❌ Override border radius unless absolutely necessary

---

## Examples

### Complete Form

```dart
Column(
  children: [
    IgrisInputField(
      label: 'Task Name',
      controller: _nameController,
    ),
    SizedBox(height: DesignSystem.spacing16),
    IgrisInputField(
      label: 'Description',
      maxLines: 3,
      controller: _descController,
    ),
    SizedBox(height: DesignSystem.spacing16),
    IgrisSwitch(
      value: _isUrgent,
      onChanged: (value) => setState(() => _isUrgent = value),
      label: 'Urgent task',
    ),
    SizedBox(height: DesignSystem.spacing24),
    IgrisButton(
      text: 'Create Task',
      fullWidth: true,
      onPressed: _handleSubmit,
    ),
  ],
)
```

### Settings List

```dart
IgrisCard(
  child: Column(
    children: [
      IgrisSwitch(
        value: _notifications,
        onChanged: _toggleNotifications,
        label: 'Push notifications',
      ),
      Divider(),
      IgrisSwitch(
        value: _darkMode,
        onChanged: _toggleDarkMode,
        label: 'Dark mode',
      ),
      Divider(),
      IgrisCheckbox(
        value: _analytics,
        onChanged: _toggleAnalytics,
        label: 'Share analytics',
      ),
    ],
  ),
)
```

---

## Theming Architecture

```
AppColors (source of truth)
    ↓
AppTheme.darkTheme (forwards colors)
    ↓
IgrisColors extension (provides glows)
    ↓
Igris UI Components (styled Material widgets)
```

**Key Principle:** Material widgets provide structure, Igris provides style.
