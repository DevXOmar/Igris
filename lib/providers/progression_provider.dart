import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import '../models/feat.dart';
import '../models/player_profile.dart';
import '../providers/domain_provider.dart';
import '../providers/task_provider.dart';
import '../providers/weekly_stats_provider.dart';
import '../services/daily_log_service.dart';
import '../services/progression_service.dart';
import '../services/animation_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TITLE DEFINITIONS
// Static catalogue of every title a hunter can earn.
// Unlock logic lives here (pure function of PlayerProfile).
// ─────────────────────────────────────────────────────────────────────────────

class TitleDefinition {
  final String id;
  final String name;
  final String description;

  /// Human-readable unlock hint shown in the UI.
  final String unlockCondition;

  final IconData icon;

  /// Returns true when [profile] satisfies the unlock requirement.
  final bool Function(TitleUnlockContext context) checkCondition;

  const TitleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockCondition,
    required this.icon,
    required this.checkCondition,
  });
}

/// Derived stats available when evaluating title unlock conditions.
///
/// This is constructed inside [ProgressionNotifier] so title checks can use
/// current weekly stats and domain/task data in addition to [PlayerProfile].
class TitleUnlockContext {
  final PlayerProfile profile;
  final WeeklyStats weeklyStats;
  final DomainState domainState;
  final TaskState taskState;
  final DailyLogService _dailyLogService;

  TitleUnlockContext({
    required this.profile,
    required this.weeklyStats,
    required this.domainState,
    required this.taskState,
    DailyLogService? dailyLogService,
  }) : _dailyLogService = dailyLogService ?? DailyLogService();

  /// Total completed task instances within the current streak window.
  ///
  /// Uses [weeklyStats.currentStreak] (days) and sums completed IDs in logs.
  late final int completedTaskInstancesInCurrentStreak = () {
    final streakDays = weeklyStats.currentStreak;
    if (streakDays <= 0) return 0;

    final today = app_date_utils.DateUtils.today;
    var total = 0;
    for (int i = 0; i < streakDays; i++) {
      final date = today.subtract(Duration(days: i));
      final log = _dailyLogService.getLogForDate(date);
      if (log == null) continue;
      total += log.completedTaskIds.length;
    }
    return total;
  }();

  /// Distinct one-time tasks that have ever been completed at least once.
  ///
  /// Used as a proxy for "backlog" tasks.
  late final int distinctOneTimeTasksCompleted = () {
    final oneTimeTaskIds = taskState.oneTimeTasks.map((t) => t.id).toSet();
    if (oneTimeTaskIds.isEmpty) return 0;

    final completed = <String>{};
    for (final log in _dailyLogService.getAllLogs()) {
      for (final id in log.completedTaskIds) {
        if (oneTimeTaskIds.contains(id)) {
          completed.add(id);
        }
      }
    }
    return completed.length;
  }();

  int sumDomainStrengthWhere(bool Function(String name) predicate) {
    var total = 0;
    for (final d in domainState.domains) {
      final name = d.name.trim();
      if (name.isEmpty) continue;
      if (predicate(name.toLowerCase())) total += d.strength;
    }
    return total;
  }

  bool anyDomainStrengthAtLeast(int threshold) {
    for (final d in domainState.domains) {
      if (d.strength >= threshold) return true;
    }
    return false;
  }

  List<double> get _activeWeeklyProgressValues {
    if (weeklyStats.weeklyProgress.isEmpty) return const [];
    final values = <double>[];
    for (final domain in domainState.activeDomains) {
      final progress = weeklyStats.weeklyProgress[domain];
      if (progress != null) values.add(progress);
    }
    return values;
  }

  bool get hasActivityAcrossAllActiveDomainsThisWeek {
    final active = domainState.activeDomains;
    if (active.length < 2) return false;
    for (final domain in active) {
      final progress = weeklyStats.weeklyProgress[domain] ?? 0.0;
      if (progress <= 0.0) return false;
    }
    return true;
  }

  bool get hasBalancedWeeklyProgressAcrossDomains {
    final values = _activeWeeklyProgressValues;
    if (values.length < 2) return false;
    final minP = values.reduce(min);
    final maxP = values.reduce(max);
    // Simple "balanced" heuristic: everyone is participating, and no domain
    // lags too far behind.
    return minP >= 0.40 && (maxP - minP) <= 0.25;
  }

