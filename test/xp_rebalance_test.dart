import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:igris/models/daily_log.dart';
import 'package:igris/models/domain.dart';
import 'package:igris/models/feat.dart';
import 'package:igris/models/fuel_vault_entry.dart';
import 'package:igris/models/player_profile.dart';
import 'package:igris/models/rival.dart';
import 'package:igris/models/task.dart';
import 'package:igris/providers/progression_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    hiveTestDir = await Directory.systemTemp.createTemp('igris_hive_xp_test_');
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

  setUp(() async {
    // Ensure tests don't leak persisted progression state across cases.
    await Hive.box<PlayerProfile>('playerProfileBox').clear();
    await Hive.box<DailyLog>('dailyLogsBox').clear();
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

  test('XP reward values are rebalanced', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(progressionProvider.notifier);

    await notifier.addXP(XpRewards.taskComplete);

    expect(container.read(progressionProvider).totalXP, 15);

    await notifier.onDomainCompleted();
    expect(container.read(progressionProvider).totalXP, 40);

    await notifier.onWeeklyGoalCompleted();
    expect(container.read(progressionProvider).totalXP, 140);
  });

  test('45/60 streak milestones award XP once', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(progressionProvider.notifier);

    await notifier.syncStreak(44);

    final after44 = container.read(progressionProvider).totalXP;
    expect(after44, 500);

    await notifier.syncStreak(45);
    expect(container.read(progressionProvider).totalXP, 800);

    await notifier.syncStreak(45);
    expect(container.read(progressionProvider).totalXP, 800);

    await notifier.syncStreak(60);
    expect(container.read(progressionProvider).totalXP, 1200);

    await notifier.syncStreak(60);
    expect(container.read(progressionProvider).totalXP, 1200);

    final milestones =
        container.read(progressionProvider).achievedStreakMilestones;
    expect(milestones, containsAll(<int>[7, 14, 21, 30, 45, 60]));
  });

  test('90-day streak unlocks title (no XP) once', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(progressionProvider.notifier);

    await notifier.syncStreak(60);

    final before90 = container.read(progressionProvider).totalXP;

    await notifier.syncStreak(90);

    final profile = container.read(progressionProvider);
    expect(profile.totalXP, before90);
    expect(profile.unlockedTitleIds, contains('unbreakable'));
    expect(profile.achievedStreakMilestones, contains(90));

    final unlockedCount =
        profile.unlockedTitleIds.where((id) => id == 'unbreakable').length;
    expect(unlockedCount, 1);

    await notifier.syncStreak(90);

    final profile2 = container.read(progressionProvider);
    expect(
        profile2.unlockedTitleIds.where((id) => id == 'unbreakable').length, 1);
    expect(profile2.totalXP, before90);
  });
}
