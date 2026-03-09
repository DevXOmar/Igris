import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// responsive_framework: wraps every screen with breakpoint-aware layout logic.
// Breakpoints: MOBILE (0–480), TABLET (481–1024), DESKTOP (1025+)
import 'package:responsive_framework/responsive_framework.dart';
// shadcn_ui: premium component library (cards, buttons, inputs, dialogs).
// ShadTheme injected into the MaterialApp builder so ShadCard/ShadButton
// pick up our dark color palette throughout the widget tree.
import 'package:shadcn_ui/shadcn_ui.dart';
import 'core/theme/app_theme.dart';
import 'models/domain.dart';
import 'models/task.dart';
import 'models/daily_log.dart';
import 'models/fuel_vault_entry.dart';
import 'models/rival.dart';
import 'models/feat.dart';
import 'models/player_profile.dart';
import 'screens/home/home_screen.dart';
import 'widgets/animations/animation_overlay.dart';

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Disable Android glow/stretch overscroll effects for a tighter, more
    // "professional" feel across all scrollables.
    return child;
  }
}

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters
  Hive.registerAdapter(DomainAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(DailyLogAdapter());
  Hive.registerAdapter(FuelVaultEntryAdapter());
  Hive.registerAdapter(RivalAdapter());
  Hive.registerAdapter(FeatAdapter());
  Hive.registerAdapter(PlayerProfileAdapter());
  
  // Open Hive Boxes
  await Hive.openBox<Domain>('domainsBox');
  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<DailyLog>('dailyLogsBox');
  await Hive.openBox<FuelVaultEntry>('fuelVaultBox');
  await Hive.openBox<Rival>('rivalsBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox<PlayerProfile>('playerProfileBox');
  
  runApp(
    // ProviderScope is required for Riverpod
    // All providers must be descendants of ProviderScope
    const ProviderScope(
      child: IgrisApp(),
    ),
  );
}

/// Main application widget
class IgrisApp extends StatelessWidget {
  const IgrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Igris',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      // IgrisThemeColors extension is embedded in darkTheme.extensions.
      theme: AppTheme.darkTheme,
      // builder wraps every route with:
      //   1. ResponsiveBreakpoints — makes layout adapt to MOBILE/TABLET/DESKTOP
      //   2. ShadTheme — provides shadcn_ui components with our dark palette
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          // MOBILE ≤ 480 px (phones)
          // TABLET 481–1024 px (tablets, small laptops)
          // DESKTOP ≥ 1025 px (wide screens, web)
          breakpoints: const [
            Breakpoint(start: 0, end: 480, name: MOBILE),
            Breakpoint(start: 481, end: 1024, name: TABLET),
            Breakpoint(start: 1025, end: double.infinity, name: DESKTOP),
          ],
          child: ShadTheme(
            // ShadThemeData injects our dark palette into shadcn_ui components.
            // colorScheme uses ShadSlateColorScheme.dark() as the base —
            // slate is the closest preset to our #0A0F1C background.
            data: ShadThemeData(
              brightness: Brightness.dark,
              colorScheme: const ShadSlateColorScheme.dark(),
            ),
            child: child!,
          ),
        );
      },
      home: const _IgrisRoot(),
    );
  }
}

/// Root widget that places [AnimationOverlay] above [HomeScreen].
///
/// The overlay watches [animationServiceProvider] and renders animation
/// widgets on top of the full app when events are fired from anywhere in the
/// widget tree. All overlays are [IgnorePointer] — user interaction is never
/// blocked during an animation.
class _IgrisRoot extends StatelessWidget {
  const _IgrisRoot();

  @override
  Widget build(BuildContext context) {
    return const AnimationOverlay(child: HomeScreen());
  }
}