  bool _isDayQualifiedForStreak(DateTime date) {
    final log = _dailyLogService.getLogForDate(date);
    if (log == null) return false;

    // Grace always qualifies the day.
    if (log.graceUsed) return true;

    // Match the streak criteria in weekly_stats_provider:
    // completion >= 70% across active-domain tasks.
    final allTasks = taskState.tasks.where((task) {
      final domain = domainState.getDomainById(task.domainId);
      return domain != null && domain.isActive;
    }).toList(growable: false);

    if (allTasks.isEmpty) {
      // No tasks that day — don't break the streak.
      return true;
    }

    final completedCount =
        allTasks.where((task) => log.isTaskCompleted(task.id)).length;
    final completionPercentage = (completedCount / allTasks.length) * 100;
    return completionPercentage >= 70.0;
  }

  int _graceUsedInWeek(DateTime weekStart) {
    var used = 0;
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final log = _dailyLogService.getLogForDate(date);
      if (log != null && log.graceUsed) used++;
    }
    return used;
  }

  bool get hasUnyieldingRythmForThreeWeeks {
    // Interpret requirement as 21 consecutive qualified days ending today,
    // and at most 1 grace used in each of the last 3 weeks.
    final today = app_date_utils.DateUtils.today;

    for (int i = 0; i < 21; i++) {
      final date = today.subtract(Duration(days: i));
      if (!_isDayQualifiedForStreak(date)) return false;
    }

    for (int w = 0; w < 3; w++) {
      final weekRef = today.subtract(Duration(days: 7 * w));
      final weekStart = app_date_utils.DateUtils.getStartOfWeek(weekRef);
      if (_graceUsedInWeek(weekStart) > 1) return false;
    }

    return true;
  }
}

// ignore: avoid_classes_with_only_static_members
class TitleDefinitions {
  static const int _domainConquerorStrengthThreshold = 250;

  static final RegExp _studyRe = RegExp(
    r'\b(study|studies|learn|learning|school|college|university|reading|read|book|course|exam)\b',
    caseSensitive: false,
  );
  static final RegExp _workRe = RegExp(
    r'\b(work|job|career|business|productivity|project|projects|office|deep work)\b',
    caseSensitive: false,
  );
  static final RegExp _fitnessRe = RegExp(
    r'\b(fitness|workout|gym|health|run|running|cardio|strength|training)\b',
    caseSensitive: false,
  );

