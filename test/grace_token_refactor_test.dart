import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igris/core/utils/date_utils.dart' as app_date_utils;
import 'package:igris/models/daily_log.dart';
import 'package:igris/models/domain.dart';
import 'package:igris/models/feat.dart';
import 'package:igris/models/fuel_vault_entry.dart';
import 'package:igris/models/player_profile.dart';
import 'package:igris/models/rival.dart';
import 'package:igris/models/task.dart';
import 'package:igris/providers/daily_log_provider.dart';
import 'package:igris/providers/progression_provider.dart';
import 'package:igris/providers/weekly_stats_provider.dart';

void main() {
  late Directory hiveTestDir;

  Future<void> seedActiveDomainAndTasks() async {
    await Hive.box<Domain>('domainsBox').put(
      'd1',
      Domain(id: 'd1', name: 'Work', isActive: true),
    );

    await Hive.box<Task>('tasksBox').put(
      't1',
      Task(id: 't1', domainId: 'd1', title: 'Task 1', isRecurring: true),
    );
    await Hive.box<Task>('tasksBox').put(
      't2',
      Task(id: 't2', domainId: 'd1', title: 'Task 2', isRecurring: true),
    );
    await Hive.box<Task>('tasksBox').put(
      't3',
      Task(id: 't3', domainId: 'd1', title: 'Task 3', isRecurring: true),
    );
  }

  Future<void> saveLog(DailyLog log) async {
    final key = app_date_utils.DateUtils.getDateKey(log.date);
    await Hive.box<DailyLog>('dailyLogsBox').put(key, log);
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    hiveTestDir = await Directory.systemTemp.createTemp('igris_hive_grace_test_');
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
    await Hive.box<PlayerProfile>('playerProfileBox').clear();
    await Hive.box<DailyLog>('dailyLogsBox').clear();
    await Hive.box<Domain>('domainsBox').clear();
    await Hive.box<Task>('tasksBox').clear();
    await Hive.box('settingsBox').clear();
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

  test('Complete 3 tasks + grace: XP counted normally', () async {
    final today = app_date_utils.DateUtils.today;

    await seedActiveDomainAndTasks();

    await saveLog(
      DailyLog(
        date: today,
        graceUsed: true,
        completedTaskIds: [],
        rewardedTaskIds: [],
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final logNotifier = container.read(dailyLogProvider.notifier);

    await logNotifier.completeTask('t1', 'd1');
    await logNotifier.completeTask('t2', 'd1');
    await logNotifier.completeTask('t3', 'd1');

    final profile = container.read(progressionProvider);

    // 3 task rewards (15 XP each), plus first-task-of-day bonus (20 XP),
    // all multiplied by early-game 1.8x at level 1:
    // (15 + 20) * 1.8 + 15 * 1.8 + 15 * 1.8 = 63 + 27 + 27 = 117
    expect(profile.totalXP, 117);
  });

  test('Complete 0 tasks + grace: XP=0, streak preserved', () async {
    final today = app_date_utils.DateUtils.today;
    final yesterday = today.subtract(const Duration(days: 1));

    await seedActiveDomainAndTasks();

    // Yesterday: at least one completion.
    await saveLog(
      DailyLog(
        date: yesterday,
        graceUsed: false,
        completedTaskIds: ['t1'],
        rewardedTaskIds: [],
      ),
    );

    // Today: grace used, but no tasks completed.
    await saveLog(
      DailyLog(
        date: today,
        graceUsed: true,
        completedTaskIds: [],
        rewardedTaskIds: [],
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final stats = container.read(weeklyStatsProvider);
    expect(stats.currentStreak, 2);

    // No tasks completed today, so no XP should have been awarded.
    expect(container.read(progressionProvider).totalXP, 0);
  });

  test('Complete tasks without grace: normal XP + streak', () async {
    final today = app_date_utils.DateUtils.today;

    await seedActiveDomainAndTasks();

    // Ensure today exists and grace is NOT active.
    await saveLog(
      DailyLog(
        date: today,
        graceUsed: false,
        completedTaskIds: [],
        rewardedTaskIds: [],
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(dailyLogProvider.notifier).completeTask('t1', 'd1');

    // First task of day: (15 + 20) * 1.8 = 63
    expect(container.read(progressionProvider).totalXP, 63);

    final stats = container.read(weeklyStatsProvider);
    expect(stats.currentStreak, 1);
  });

  test('No tasks + no grace: streak breaks', () async {
    final today = app_date_utils.DateUtils.today;
    final yesterday = today.subtract(const Duration(days: 1));

    await seedActiveDomainAndTasks();

    // Yesterday qualifies.
    await saveLog(
      DailyLog(
        date: yesterday,
        graceUsed: false,
        completedTaskIds: ['t1'],
        rewardedTaskIds: [],
      ),
    );

    // Today: no completions and no grace.
    await saveLog(
      DailyLog(
        date: today,
        graceUsed: false,
        completedTaskIds: [],
        rewardedTaskIds: [],
      ),
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final stats = container.read(weeklyStatsProvider);
    expect(stats.currentStreak, 0);
  });
}
