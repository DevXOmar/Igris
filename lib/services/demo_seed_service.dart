import 'package:hive/hive.dart';

import '../core/utils/date_utils.dart' as app_date_utils;
import '../models/daily_log.dart';
import '../models/domain.dart';
import '../models/feat.dart';
import '../models/player_profile.dart';
import '../models/rival.dart';
import '../models/task.dart';
import '../providers/progression_provider.dart';

class DemoSeedService {
  static const _settingsBoxName = 'settingsBox';
  static const _seedKey = 'demoSeedAppliedV1';

  static bool _statsAreDefault(Map<String, int> stats) {
    final defaults = PlayerProfile.defaultStats;
    if (stats.length != defaults.length) return false;
    for (final e in defaults.entries) {
      if (stats[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _looksLikeUserProfile(PlayerProfile profile) {
    if (profile.name.trim().isNotEmpty) return true;
    if (profile.level != 1) return true;
    if (profile.currentXP != 0) return true;
    if (profile.totalXP != 0) return true;
    if (profile.rank != 'E') return true;
    if (profile.activeTitleIds.isNotEmpty) return true;
    if (profile.unlockedTitleIds.isNotEmpty) return true;
    if (profile.feats.isNotEmpty) return true;
    if (profile.totalTasksCompleted != 0) return true;
    if (profile.weeklyGoalsCompleted != 0) return true;
    if (profile.longestStreak != 0) return true;
    if (profile.lastStreakMilestoneAwarded != 0) return true;
    if (profile.unspentStatPoints != 0) return true;
    if (profile.statPointsAwarded != 0) return true;
    if (!_statsAreDefault(profile.stats)) return true;
    return false;
  }

  /// Seeds a rich demo dataset.
  ///
  /// This is intended for local testing only and must be enabled explicitly via
  /// `--dart-define=IGRIS_DEMO_SEED=true`.
  static Future<void> maybeSeed({required bool enabled}) async {
    if (!enabled) return;

    final settingsBox = Hive.box(_settingsBoxName);
    final alreadySeeded = settingsBox.get(_seedKey) == true;
    if (alreadySeeded) return;

    final domainsBox = Hive.box<Domain>('domainsBox');
    final tasksBox = Hive.box<Task>('tasksBox');
    final rivalsBox = Hive.box<Rival>('rivalsBox');
    final logsBox = Hive.box<DailyLog>('dailyLogsBox');
    final profileBox = Hive.box<PlayerProfile>('playerProfileBox');

    // Only seed into a fresh workspace to avoid clobbering real user data.
    final hasAnyData =
        domainsBox.isNotEmpty || tasksBox.isNotEmpty || rivalsBox.isNotEmpty;
    final existingProfile = profileBox.get('profile');
    final hasProfile =
      existingProfile != null && _looksLikeUserProfile(existingProfile);

    if (hasAnyData || hasProfile) {
      return;
    }

    final now = DateTime.now();

    // ── Domains ───────────────────────────────────────────────────────────
    final domains = <Domain>[
      Domain(id: 'd_academics', name: 'Academics', strength: 220, isActive: true),
      Domain(id: 'd_boxing', name: 'Boxing', strength: 80, isActive: true),
      Domain(id: 'd_ds', name: 'DS', strength: 140, isActive: true),
      Domain(id: 'd_stocks', name: 'Stocks & Market', strength: 90, isActive: true),
      Domain(id: 'd_vachan', name: 'Vachan', strength: 60, isActive: true),
    ];

    for (final d in domains) {
      await domainsBox.put(d.id, d);
    }

    // ── Tasks ─────────────────────────────────────────────────────────────
    final tasks = <Task>[
      // Academics
      Task(id: 't_ac_1', domainId: 'd_academics', title: 'Read 10 pages', isRecurring: true),
      Task(id: 't_ac_2', domainId: 'd_academics', title: 'Solve 20 problems', isRecurring: true),
      Task(id: 't_ac_3', domainId: 'd_academics', title: 'Revise flashcards', isRecurring: true),
      Task(id: 't_ac_4', domainId: 'd_academics', title: 'Mock test (30m)', isRecurring: false),

      // Boxing
      Task(id: 't_bx_1', domainId: 'd_boxing', title: 'Footwork drills', isRecurring: true),
      Task(id: 't_bx_2', domainId: 'd_boxing', title: 'Shadow boxing (6 rounds)', isRecurring: true),
      Task(id: 't_bx_3', domainId: 'd_boxing', title: 'Heavy bag (8 rounds)', isRecurring: true),
      Task(id: 't_bx_4', domainId: 'd_boxing', title: 'Mobility + stretch', isRecurring: true),

      // DS
      Task(id: 't_ds_1', domainId: 'd_ds', title: 'LeetCode (1 problem)', isRecurring: true),
      Task(id: 't_ds_2', domainId: 'd_ds', title: 'System design notes', isRecurring: true),
      Task(id: 't_ds_3', domainId: 'd_ds', title: 'Project commit', isRecurring: true),
      Task(id: 't_ds_4', domainId: 'd_ds', title: 'Review fundamentals', isRecurring: false),

      // Stocks
      Task(id: 't_st_1', domainId: 'd_stocks', title: 'Market scan (10m)', isRecurring: true),
      Task(id: 't_st_2', domainId: 'd_stocks', title: 'Read 1 annual report section', isRecurring: true),
      Task(id: 't_st_3', domainId: 'd_stocks', title: 'Update watchlist', isRecurring: true),
      Task(id: 't_st_4', domainId: 'd_stocks', title: 'Journal 1 trade idea', isRecurring: false),

      // Vachan
      Task(id: 't_va_1', domainId: 'd_vachan', title: 'Meditation (10m)', isRecurring: true),
      Task(id: 't_va_2', domainId: 'd_vachan', title: 'Gratitude (3 lines)', isRecurring: true),
      Task(id: 't_va_3', domainId: 'd_vachan', title: 'Read 1 page (wisdom)', isRecurring: true),
    ];

    for (final t in tasks) {
      await tasksBox.put(t.id, t);
    }

    // ── Weekly logs (to show progress bars filling) ───────────────────────
    final today = app_date_utils.DateUtils.today;
    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);

    // Aim: ~14% for Stocks (4 completions out of 4 tasks * 7 days = 28).
    final stocksTaskIds = tasks
        .where((t) => t.domainId == 'd_stocks')
        .map((t) => t.id)
        .toList(growable: false);

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      if (date.isAfter(today)) break;

      final key = app_date_utils.DateUtils.getDateKey(date);

      final completed = <String>[];
      if (i < 4 && i < stocksTaskIds.length) {
        // Complete one Stocks task for the first 4 days.
        completed.add(stocksTaskIds[i]);
      }

      final log = DailyLog(
        date: date,
        completedTaskIds: completed,
        graceUsed: i == 2, // mid-week grace example
      );
      await logsBox.put(key, log);
    }

    // ── Rivals ────────────────────────────────────────────────────────────
    final rivals = <Rival>[
      Rival(
        id: 'r_1',
        name: 'The Apex Analyst',
        domain: 'Stocks & Market',
        description: 'Disciplined research, ruthless clarity.',
        lastAchievement: 'Closed week with 5/5 execution',
        lastUpdated: now.subtract(const Duration(hours: 7)),
        threatLevel: 4,
        categoryKey: RivalCategory.apex.key,
      ),
      Rival(
        id: 'r_2',
        name: 'Iron Hands',
        domain: 'Boxing',
        description: 'Consistency in the trenches.',
        lastAchievement: 'Completed 30-day conditioning block',
        lastUpdated: now.subtract(const Duration(days: 1)),
        threatLevel: 3,
        categoryKey: RivalCategory.proximal.key,
      ),
      Rival(
        id: 'r_3',
        name: 'Mythic Builder',
        domain: 'DS',
        description: 'Ships relentlessly. No excuses.',
        lastAchievement: 'Launched a full-stack feature set',
        lastUpdated: now.subtract(const Duration(days: 2)),
        threatLevel: 5,
        categoryKey: RivalCategory.mythic.key,
      ),
    ];

    for (final r in rivals) {
      await rivalsBox.put(r.id, r);
    }

    // ── Profile (high level + lots of titles) ─────────────────────────────
    final allTitleIds =
        TitleDefinitions.all.map((t) => t.id).toList(growable: false);

    final profile = PlayerProfile(
      name: 'Demo Hunter',
      level: 42,
      currentXP: 78,
      totalXP: 25000,
      rank: 'S',
      activeTitleIds: allTitleIds.take(2).toList(growable: false),
      unlockedTitleIds: allTitleIds,
      feats: [
        Feat(
          name: 'Gate Cleared',
          description: 'Completed a full week at 100% execution.',
          timestamp: now.subtract(const Duration(days: 21)),
        ),
      ],
      totalTasksCompleted: 1240,
      weeklyGoalsCompleted: 14,
      longestStreak: 67,
      lastStreakMilestoneAwarded: 30,
      unspentStatPoints: 8,
      statPointsAwarded: 30,
      stats: const {
        'presence': 24,
        'strength': 18,
        'agility': 16,
        'endurance': 20,
        'intelligence': 22,
        'discipline': 28,
      },
    );

    await profileBox.put('profile', profile);

    await settingsBox.put(_seedKey, true);
  }
}