  static final List<TitleDefinition> all = [
    TitleDefinition(
      id: 'novice_hunter',
      name: 'Novice Hunter',
      description: 'A new hunter steps into the gates.',
      unlockCondition: 'Complete 10 tasks',
      icon: Icons.emoji_events_outlined,
      checkCondition: (c) => c.profile.totalTasksCompleted >= 10,
    ),
    TitleDefinition(
      id: 'awakened_star',
      name: 'Awakened ★',
      description: 'Your power has begun to surface.',
      unlockCondition: 'Reach Level 5',
      icon: Icons.auto_awesome,
      checkCondition: (c) => c.profile.level >= 5,
    ),
    TitleDefinition(
      id: 'daily_survivor',
      name: 'Daily Survivor',
      description: 'You kept moving, day after day.',
      unlockCondition: '7-day streak',
      icon: Icons.shield_outlined,
      checkCondition: (c) => c.profile.longestStreak >= 7,
    ),
    TitleDefinition(
      id: 'relentless_star',
      name: 'Relentless ★',
      description: 'Consistency is your weapon.',
      unlockCondition: '30-day streak',
      icon: Icons.local_fire_department,
      checkCondition: (c) => c.profile.longestStreak >= 30,
    ),
    TitleDefinition(
      id: 'unyielding_rythm',
      name: 'The Unyielding Rythm',
      description: 'Controlled grace. Unbroken execution. Three weeks straight.',
      unlockCondition: 'Use at most 1 grace per week and maintain streak for 3 weeks',
      icon: Icons.multiline_chart,
      checkCondition: (c) => c.hasUnyieldingRythmForThreeWeeks,
    ),
    TitleDefinition(
      id: 'iron_will',
      name: 'Iron Will',
      description: 'A mind that refuses to fracture.',
      unlockCondition: '50 tasks without breaking streak',
      icon: Icons.military_tech_outlined,
      checkCondition: (c) => c.completedTaskInstancesInCurrentStreak >= 50,
    ),
    TitleDefinition(
      id: 'wolf_assassin_star',
      name: 'Wolf Assassin ★',
      description: 'Swift, precise, relentless in execution.',
      unlockCondition: '100 total tasks',
      icon: Icons.flash_on,
      checkCondition: (c) => c.profile.totalTasksCompleted >= 100,
    ),
    TitleDefinition(
      id: 'architect_star',
      name: 'Architect ★',
      description: 'Builds mastery across multiple domains.',
      unlockCondition: 'Reach Level 10',
      icon: Icons.account_tree,
      checkCondition: (c) => c.profile.level >= 10,
    ),
    TitleDefinition(
      id: 'scholar',
      name: 'Scholar',
      description: 'Knowledge through persistent discipline.',
      unlockCondition: '200 study-related tasks',
      icon: Icons.menu_book,
      checkCondition: (c) =>
          c.sumDomainStrengthWhere((n) => _studyRe.hasMatch(n)) >= 200,
    ),
    TitleDefinition(
      id: 'forge_master',
      name: 'Forge Master',
      description: 'Turns effort into output, again and again.',
      unlockCondition: '150 work/productivity tasks',
      icon: Icons.build_outlined,
      checkCondition: (c) =>
          c.sumDomainStrengthWhere((n) => _workRe.hasMatch(n)) >= 150,
    ),
    TitleDefinition(
      id: 'titan_of_fitness',
      name: 'Titan of Fitness',
      description: 'A body forged in repetition.',
      unlockCondition: '100 fitness tasks',
      icon: Icons.fitness_center,
      checkCondition: (c) =>
          c.sumDomainStrengthWhere((n) => _fitnessRe.hasMatch(n)) >= 100,
    ),
    TitleDefinition(
      id: 'shadow_walker',
      name: 'Shadow Walker',
      description: 'Moves through every domain without faltering.',
      unlockCondition: 'Consistent activity across ALL domains',
      icon: Icons.blur_on,
      checkCondition: (c) => c.hasActivityAcrossAllActiveDomainsThisWeek,
    ),
    TitleDefinition(
      id: 'domain_conqueror',
      name: 'Domain Conqueror',
      description: 'One domain stands fully conquered.',
      unlockCondition: 'Max out one domain',
      icon: Icons.flag_outlined,
      checkCondition: (c) => c.anyDomainStrengthAtLeast(_domainConquerorStrengthThreshold),
    ),
    TitleDefinition(
      id: 's_rank_candidate_star',
      name: 'S-Rank Candidate ★',
      description: 'Your presence alone shifts the room.',
      unlockCondition: 'Level 30',
      icon: Icons.stars_rounded,
      checkCondition: (c) => c.profile.level >= 30,
    ),
    TitleDefinition(
      id: 'double_dungeon_survivor',
      name: 'Double Dungeon Survivor',
      description: 'You endured the week’s crushing weight.',
      unlockCondition: '50 tasks in one week',
      icon: Icons.calendar_month_outlined,
      checkCondition: (c) => c.weeklyStats.completedTasksThisWeek >= 50,
    ),
    TitleDefinition(
      id: 'igris_blade_star',
      name: 'Igris’ Blade ★',
      description: 'Loyalty sharpened into an edge.',
      unlockCondition: '100-day streak',
      icon: Icons.gavel,
      checkCondition: (c) => c.profile.longestStreak >= 100,
    ),
    TitleDefinition(
      id: 'rulers_authority',
      name: 'Ruler’s Authority',
      description: 'Balance maintained. Order enforced.',
      unlockCondition: 'Maintain balanced weekly progress across domains',
      icon: Icons.balance,
      checkCondition: (c) => c.hasBalancedWeeklyProgressAcrossDomains,
    ),
    TitleDefinition(
      id: 'shadow_summoner_star',
      name: 'Shadow Summoner ★',
      description: 'A legion formed from relentless completion.',
      unlockCondition: '1000 total tasks',
      icon: Icons.groups_2_outlined,
      checkCondition: (c) => c.profile.totalTasksCompleted >= 1000,
    ),
    TitleDefinition(
      id: 'national_level_hunter',
      name: 'National Level Hunter',
      description: 'A name known far beyond the gates.',
      unlockCondition: 'Level 100 OR major real-world milestone',
      icon: Icons.public,
      checkCondition: (c) => c.profile.level >= 100 || c.profile.feats.isNotEmpty,
    ),
    TitleDefinition(
      id: 'kamish_slayer_reworked',
      name: 'Kamish Slayer (REWORKED)',
      description: 'You cleared what others abandoned.',
      unlockCondition: 'Clear 100+ backlog/overdue tasks',
      icon: Icons.task_alt,
      checkCondition: (c) => c.distinctOneTimeTasksCompleted >= 100,
    ),
    TitleDefinition(
      id: 'shadow_monarch_star',
      name: 'Shadow Monarch ★',
      description: 'A year of discipline — and beyond.',
      unlockCondition: '365-day streak + extreme consistency',
      icon: Icons.workspace_premium,
      checkCondition: (c) =>
          c.profile.longestStreak >= 365 && c.profile.weeklyGoalsCompleted >= 12,
    ),
  ];

