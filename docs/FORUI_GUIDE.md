# ForUI Design System Guide

## Table of Contents
1. [Overview](#overview)
2. [Setup](#setup)
3. [Theme System](#theme-system)
4. [Colors](#colors)
5. [Typography](#typography)
6. [Common Widgets](#common-widgets)
7. [Hooks Integration](#hooks-integration)
8. [Common Patterns](#common-patterns)
9. [Migration from shadcn_ui](#migration-from-shadcn_ui)

## Overview

ForUI is a Flutter UI library inspired by shadcn/ui, providing beautifully designed, minimalistic widgets with first-class support for Flutter Hooks. It offers over 40+ widgets with built-in theming support.

**Key Features:**
- 🎨 Multiple pre-built themes (Zinc, Slate, Red, Rose, Orange, Green, Blue, Yellow, Violet)
- ⚡ Built-in CLI for generating themes and styles
- ✅ Well-tested and documented
- 🌍 i18n support with FLocalizations
- 🪝 First-class Flutter Hooks integration via `forui_hooks`

## Setup

### 1. App Root Configuration

Wrap your app with `MaterialApp`, `FTheme`, and `FToaster`:

```dart
import 'package:forui/forui.dart';

MaterialApp.router(
  locale: const Locale('en', 'US'),
  localizationsDelegates: FLocalizations.localizationsDelegates,
  supportedLocales: FLocalizations.supportedLocales,
  theme: FThemes.zinc.light.toApproximateMaterialTheme(),
  darkTheme: FThemes.zinc.dark.toApproximateMaterialTheme(),
  themeMode: ThemeMode.system,
  builder: (context, child) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final theme = brightness == Brightness.dark 
        ? FThemes.zinc.dark 
        : FThemes.zinc.light;
    return FTheme(data: theme, child: FToaster(child: child!));
  },
  routerConfig: _appRouter.config(),
)
```

### 2. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  forui: ^0.17.0
  forui_hooks: ^0.17.0  # Optional, for Hooks integration
```

## Theme System

### Accessing Theme

```dart
// Recommended way
final theme = context.theme;

// Alternative (longer)
final theme = FTheme.of(context);
```

### Available Themes

ForUI provides multiple built-in themes:
- `FThemes.zinc` (default)
- `FThemes.slate`
- `FThemes.red`
- `FThemes.rose`
- `FThemes.orange`
- `FThemes.green`
- `FThemes.blue`
- `FThemes.yellow`
- `FThemes.violet`

Each theme has `.light` and `.dark` variants.

### Custom Theme

```dart
FThemeData(
  colors: FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: Color(0x33000000),
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF09090B),
    primary: Color(0xFF18181B),
    primaryForeground: Color(0xFFFAFAFA),
    // ... other colors
  ),
)
```

## Colors

### Color System

ForUI uses a semantic color system:

```dart
final theme = context.theme;

// Main colors
theme.colors.background        // Main background
theme.colors.foreground        // Main text/foreground
theme.colors.primary           // Primary actions
theme.colors.primaryForeground // Text on primary
theme.colors.secondary         // Secondary elements
theme.colors.secondaryForeground
theme.colors.muted             // Muted/disabled elements
theme.colors.mutedForeground
theme.colors.destructive       // Destructive actions (delete, etc.)
theme.colors.destructiveForeground
theme.colors.error             // Error states
theme.colors.errorForeground
theme.colors.border            // Border color
```

### Color Utilities

```dart
// Generate hover color (lighter/darker based on brightness)
final hoverColor = theme.colors.hover(theme.colors.primary);

// Generate disabled color
final disabledColor = theme.colors.disable(
  theme.colors.foreground,
  theme.colors.background, // optional background
);
```

## Typography

### Typography Scale

ForUI uses a Tailwind-inspired typography scale:

```dart
final theme = context.theme;

theme.typography.xs    // 12px, height: 1
theme.typography.sm    // 14px, height: 1.25
theme.typography.base  // 16px, height: 1.5 (default)
theme.typography.lg    // 18px, height: 1.75
theme.typography.xl    // 20px, height: 1.75
theme.typography.xl2   // 22px, height: 2
theme.typography.xl3   // 30px, height: 2.25
theme.typography.xl4   // 36px, height: 2.5
theme.typography.xl5   // 48px, height: 1
theme.typography.xl6   // 60px, height: 1
theme.typography.xl7   // 72px, height: 1
theme.typography.xl8   // 96px, height: 1
```

### Typography Usage

```dart
// Apply to Text widget
Text('Hello', style: theme.typography.lg)

// Customize with copyWith
Text(
  'Important',
  style: theme.typography.xl2.copyWith(
    fontWeight: FontWeight.bold,
    color: theme.colors.primary,
  ),
)

// Muted text pattern
Text(
  'Secondary info',
  style: theme.typography.sm.copyWith(
    color: theme.colors.mutedForeground
  ),
)
```

## Common Widgets

### Buttons

```dart
// Primary button (default)
FButton(
  onPress: () {},
  child: const Text('Click Me'),
)

// Button variants
FButton(
  style: FButtonStyle.primary(),
  onPress: () {},
  child: const Text('Primary'),
)

FButton(
  style: FButtonStyle.secondary(),
  onPress: () {},
  child: const Text('Secondary'),
)

FButton(
  style: FButtonStyle.destructive(),
  onPress: () {},
  child: const Text('Delete'),
)

FButton(
  style: FButtonStyle.outline(),
  onPress: () {},
  child: const Text('Outline'),
)

FButton(
  style: FButtonStyle.ghost(),
  onPress: () {},
  child: const Text('Ghost'),
)

// Button with icon
FButton(
  onPress: () {},
  prefix: const Icon(FIcons.mail),
  child: const Text('Send Email'),
)

// Icon-only button
FButton.icon(
  style: FButtonStyle.ghost(),
  onPress: () {},
  child: const Icon(FIcons.x),
)

// Disabled button
FButton(
  onPress: null, // null = disabled
  child: const Text('Disabled'),
)
```

### Cards

```dart
// Simple card with title and subtitle
FCard(
  title: const Text('Card Title'),
  subtitle: const Text('Card description goes here'),
  child: Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text('Card content'),
  ),
)

// Custom card (raw)
FCard.raw(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Custom content'),
      ],
    ),
  ),
)
```

### Alerts

```dart
// Primary alert
FAlert(
  icon: Icon(FIcons.info),
  title: const Text('Information'),
  subtitle: const Text('This is an informational message.'),
)

// Destructive alert
FAlert(
  style: FAlertStyle.destructive(),
  icon: Icon(FIcons.alertTriangle),
  title: const Text('Error'),
  subtitle: const Text('Something went wrong!'),
)

// Custom icon color
FAlert(
  icon: Icon(FIcons.lightbulb, color: theme.colors.primary),
  title: const Text('Tip'),
  subtitle: const Text('Here\'s a helpful tip.'),
)
```

### Dialogs

```dart
// Show dialog
showFDialog(
  context: context,
  builder: (dialogContext, style, animation) => FDialog(
    style: (_) => style,
    animation: animation,
    direction: Axis.vertical, // or Axis.horizontal
    title: const Text('Confirm Action'),
    body: const Text('Are you sure you want to proceed?'),
    actions: [
      FButton(
        style: FButtonStyle.outline(),
        onPress: () => Navigator.pop(dialogContext),
        child: const Text('Cancel'),
      ),
      FButton(
        onPress: () {
          // Handle confirm
          Navigator.pop(dialogContext);
        },
        child: const Text('Confirm'),
      ),
    ],
  ),
);

// Adaptive dialog (vertical on small screens, horizontal on large)
FDialog.adaptive(
  actions: [...],
  title: const Text('Title'),
  body: const Text('Body'),
)
```

### Toasts

```dart
// Show toast
showFToast(
  context: context,
  title: const Text('Success'),
  description: const Text('Operation completed successfully!'),
)

// Toast with icon
showFToast(
  context: context,
  icon: const Icon(FIcons.checkCircle),
  title: const Text('Saved'),
  description: const Text('Your changes have been saved.'),
)

// Toast with custom duration
showFToast(
  context: context,
  title: const Text('Warning'),
  duration: const Duration(seconds: 10),
)

// Toast without auto-dismiss
showFToast(
  context: context,
  title: const Text('Important'),
  duration: null, // Won't auto-dismiss
)
```

### Scaffold & Headers

```dart
// Root page (no back button)
FScaffold(
  header: const FHeader(
    title: Text('My App'),
  ),
  child: YourContent(),
)

// Nested page (with back button and actions)
FScaffold(
  header: FHeader.nested(
    title: const Text('Details'),
    prefixes: [
      FHeaderAction.back(onPress: () => Navigator.pop(context)),
    ],
    suffixes: [
      FHeaderAction(
        icon: const Icon(FIcons.settings),
        onPress: () {},
      ),
    ],
  ),
  child: YourContent(),
)

// With footer
FScaffold(
  header: const FHeader(title: Text('My App')),
  footer: FBottomNavigationBar(
    index: _selectedIndex,
    onChange: (index) => setState(() => _selectedIndex = index),
    children: const [
      FBottomNavigationBarItem(icon: Icon(FIcons.house)),
      FBottomNavigationBarItem(icon: Icon(FIcons.search)),
      FBottomNavigationBarItem(icon: Icon(FIcons.settings)),
    ],
  ),
  child: YourContent(),
)

// Without automatic padding
FScaffold(
  header: const FHeader(title: Text('Chat')),
  childPad: false, // Disable automatic padding
  child: YourContent(),
)
```

**FHeader Types:**
- `FHeader()` - Root page header (title aligned to start, only suffixes)
- `FHeader.nested()` - Nested page header (title centered, has prefixes and suffixes)

**FHeaderAction:**
- `FHeaderAction(icon: Icon(...), onPress: ...)` - Custom action
- `FHeaderAction.back(onPress: ...)` - Back arrow
- `FHeaderAction.x(onPress: ...)` - X/close icon

### Progress Indicators

```dart
// Circular progress (indeterminate)
const FCircularProgress()

// Circular progress variants
const FCircularProgress.loader()
const FCircularProgress.pinwheel()

// Linear progress (indeterminate)
const FProgress()

// Determinate progress
FDeterminateProgress(value: 0.7) // 70%
```

### Icons

ForUI includes Lucide icons via `FIcons`:

```dart
Icon(FIcons.home)
Icon(FIcons.settings)
Icon(FIcons.user)
Icon(FIcons.search)
Icon(FIcons.mail)
Icon(FIcons.arrowLeft)
Icon(FIcons.arrowRight)
Icon(FIcons.chevronLeft)
Icon(FIcons.chevronRight)
Icon(FIcons.x)
Icon(FIcons.check)
Icon(FIcons.info)
Icon(FIcons.alertTriangle)
Icon(FIcons.calendar)
// ... and many more
```

## Hooks Integration

ForUI provides hooks via the `forui_hooks` package:

```dart
import 'package:forui_hooks/forui_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// Popover controller
class MyWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final controller = useFPopoverController();
    
    return FButton(
      onPress: controller.toggle,
      child: const Text('Toggle Popover'),
    );
  }
}
```

Available hooks:
- `useFPopoverController` - Popover control
- `useFAccordionController` - Accordion control
- `useFCalendarController` - Calendar control
- `useFTabController` - Tab control
- `useFSliderController` - Slider control
- And more...

## Common Patterns

### Loading States

```dart
Widget build(BuildContext context) {
  return isLoading 
    ? const Center(child: FCircularProgress())
    : YourContent();
}
```

### Empty States

```dart
Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(FIcons.inbox, size: 64, color: theme.colors.mutedForeground),
      const SizedBox(height: 16),
      Text('No items found', style: theme.typography.xl),
      const SizedBox(height: 8),
      Text(
        'Get started by adding your first item',
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground
        ),
      ),
    ],
  ),
)
```

### Error States

```dart
FAlert(
  style: FAlertStyle.destructive(),
  icon: Icon(FIcons.alertCircle),
  title: const Text('Error'),
  subtitle: Text(errorMessage),
)
```

### Confirmation Dialogs

```dart
Future<bool?> _confirmDelete() async {
  return showFDialog<bool>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: (_) => style,
      animation: animation,
      direction: Axis.vertical,
      title: const Text('Confirm Deletion'),
      body: const Text('This action cannot be undone.'),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FButton(
          style: FButtonStyle.destructive(),
          onPress: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
```

## Migration from shadcn_ui

### Import Changes

```dart
// Before
import 'package:shadcn_ui/shadcn_ui.dart';

// After
import 'package:forui/forui.dart';
```

### Theme Access

```dart
// Before
final theme = ShadTheme.of(context);
theme.colorScheme.primary
theme.textTheme.h1

// After
final theme = context.theme;
theme.colors.primary
theme.typography.xl4
```

### Widget Mapping

| shadcn_ui | ForUI |
|-----------|-------|
| `ShadApp` | `MaterialApp` + `FTheme` + `FToaster` |
| `ShadTheme.of(context)` | `context.theme` |
| `ShadButton()` | `FButton()` |
| `ShadButton.ghost()` | `FButton(style: FButtonStyle.ghost())` |
| `ShadButton.destructive()` | `FButton(style: FButtonStyle.destructive())` |
| `ShadIconButton()` | `FButton.icon()` |
| `ShadCard()` | `FCard()` or `FCard.raw()` |
| `ShadAlert()` | `FAlert()` |
| `ShadDialog.alert()` | `FDialog()` |
| `showShadDialog()` | `showFDialog()` |
| `ShadToast()` | `showFToast()` |
| `ShadSonner.of(context).show()` | `showFToast(context: context, ...)` |
| `LucideIcons.x` | `FIcons.x` |

### Property Mapping

| shadcn_ui | ForUI |
|-----------|-------|
| `onPressed:` | `onPress:` |
| `description:` | `subtitle:` (for FCard, FAlert) |
| `theme.colorScheme.X` | `theme.colors.X` |
| `theme.textTheme.h1` | `theme.typography.xl4` |
| `theme.textTheme.h2` | `theme.typography.xl3` |
| `theme.textTheme.h3` | `theme.typography.xl2` |
| `theme.textTheme.large` | `theme.typography.lg` |
| `theme.textTheme.p` | `theme.typography.base` |
| `theme.textTheme.small` | `theme.typography.sm` |
| `theme.textTheme.muted` | `theme.typography.sm.copyWith(color: theme.colors.mutedForeground)` |

### Style Classes

ForUI uses style builder pattern:

```dart
// shadcn_ui
ShadButton.destructive(child: Text('Delete'))

// ForUI
FButton(
  style: FButtonStyle.destructive(),
  child: Text('Delete'),
)
```

## CLI Tools

ForUI provides CLI tools for customization:

```bash
# Generate custom theme
dart run forui theme create my-theme

# Generate custom widget style
dart run forui style create button

# Create Material theme mapping snippet
dart run forui snippet create material-mapping
```

## Resources

- **Official Docs**: https://forui.dev/docs
- **API Reference**: https://pub.dev/documentation/forui
- **GitHub**: https://github.com/duobaseio/forui
- **Examples**: https://forui.dev/docs/widgets

## Best Practices

1. **Theme Access**: Always use `context.theme` for consistency
2. **Colors**: Use semantic colors (`primary`, `secondary`, etc.) instead of hardcoded colors
3. **Typography**: Use the typography scale for consistent text sizing
4. **Icons**: Use `FIcons` for consistent icon usage
5. **Toasts**: Wrap app with `FToaster` to enable toast notifications
6. **Buttons**: Use appropriate button styles (`primary`, `destructive`, `ghost`, etc.)
7. **Loading States**: Use `FCircularProgress` or `FProgress` for loading indicators
8. **Empty States**: Create informative empty states with icons and descriptions
9. **Error Handling**: Use destructive alerts for errors

## Troubleshooting

### Theme not found

**Problem**: `context.theme` returns default theme

**Solution**: Ensure `FTheme` widget is an ancestor:

```dart
FTheme(
  data: FThemes.zinc.light,
  child: YourWidget(),
)
```

### Toast not showing

**Problem**: `showFToast` doesn't display

**Solution**: Ensure `FToaster` wraps your app in the builder:

```dart
MaterialApp(
  builder: (context, child) => FTheme(
    data: theme,
    child: FToaster(child: child!),
  ),
)
```

### Icons not displaying

**Problem**: `FIcons.X` shows empty box

**Solution**: ForUI icons should work automatically. Ensure you have the latest forui version.

---

**Last Updated**: January 2026  
**ForUI Version**: 0.17.0

