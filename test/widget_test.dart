import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:igris/main.dart';
import 'package:igris/screens/home/home_screen.dart';
import 'package:igris/models/daily_log.dart';
import 'package:igris/models/domain.dart';
import 'package:igris/models/feat.dart';
import 'package:igris/models/fuel_vault_entry.dart';
import 'package:igris/models/player_profile.dart';
import 'package:igris/models/rival.dart';
import 'package:igris/models/task.dart';
import 'package:igris/providers/progression_provider.dart';
import 'package:igris/widgets/ui/igris_button.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    hiveTestDir = await Directory.systemTemp.createTemp('igris_hive_test_');
    Hive.init(hiveTestDir.path);

    Hive.registerAdapter(DomainAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(DailyLogAdapter());
    Hive.registerAdapter(FuelVaultEntryAdapter());
    Hive.registerAdapter(RivalAdapter());
    Hive.registerAdapter(FeatAdapter());
    Hive.registerAdapter(PlayerProfileAdapter());

    await Hive.openBox<Domain>('domainsBox');
    await Hive.openBox<Task>('tasksBox');
    await Hive.openBox<DailyLog>('dailyLogsBox');
    await Hive.openBox<FuelVaultEntry>('fuelVaultBox');
    await Hive.openBox<Rival>('rivalsBox');
    await Hive.openBox('settingsBox');
    await Hive.openBox<PlayerProfile>('playerProfileBox');
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Best-effort cleanup for tests.
    }
    try {
      if (hiveTestDir.existsSync()) {
        await hiveTestDir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup for tests.
    }
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: IgrisApp()));

    // flutter_animate schedules some zero-duration timers on initState.
    // Pump an extra frame to flush them so the test doesn't fail on teardown.
    await tester.pump(const Duration(milliseconds: 1));

    // First launch: name is empty, so onboarding should be shown.
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(IgrisApp)));
    await container.read(progressionProvider.notifier).updateName('Test User');

    // Allow async profile save + root rebuild.
    await tester.pump();
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Main app should now be visible.
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