  static TitleDefinition? findById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

/// XP amounts for different player actions.
class XpRewards {
  XpRewards._();

  static const int taskComplete = 10;
  static const int domainComplete = 30;
  static const int weeklyGoal = 75;
  static const int streak7 = 50;
  static const int streak14 = 100;
  static const int streak21 = 150;
  static const int streak30 = 200;
}

// ─────────────────────────────────────────────────────────────────────────────
// RANK HELPERS
// ─────────────────────────────────────────────────────────────────────────────

const List<String> kRankOrder = [
  'E',
  'D',
  'C',
  'B',
  'A',
  'S',
  'National',
  'Monarch',
];

int _rankIndex(String rank) {
  final i = kRankOrder.indexOf(rank);
  return i < 0 ? 0 : i;
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESSION NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

/// Central notifier for hunter progression.
///
/// State = [PlayerProfile] (immutable, copyWith pattern).
/// All writes go through helper methods that create a new profile instance,
/// persist to Hive, then update Riverpod state.
///
/// Entry points for external callers:
/// - [onTaskCompleted]     — call from DailyLogNotifier on task completion
/// - [onDomainCompleted]   — call when all tasks in a domain finish today
/// - [onWeeklyGoalCompleted] — call when weekly score hits 100%
/// - [onStreakMilestone]   — call when streak crosses 7/14/21/30 days
/// - [grantFeat]           — manually record a real-life achievement
/// - [equipTitle] / [unequipTitle] — toggle active title display
/// - [addXP]               — direct XP injection (public for flexibility)
class ProgressionNotifier extends Notifier<PlayerProfile> {
  static const int _baseXP = 100;
  static const int _xpPerStatPoint = 250;
  static const int _maxStatValue = PlayerProfile.defaultMaxStatValue;

  final ProgressionService _service = ProgressionService();

  @override
  PlayerProfile build() {
    final profile = _service.getProfile();
    final knownIds = TitleDefinitions.all.map((t) => t.id).toSet();
    final sanitizedActive =
        profile.activeTitleIds.where(knownIds.contains).toList(growable: false);
    final sanitizedUnlocked =
        profile.unlockedTitleIds.where(knownIds.contains).toList(growable: false);

    if (sanitizedActive.length == profile.activeTitleIds.length &&
        sanitizedUnlocked.length == profile.unlockedTitleIds.length) {
      return profile;
    }
    return profile.copyWith(
      activeTitleIds: sanitizedActive,
      unlockedTitleIds: sanitizedUnlocked,
    );
  }

  // ── Formula: requiredXP = baseXP * level^1.5 ────────────────────────────

  /// XP required to advance FROM [level] to [level]+1.
  int requiredXPForLevel(int level) =>
      (_baseXP * pow(level, 1.5)).floor();

  // ── Public action hooks ──────────────────────────────────────────────────

  /// Atomically increments the task counter and awards 10 XP.
  ///
  /// Safe to call from any Notifier (no external provider dependencies).
  /// Rank/title checks run automatically inside [addXP].
  Future<void> recordTaskCompleted() async {
    var profile = state.copyWith(
      totalTasksCompleted: state.totalTasksCompleted + 1,
    );
    await _service.saveProfile(profile);
    state = profile;
    await addXP(XpRewards.taskComplete);
  }

  /// Syncs the current streak into [PlayerProfile.longestStreak] and
  /// checks streak-based XP milestones.
  ///
  /// Call this from a widget that has access to [weeklyStatsProvider]
  /// (e.g. [XpLevelWidget]) whenever the streak value changes.
  Future<void> syncStreak(int currentStreak) async {
    var profile = state;
    if (currentStreak > profile.longestStreak) {
      profile = profile.copyWith(longestStreak: currentStreak);
      await _service.saveProfile(profile);
      state = profile;
    }
    await _checkStreakMilestones(currentStreak);
  }

  /// Award 30 XP when all tasks in a domain are completed today.
  Future<void> onDomainCompleted() async {
    await addXP(XpRewards.domainComplete);
  }

  /// Award 75 XP for completing the weekly campaign (score = 100%).
  Future<void> onWeeklyGoalCompleted() async {
    var profile = state;
    profile =
        profile.copyWith(weeklyGoalsCompleted: profile.weeklyGoalsCompleted + 1);
    await _service.saveProfile(profile);
    state = profile;
    await addXP(XpRewards.weeklyGoal);
  }

  /// Adds [amount] XP, then runs the full check pipeline:
  /// level-up → rank promotion → title unlocks.
  Future<void> addXP(int amount) async {
    var profile = state;
    profile = profile.copyWith(
      currentXP: profile.currentXP + amount,
      totalXP: profile.totalXP + amount,
    );

    // Level-up loop (handles multi-level skips in one call)
    bool didLevelUp = false;
    int latestLevel = profile.level;
    while (profile.currentXP >= requiredXPForLevel(profile.level)) {
      final surplus = profile.currentXP - requiredXPForLevel(profile.level);
      final newLevel = profile.level + 1;
      profile = profile.copyWith(level: newLevel, currentXP: surplus);
      didLevelUp = true;
      latestLevel = newLevel;
    }

    if (didLevelUp) {
      final lvl = latestLevel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(animationServiceProvider.notifier).onLevelUp(lvl);
      });
    }

    // Rank promotion check
    final promoted = _withRankPromotion(profile);
    if (promoted.rank != profile.rank) {
      profile = promoted;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(animationServiceProvider.notifier).onDomainUnlocked();
      });
    } else {
      profile = promoted;
    }

    // Title unlock check
    profile = _withTitleUnlocks(profile);

    // XP milestone → stat point awards
    profile = _withStatPointMilestones(profile);

    await _service.saveProfile(profile);
    state = profile;
  }

  /// Persists a new stat map and updates unspent points.
  ///
  /// This is the only write path for stat allocation UI.
  Future<void> updateStats({
    required Map<String, int> stats,
    required int unspentStatPoints,
  }) async {
    final normalizedStats = <String, int>{
      ...PlayerProfile.defaultStats,
      ...stats,
    };

    // Clamp values to prevent invalid persistence.
    normalizedStats.updateAll((_, v) {
      if (v < 0) return 0;
      if (v > _maxStatValue) return _maxStatValue;
      return v;
    });

    final profile = state.copyWith(
      stats: normalizedStats,
      unspentStatPoints: unspentStatPoints < 0 ? 0 : unspentStatPoints,
    );
    await _service.saveProfile(profile);
    state = profile;
  }

  /// Permanently records a real-life achievement in the Hall of Feats.
  Future<void> grantFeat({
    required String name,
    required String description,
  }) async {
    final feat =
        Feat(name: name, description: description, timestamp: DateTime.now());
    var profile = state.copyWith(feats: [...state.feats, feat]);
    profile = _withTitleUnlocks(profile);
    await _service.saveProfile(profile);
    state = profile;
  }

  /// Equip a title for display (must be unlocked first).
  Future<void> equipTitle(String id) async {
    if (!state.unlockedTitleIds.contains(id)) return;
    if (state.activeTitleIds.contains(id)) return;
    final profile =
        state.copyWith(activeTitleIds: [...state.activeTitleIds, id]);
    await _service.saveProfile(profile);
    state = profile;
  }

  /// Remove a title from active display.
  Future<void> unequipTitle(String id) async {
    final profile = state.copyWith(
      activeTitleIds: state.activeTitleIds.where((t) => t != id).toList(),
    );
    await _service.saveProfile(profile);
    state = profile;
  }

  /// Updates the editable hunter name shown on the profile screen.
  Future<void> updateName(String name) async {
    final profile = state.copyWith(name: name.trim());
    await _service.saveProfile(profile);
    state = profile;
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  Future<void> _checkStreakMilestones(int streak) async {
    const milestones = [7, 14, 21, 30];
    for (final m in milestones) {
      if (streak >= m && state.lastStreakMilestoneAwarded < m) {
        int xp = 0;
        if (m == 7) xp = XpRewards.streak7;
        if (m == 14) xp = XpRewards.streak14;
        if (m == 21) xp = XpRewards.streak21;
        if (m == 30) xp = XpRewards.streak30;

        // Mark milestone before awarding to prevent re-entry
        final updated = state.copyWith(lastStreakMilestoneAwarded: m);
        await _service.saveProfile(updated);
        state = updated;

        await addXP(xp);

        // Fire streak animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(animationServiceProvider.notifier).onStreakMilestone();
        });
      }
    }
  }

  /// Returns a new [PlayerProfile] with rank promoted if conditions are met.
  /// Never demotes rank.
  PlayerProfile _withRankPromotion(PlayerProfile profile) {
    String newRank = profile.rank;

    // E → D: 50 tasks completed
    if (_rankIndex(newRank) < _rankIndex('D') &&
        profile.totalTasksCompleted >= 50) {
      newRank = 'D';
    }
    // D → C: 14-day streak
    if (_rankIndex(newRank) < _rankIndex('C') &&
        profile.longestStreak >= 14) {
      newRank = 'C';
    }
    // C → B: 3 weekly campaigns
    if (_rankIndex(newRank) < _rankIndex('B') &&
        profile.weeklyGoalsCompleted >= 3) {
      newRank = 'B';
    }
    // B → A: Level 20
    if (_rankIndex(newRank) < _rankIndex('A') && profile.level >= 20) {
      newRank = 'A';
    }
    // A → S: 30-day streak
    if (_rankIndex(newRank) < _rankIndex('S') &&
        profile.longestStreak >= 30) {
      newRank = 'S';
    }
    // National and Monarch require manual feat grants — not auto-promoted here

    return profile.copyWith(rank: newRank);
  }

  /// Returns a new [PlayerProfile] with any newly earned titles added.
  PlayerProfile _withTitleUnlocks(PlayerProfile profile) {
    final unlocked = List<String>.from(profile.unlockedTitleIds);
    final context = TitleUnlockContext(
      profile: profile,
      weeklyStats: ref.read(weeklyStatsProvider),
      domainState: ref.read(domainProvider),
      taskState: ref.read(taskProvider),
    );
    for (final title in TitleDefinitions.all) {
      if (!unlocked.contains(title.id) && title.checkCondition(context)) {
        unlocked.add(title.id);
      }
    }
    if (unlocked.length == profile.unlockedTitleIds.length) return profile;
    return profile.copyWith(unlockedTitleIds: unlocked);
  }

  PlayerProfile _withStatPointMilestones(PlayerProfile profile) {
    if (_xpPerStatPoint <= 0) return profile;
    final earned = profile.totalXP ~/ _xpPerStatPoint;
    final delta = earned - profile.statPointsAwarded;
    if (delta <= 0) return profile;
    return profile.copyWith(
      statPointsAwarded: earned,
      unspentStatPoints: profile.unspentStatPoints + delta,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

final progressionProvider =
    NotifierProvider<ProgressionNotifier, PlayerProfile>(
  ProgressionNotifier.new,
);

/// Convenience computed provider: XP % toward next level (0.0 → 1.0).
final xpProgressProvider = Provider<double>((ref) {
  final profile = ref.watch(progressionProvider);
  final notifier = ref.read(progressionProvider.notifier);
  final required = notifier.requiredXPForLevel(profile.level);
  if (required <= 0) return 0.0;
  return (profile.currentXP / required).clamp(0.0, 1.0);
});

/// Convenience computed provider: XP needed for next level.
final xpRequiredProvider = Provider<int>((ref) {
  final profile = ref.watch(progressionProvider);
  return ref.read(progressionProvider.notifier).requiredXPForLevel(profile.level);
});
