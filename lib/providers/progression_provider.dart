import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/progression/stat_calculator.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import '../models/feat.dart';
import '../models/domain.dart';
import '../models/player_profile.dart';
import '../models/task.dart';
import '../providers/domain_provider.dart';
import '../providers/task_provider.dart';
import '../providers/weekly_stats_provider.dart';
import '../services/daily_log_service.dart';
import '../services/progression_service.dart';
import '../services/animation_service.dart';
import '../services/settings_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TITLE DEFINITIONS
// Static catalogue of every title a hunter can earn.
// Unlock logic lives here (pure function of PlayerProfile).
// ─────────────────────────────────────────────────────────────────────────────

enum TitleEffectType {
  /// Additive XP bonus applied to all XP awards.
  xpBonus,

  /// Additive XP bonus applied only to streak milestone XP awards.
  streakXpBonus,

  /// Additive bonus to stat points earned from XP milestones.
  statPointBonus,

  /// Additive bonus to an individual stat (effective display power).
  statBonus,

  /// Additive bonus to all stats (effective display power).
  allStatsBonus,

  /// Additive XP bonus applied to task completion XP (category-aware).
  taskXpBonus,

  /// Additive XP bonus applied only to weekly goal completion XP.
  weeklyGoalXpBonus,

  /// Informational effect (no numeric gameplay change in code).
  note,
}

enum TaskXpCategory {
  taskComplete,
  study,
  work,
  fitness,
  oneTime,
  dominantDomain,
}

class TitleEffect {
  final TitleEffectType type;
  final double percent;
  final String? statKey;
  final TaskXpCategory? taskXpCategory;
  final String? note;

  const TitleEffect._(
    this.type,
    this.percent, {
    this.statKey,
    this.taskXpCategory,
    this.note,
  });

  const TitleEffect.xpBonus(double percent)
      : this._(TitleEffectType.xpBonus, percent);

  const TitleEffect.streakXpBonus(double percent)
      : this._(TitleEffectType.streakXpBonus, percent);

  const TitleEffect.statPointBonus(double percent)
      : this._(TitleEffectType.statPointBonus, percent);

  const TitleEffect.statBonus({
    required String statKey,
    required double percent,
  }) : this._(
          TitleEffectType.statBonus,
          percent,
          statKey: statKey,
        );

  const TitleEffect.allStatsBonus(double percent)
      : this._(TitleEffectType.allStatsBonus, percent);

  const TitleEffect.taskXpBonus({
    required TaskXpCategory category,
    required double percent,
  }) : this._(
          TitleEffectType.taskXpBonus,
          percent,
          taskXpCategory: category,
        );

  const TitleEffect.weeklyGoalXpBonus(double percent)
      : this._(TitleEffectType.weeklyGoalXpBonus, percent);

  const TitleEffect.note(String text)
      : this._(TitleEffectType.note, 0.0, note: text);

  String format() {
    String pct(double v) => '${(v * 100).round()}%';
    if (type == TitleEffectType.xpBonus) {
      return '+${pct(percent)} XP';
    }
    if (type == TitleEffectType.streakXpBonus) {
      return '+${pct(percent)} streak XP';
    }
    if (type == TitleEffectType.statPointBonus) {
      return '+${pct(percent)} stat growth';
    }
    if (type == TitleEffectType.allStatsBonus) {
      return '+${pct(percent)} all stats';
    }
    if (type == TitleEffectType.statBonus) {
      final label = (statKey ?? 'stat').toUpperCase();
      return '+${pct(percent)} $label';
    }
    if (type == TitleEffectType.taskXpBonus) {
      final c = taskXpCategory;
      final label = switch (c) {
        TaskXpCategory.taskComplete => 'task XP',
        TaskXpCategory.study => 'study task XP',
        TaskXpCategory.work => 'work task XP',
        TaskXpCategory.fitness => 'fitness task XP',
        TaskXpCategory.oneTime => 'one-time task XP',
        TaskXpCategory.dominantDomain => 'dominant domain XP',
        _ => 'task XP',
      };
      return '+${pct(percent)} $label';
    }
    if (type == TitleEffectType.weeklyGoalXpBonus) {
      return '+${pct(percent)} weekly goal XP';
    }
    if (type == TitleEffectType.note) {
      return note ?? '';
    }
    return '';
  }
}

class AggregatedTitleEffects {
  final double xpBonusPercent;
  final double streakXpBonusPercent;
  final double statPointBonusPercent;

  const AggregatedTitleEffects({
    required this.xpBonusPercent,
    required this.streakXpBonusPercent,
    required this.statPointBonusPercent,
  });

  static const none = AggregatedTitleEffects(
    xpBonusPercent: 0.0,
    streakXpBonusPercent: 0.0,
    statPointBonusPercent: 0.0,
  );
}

class TitleDefinition {
  final String id;
  final String name;
  final String description;

  /// Human-readable unlock hint shown in the UI.
  final String unlockCondition;

  final IconData icon;

  /// Gameplay modifiers granted when the title is equipped.
  final List<TitleEffect> effects;

  /// Returns true when [profile] satisfies the unlock requirement.
  final bool Function(TitleUnlockContext context) checkCondition;

  const TitleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockCondition,
    required this.icon,
    this.effects = const [],
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
    // Any completion across *eligible* active-domain tasks qualifies.
    final eligibleTasks = taskState.tasks.where((task) {
      final domain = domainState.getDomainById(task.domainId);
      if (domain == null || !domain.isActive) return false;
      return isTaskActiveOnDate(task, date);
    }).toList(growable: false);

    if (eligibleTasks.isEmpty) {
      // No tasks that day — don't break the streak.
      return true;
    }

    final completedCount =
      eligibleTasks.where((task) => log.isTaskCompleted(task.id)).length;
    return completedCount >= 1;
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
      effects: const [
        TitleEffect.xpBonus(0.05),
      ],
      checkCondition: (c) => c.profile.totalTasksCompleted >= 10,
    ),
    TitleDefinition(
      id: 'awakened_star',
      name: 'Awakened ★',
      description: 'Your power has begun to surface.',
      unlockCondition: 'Reach Level 5',
      icon: Icons.auto_awesome,
      effects: const [
        TitleEffect.statPointBonus(0.05),
      ],
      checkCondition: (c) => c.profile.level >= 5,
    ),
    TitleDefinition(
      id: 'daily_survivor',
      name: 'Daily Survivor',
      description: 'You kept moving, day after day.',
      unlockCondition: '7-day streak',
      icon: Icons.shield_outlined,
      effects: const [
        TitleEffect.streakXpBonus(0.10),
      ],
      checkCondition: (c) => c.profile.longestStreak >= 7,
    ),
    TitleDefinition(
      id: 'relentless_star',
      name: 'Relentless ★',
      description: 'Consistency is your weapon.',
      unlockCondition: '30-day streak',
      icon: Icons.local_fire_department,
      effects: const [
        TitleEffect.streakXpBonus(0.15),
      ],
      checkCondition: (c) => c.profile.longestStreak >= 30,
    ),
    TitleDefinition(
      id: 'unbreakable',
      name: 'Unbreakable',
      description: 'A streak that refuses to end.',
      unlockCondition: '90-day streak',
      icon: Icons.verified_user_outlined,
      effects: const [
        TitleEffect.note('Unlocked for reaching a 90-day streak.'),
      ],
      checkCondition: (c) => c.profile.longestStreak >= 90,
    ),
    TitleDefinition(
      id: 'unyielding_rythm',
      name: 'The Unyielding Rythm',
      description:
          'Controlled grace. Unbroken execution. Three weeks straight.',
      unlockCondition:
          'Use at most 1 grace per week and maintain streak for 3 weeks',
      icon: Icons.multiline_chart,
      effects: const [
        TitleEffect.statBonus(statKey: 'discipline', percent: 0.20),
        TitleEffect.streakXpBonus(0.10),
        TitleEffect.xpBonus(0.05),
        TitleEffect.note(
            'Grace preserves your streak; XP from completed tasks still counts.'),
      ],
      checkCondition: (c) => c.hasUnyieldingRythmForThreeWeeks,
    ),
    TitleDefinition(
      id: 'iron_will',
      name: 'Iron Will',
      description: 'A mind that refuses to fracture.',
      unlockCondition: '50 tasks without breaking streak',
      icon: Icons.military_tech_outlined,
      effects: const [
        TitleEffect.statBonus(statKey: 'discipline', percent: 0.10),
      ],
      checkCondition: (c) => c.completedTaskInstancesInCurrentStreak >= 50,
    ),
    TitleDefinition(
      id: 'wolf_assassin_star',
      name: 'Wolf Assassin ★',
      description: 'Swift, precise, relentless in execution.',
      unlockCondition: '100 total tasks',
      icon: Icons.flash_on,
      effects: const [
        TitleEffect.taskXpBonus(
            category: TaskXpCategory.taskComplete, percent: 0.15),
        TitleEffect.xpBonus(0.05),
      ],
      checkCondition: (c) => c.profile.totalTasksCompleted >= 100,
    ),
    TitleDefinition(
      id: 'architect_star',
      name: 'Architect ★',
      description: 'Builds mastery across multiple domains.',
      unlockCondition: 'Reach Level 10',
      icon: Icons.account_tree,
      effects: const [
        // Strategy maps to Intelligence in this build.
        TitleEffect.statBonus(statKey: 'intelligence', percent: 0.10),
        TitleEffect.statBonus(statKey: 'intelligence', percent: 0.05),
      ],
      checkCondition: (c) => c.profile.level >= 10,
    ),
    TitleDefinition(
      id: 'scholar',
      name: 'Scholar',
      description: 'Knowledge through persistent discipline.',
      unlockCondition: '200 study-related tasks',
      icon: Icons.menu_book,
      effects: const [
        TitleEffect.statBonus(statKey: 'intelligence', percent: 0.15),
        TitleEffect.taskXpBonus(category: TaskXpCategory.study, percent: 0.10),
      ],
      checkCondition: (c) =>
          c.sumDomainStrengthWhere((n) => _studyRe.hasMatch(n)) >= 200,
    ),
    TitleDefinition(
      id: 'forge_master',
      name: 'Forge Master',
      description: 'Turns effort into output, again and again.',
      unlockCondition: '150 work/productivity tasks',
      icon: Icons.build_outlined,
      effects: const [
        // Execution maps to Discipline in this build.
        TitleEffect.statBonus(statKey: 'discipline', percent: 0.15),
        TitleEffect.taskXpBonus(category: TaskXpCategory.work, percent: 0.10),
      ],
      checkCondition: (c) =>
          c.sumDomainStrengthWhere((n) => _workRe.hasMatch(n)) >= 150,
    ),
    TitleDefinition(
      id: 'titan_of_fitness',
      name: 'Titan of Fitness',
      description: 'A body forged in repetition.',
      unlockCondition: '100 fitness tasks',
      icon: Icons.fitness_center,
      effects: const [
        // Vitality maps to Endurance in this build.
        TitleEffect.statBonus(statKey: 'endurance', percent: 0.15),
        TitleEffect.taskXpBonus(
            category: TaskXpCategory.fitness, percent: 0.10),
      ],
      checkCondition: (c) =>
          c.sumDomainStrengthWhere((n) => _fitnessRe.hasMatch(n)) >= 100,
    ),
    TitleDefinition(
      id: 'shadow_walker',
      name: 'Shadow Walker',
      description: 'Moves through every domain without faltering.',
      unlockCondition: 'Consistent activity across ALL domains',
      icon: Icons.blur_on,
      effects: const [
        TitleEffect.allStatsBonus(0.05),
      ],
      checkCondition: (c) => c.hasActivityAcrossAllActiveDomainsThisWeek,
    ),
    TitleDefinition(
      id: 'domain_conqueror',
      name: 'Domain Conqueror',
      description: 'One domain stands fully conquered.',
      unlockCondition: 'Max out one domain',
      icon: Icons.flag_outlined,
      effects: const [
        TitleEffect.taskXpBonus(
            category: TaskXpCategory.dominantDomain, percent: 0.20),
      ],
      checkCondition: (c) =>
          c.anyDomainStrengthAtLeast(_domainConquerorStrengthThreshold),
    ),
    TitleDefinition(
      id: 's_rank_candidate_star',
      name: 'S-Rank Candidate ★',
      description: 'Your presence alone shifts the room.',
      unlockCondition: 'Level 30',
      icon: Icons.stars_rounded,
      effects: const [
        TitleEffect.xpBonus(0.10),
        TitleEffect.statBonus(statKey: 'presence', percent: 0.10),
      ],
      checkCondition: (c) => c.profile.level >= 30,
    ),
    TitleDefinition(
      id: 'double_dungeon_survivor',
      name: 'Double Dungeon Survivor',
      description: 'You endured the week’s crushing weight.',
      unlockCondition: '50 tasks in one week',
      icon: Icons.calendar_month_outlined,
      effects: const [
        TitleEffect.weeklyGoalXpBonus(0.25),
      ],
      checkCondition: (c) => c.weeklyStats.completedTasksThisWeek >= 50,
    ),
    TitleDefinition(
      id: 'igris_blade_star',
      name: 'Igris’ Blade ★',
      description: 'Loyalty sharpened into an edge.',
      unlockCondition: '100-day streak',
      icon: Icons.gavel,
      effects: const [
        TitleEffect.statBonus(statKey: 'discipline', percent: 0.20),
        // Execution maps to Discipline in this build.
        TitleEffect.statBonus(statKey: 'discipline', percent: 0.10),
      ],
      checkCondition: (c) => c.profile.longestStreak >= 100,
    ),
    TitleDefinition(
      id: 'rulers_authority',
      name: 'Ruler’s Authority',
      description: 'Balance maintained. Order enforced.',
      unlockCondition: 'Maintain balanced weekly progress across domains',
      icon: Icons.balance,
      effects: const [
        TitleEffect.note('+10% all stats if weekly balance is met.'),
      ],
      checkCondition: (c) => c.hasBalancedWeeklyProgressAcrossDomains,
    ),
    TitleDefinition(
      id: 'shadow_summoner_star',
      name: 'Shadow Summoner ★',
      description: 'A legion formed from relentless completion.',
      unlockCondition: '1000 total tasks',
      icon: Icons.groups_2_outlined,
      effects: const [
        TitleEffect.xpBonus(0.15),
      ],
      checkCondition: (c) => c.profile.totalTasksCompleted >= 1000,
    ),
    TitleDefinition(
      id: 'national_level_hunter',
      name: 'National Level Hunter',
      description: 'A name known far beyond the gates.',
      unlockCondition: 'Level 100 OR major real-world milestone',
      icon: Icons.public,
      effects: const [
        TitleEffect.statBonus(statKey: 'presence', percent: 0.20),
        TitleEffect.xpBonus(0.10),
      ],
      checkCondition: (c) =>
          c.profile.level >= 100 || c.profile.feats.isNotEmpty,
    ),
    TitleDefinition(
      id: 'kamish_slayer_reworked',
      name: 'Kamish Slayer (REWORKED)',
      description: 'You cleared what others abandoned.',
      unlockCondition: 'Clear 100+ backlog/overdue tasks',
      icon: Icons.task_alt,
      effects: const [
        TitleEffect.taskXpBonus(
            category: TaskXpCategory.oneTime, percent: 0.20),
      ],
      checkCondition: (c) => c.distinctOneTimeTasksCompleted >= 100,
    ),
    TitleDefinition(
      id: 'shadow_monarch_star',
      name: 'Shadow Monarch ★',
      description: 'A year of discipline — and beyond.',
      unlockCondition: '365-day streak + extreme consistency',
      icon: Icons.workspace_premium,
      effects: const [
        TitleEffect.allStatsBonus(0.15),
        TitleEffect.xpBonus(0.15),
        TitleEffect.streakXpBonus(0.10),
      ],
      checkCondition: (c) =>
          c.profile.longestStreak >= 365 &&
          c.profile.weeklyGoalsCompleted >= 12,
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

  static const int taskComplete = 15;
  static const int firstTaskOfDayBonus = 20;
  static const int domainComplete = 25;
  static const int weeklyGoal = 100;
  static const int weeklyPerfectBonus = 50;
  static const int streak7 = 50;
  static const int streak14 = 100;
  static const int streak21 = 150;
  static const int streak30 = 200;
  static const int streak45 = 300;
  static const int streak60 = 400;
}

int getAllocationPointsForLevel(int level) {
  if (level <= 5) return 4;
  if (level <= 15) return 3;
  return 2;
}

double getEarlyGameXpMultiplier(int level) {
  if (level <= 5) return 1.8;
  if (level <= 10) return 1.3;
  return 1.0;
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
  static const int _maxStatValue = PlayerProfile.defaultMaxStatValue;

  static const double _maxAdditiveXpBonus = 0.50;

  final ProgressionService _service = ProgressionService();
  final DailyLogService _dailyLogService = DailyLogService();
  final SettingsService _settingsService = SettingsService();

  @override
  PlayerProfile build() {
    final profile = _service.getProfile();
    final knownIds = TitleDefinitions.all.map((t) => t.id).toSet();
    final legacyActive =
        profile.activeTitleIds.where(knownIds.contains).toList(growable: false);
    final equippedSource = profile.equippedTitleIds.isNotEmpty
        ? profile.equippedTitleIds
        : legacyActive;
    final sanitizedEquipped = _sanitizeEquippedTitleIds(
      equippedSource,
      knownIds: knownIds,
    );
    final sanitizedUnlocked = profile.unlockedTitleIds
        .where(knownIds.contains)
        .toList(growable: false);

    var next = profile;

    // ── Migration: legacy single milestone int -> achieved set ────────────
    if (next.achievedStreakMilestones.isEmpty &&
        next.lastStreakMilestoneAwarded > 0) {
      const legacy = [7, 14, 21, 30];
      final migrated = legacy
          .where((m) => m <= next.lastStreakMilestoneAwarded)
          .toList(growable: false);
      next = next.copyWith(achievedStreakMilestones: migrated);
      Future(() async {
        await _service.saveProfile(next);
      });
    }

    // ── Migration: legacy final stats -> allocation-only model ───────────
    final hasAnyAllocations = next.statAllocations.values.any((v) => v != 0);
    final legacyLooksNonDefault = next.stats.entries.any((e) {
      final base = PlayerProfile.defaultStats[e.key];
      return base != null && e.value != base;
    });

    if (!hasAnyAllocations && legacyLooksNonDefault) {
      final migratedAllocations = <String, int>{
        for (final k in PlayerProfile.defaultStatAllocations.keys)
          k: max(
            0,
            (next.stats[k] ?? PlayerProfile.defaultStatValue) -
                PlayerProfile.defaultStatValue,
          ),
      };
      next = next.copyWith(
        stats: PlayerProfile.defaultStats,
        statAllocations: migratedAllocations,
      );
      Future(() async {
        await _service.saveProfile(next);
      });
    }

    if (sanitizedEquipped.length != next.equippedTitleIds.length ||
        sanitizedEquipped.length != next.activeTitleIds.length ||
        sanitizedUnlocked.length != next.unlockedTitleIds.length) {
      next = next.copyWith(
        equippedTitleIds: sanitizedEquipped,
        activeTitleIds: sanitizedEquipped,
        unlockedTitleIds: sanitizedUnlocked,
      );
    }

    return next;
  }

  List<String> _sanitizeEquippedTitleIds(
    List<String> ids, {
    required Set<String> knownIds,
  }) {
    if (ids.isEmpty) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final id in ids) {
      if (!knownIds.contains(id)) continue;
      if (seen.contains(id)) continue;
      seen.add(id);
      out.add(id);
      if (out.length >= 2) break;
    }
    return out.toList(growable: false);
  }

  AggregatedTitleEffects _aggregateEquippedTitleEffects(PlayerProfile profile) {
    final ids = profile.equippedTitleIds;
    if (ids.isEmpty) return AggregatedTitleEffects.none;

    double xp = 0.0;
    double streakXp = 0.0;
    double statPoints = 0.0;

    for (final id in ids) {
      final def = TitleDefinitions.findById(id);
      if (def == null) continue;
      for (final e in def.effects) {
        if (e.type == TitleEffectType.xpBonus) xp += e.percent;
        if (e.type == TitleEffectType.streakXpBonus) streakXp += e.percent;
        if (e.type == TitleEffectType.statPointBonus) statPoints += e.percent;
      }
    }

    double cap(double v) => v.clamp(0.0, _maxAdditiveXpBonus);

    return AggregatedTitleEffects(
      xpBonusPercent: cap(xp),
      streakXpBonusPercent: cap(streakXp),
      statPointBonusPercent: cap(statPoints),
    );
  }

  int _applyXpEffects({
    required int base,
    required bool isStreak,
  }) {
    if (base <= 0) return base;
    final effects = _aggregateEquippedTitleEffects(state);
    final bonus = effects.xpBonusPercent +
        (isStreak ? effects.streakXpBonusPercent : 0.0);
    final awarded = (base * (1.0 + bonus)).round();
    return awarded <= 0 ? 1 : awarded;
  }

  double _weeklyGoalBonusPercent(PlayerProfile profile) {
    double bonus = 0.0;
    for (final id in profile.equippedTitleIds) {
      final def = TitleDefinitions.findById(id);
      if (def == null) continue;
      for (final e in def.effects) {
        if (e.type == TitleEffectType.weeklyGoalXpBonus) bonus += e.percent;
      }
    }
    return max(0.0, bonus);
  }

  int _applyWeeklyGoalXpEffects(int base) {
    if (base <= 0) return base;
    final bonus = _weeklyGoalBonusPercent(state);
    return (base * (1.0 + bonus)).round();
  }

  bool _isDominantDomain(String domainId) {
    final domains = ref.read(domainProvider).domains;
    final active = domains.where((d) => d.isActive).toList(growable: false);
    if (active.isEmpty) return false;
    final maxStrength = active.map((d) => d.strength).reduce(max);
    if (maxStrength <= 0) return false;
    return active.any((d) => d.id == domainId && d.strength == maxStrength);
  }

  ({bool isStudy, bool isWork, bool isFitness}) _domainTagsFor(
      String domainName) {
    final n = domainName.trim().toLowerCase();
    return (
      isStudy: TitleDefinitions._studyRe.hasMatch(n),
      isWork: TitleDefinitions._workRe.hasMatch(n),
      isFitness: TitleDefinitions._fitnessRe.hasMatch(n),
    );
  }

  double _taskBonusPercent({
    required PlayerProfile profile,
    required Task task,
    required Domain? domain,
  }) {
    double bonus = 0.0;
    final isOneTime = task.isRecurring == false;
    final isDominant = domain != null && _isDominantDomain(domain.id);
    final tags = domain != null
        ? _domainTagsFor(domain.name)
        : (isStudy: false, isWork: false, isFitness: false);

    for (final id in profile.equippedTitleIds) {
      final def = TitleDefinitions.findById(id);
      if (def == null) continue;
      for (final e in def.effects) {
        if (e.type != TitleEffectType.taskXpBonus) continue;
        final c = e.taskXpCategory;
        if (c == TaskXpCategory.taskComplete) bonus += e.percent;
        if (c == TaskXpCategory.oneTime && isOneTime) bonus += e.percent;
        if (c == TaskXpCategory.dominantDomain && isDominant)
          bonus += e.percent;
        if (c == TaskXpCategory.study && tags.isStudy) bonus += e.percent;
        if (c == TaskXpCategory.work && tags.isWork) bonus += e.percent;
        if (c == TaskXpCategory.fitness && tags.isFitness) bonus += e.percent;
      }
    }
    return max(0.0, bonus);
  }

  // ── Formula: requiredXP = baseXP * level^1.5 ────────────────────────────

  /// XP required to advance FROM [level] to [level]+1.
  int requiredXPForLevel(int level) => (_baseXP * pow(level, 1.5)).floor();

  // ── Public action hooks ──────────────────────────────────────────────────

  /// Atomically increments the task counter and awards XP.
  ///
  /// Safe to call from any Notifier (no external provider dependencies).
  /// Rank/title checks run automatically inside [addXP].
  Future<void> recordTaskCompleted({
    required String taskId,
    required String domainId,
  }) async {
    final today = app_date_utils.DateUtils.today;

    final domain = ref.read(domainProvider).getDomainById(domainId);

    // Stats must never change from task completion.
    var profile = state.copyWith(
      totalTasksCompleted: state.totalTasksCompleted + 1,
    );
    await _service.saveProfile(profile);
    state = profile;

    final taskState = ref.read(taskProvider);
    Task? task;
    try {
      task = taskState.tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      task = null;
    }
    final base = XpRewards.taskComplete;
    final bonus = task == null
        ? 0.0
        : _taskBonusPercent(profile: state, task: task, domain: domain);
    final adjustedBase = (base * (1.0 + bonus)).round();

    // Daily engagement: first completed task of the day grants a flat XP bonus
    // once per day.
    final isFirstTaskOfDay =
      await _dailyLogService.markFirstTaskOfDayBonusAwarded(today);
    final finalBase =
      adjustedBase + (isFirstTaskOfDay ? XpRewards.firstTaskOfDayBonus : 0);

    await addXP(finalBase);
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
    final today = app_date_utils.DateUtils.today;
    final weekStart = app_date_utils.DateUtils.getStartOfWeek(today);
    final lastWeek = _settingsService.getLastWeeklyGoalRewardWeekStart();
    if (lastWeek != null) {
      final lastWeekStart = app_date_utils.DateUtils.getStartOfWeek(DateTime(
        lastWeek.year,
        lastWeek.month,
        lastWeek.day,
      ));
      if (!weekStart.isAfter(lastWeekStart)) {
        // Already rewarded for this week.
        return;
      }
    }

    await _settingsService.setLastWeeklyGoalRewardWeekStart(weekStart);

    var profile = state;
    profile = profile.copyWith(
        weeklyGoalsCompleted: profile.weeklyGoalsCompleted + 1);
    await _service.saveProfile(profile);
    state = profile;

    // Weekly completion: base reward + perfect week bonus.
    await addXP(_applyWeeklyGoalXpEffects(XpRewards.weeklyGoal));
    await addXP(_applyWeeklyGoalXpEffects(XpRewards.weeklyPerfectBonus));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(animationServiceProvider.notifier).onWeeklyCompletion();
    });
  }

  /// Adds [baseAmount] XP (after applying equipped title effects),
  /// then runs the full check pipeline:
  /// level-up → rank promotion → title unlocks.
  Future<void> addXP(int baseAmount, {bool isStreakAward = false}) async {
    // Early-game pacing: multiply the base XP once based on the current level.
    final earlyMult = getEarlyGameXpMultiplier(state.level);
    final scaledBase = (baseAmount * earlyMult).round();
    final amount =
        _applyXpEffects(base: scaledBase, isStreak: isStreakAward);
    var profile = state;
    profile = profile.copyWith(
      currentXP: profile.currentXP + amount,
      totalXP: profile.totalXP + amount,
    );

    // Level-up loop (handles multi-level skips in one call)
    bool didLevelUp = false;
    int latestLevel = profile.level;
    int allocationPointsEarned = 0;
    while (profile.currentXP >= requiredXPForLevel(profile.level)) {
      final surplus = profile.currentXP - requiredXPForLevel(profile.level);
      final newLevel = profile.level + 1;
      allocationPointsEarned += getAllocationPointsForLevel(newLevel);
      profile = profile.copyWith(level: newLevel, currentXP: surplus);
      didLevelUp = true;
      latestLevel = newLevel;
    }

    if (allocationPointsEarned > 0) {
      final effects = _aggregateEquippedTitleEffects(profile);
      final adjusted = max(
        allocationPointsEarned,
        (allocationPointsEarned * (1.0 + effects.statPointBonusPercent))
            .floor(),
      );
      profile = profile.copyWith(
        unspentStatPoints: profile.unspentStatPoints + adjusted,
      );
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

    await _service.saveProfile(profile);
    state = profile;
  }

  /// Persists a new allocation map and updates unspent points.
  ///
  /// Backward-compatible name: [stats] now represents ALLOCATIONS (spent
  /// points), not final derived stats.
  ///
  /// This is the only write path for the stat allocation UI.
  Future<void> updateStats({
    required Map<String, int> stats,
    required int unspentStatPoints,
  }) async {
    final normalizedAllocations = <String, int>{
      ...PlayerProfile.defaultStatAllocations,
      ...stats,
    };

    final maxAllocation = _maxStatValue - PlayerProfile.defaultStatValue;
    normalizedAllocations.updateAll((_, v) {
      if (v < 0) return 0;
      if (v > maxAllocation) return maxAllocation;
      return v;
    });

    // Harden: compute unspent from the current total earned, ignoring any
    // mismatched UI-provided value.
    final currentSpent =
        state.statAllocations.values.fold<int>(0, (a, b) => a + b);
    final totalEarned = state.unspentStatPoints + currentSpent;
    final newSpent = normalizedAllocations.values.fold<int>(0, (a, b) => a + b);
    final computedUnspent = max(0, totalEarned - newSpent);

    final profile = state.copyWith(
      statAllocations: normalizedAllocations,
      unspentStatPoints: computedUnspent,
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
    if (state.equippedTitleIds.contains(id)) return;
    if (state.equippedTitleIds.length >= 2) return;
    final equipped = [...state.equippedTitleIds, id];
    final profile = state.copyWith(
      equippedTitleIds: equipped,
      activeTitleIds: equipped,
    );
    await _service.saveProfile(profile);
    state = profile;
  }

  /// Remove a title from active display.
  Future<void> unequipTitle(String id) async {
    final equipped =
        state.equippedTitleIds.where((t) => t != id).toList(growable: false);
    final profile = state.copyWith(
      equippedTitleIds: equipped,
      activeTitleIds: equipped,
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
    final milestoneXp = <int, int>{
      7: XpRewards.streak7,
      14: XpRewards.streak14,
      21: XpRewards.streak21,
      30: XpRewards.streak30,
      45: XpRewards.streak45,
      60: XpRewards.streak60,
    };

    const titleMilestone = 90;
    const titleId = 'unbreakable';

    final achieved = state.achievedStreakMilestones.toSet();

    final orderedMilestones = milestoneXp.keys.toList()..sort();
    for (final m in orderedMilestones) {
      if (streak < m) continue;
      if (achieved.contains(m)) continue;

      achieved.add(m);
      final achievedList = achieved.toList()..sort();
      final updated = state.copyWith(
        achievedStreakMilestones: achievedList.toList(growable: false),
        lastStreakMilestoneAwarded: m > state.lastStreakMilestoneAwarded
            ? m
            : state.lastStreakMilestoneAwarded,
      );
      await _service.saveProfile(updated);
      state = updated;

      await addXP(milestoneXp[m]!, isStreakAward: true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(animationServiceProvider.notifier).onStreakMilestone();
      });
    }

    // 90-day milestone: unlock a title (no XP).
    if (streak >= titleMilestone && !achieved.contains(titleMilestone)) {
      achieved.add(titleMilestone);
      final achievedList = achieved.toList()..sort();
      final unlocked = state.unlockedTitleIds.contains(titleId)
          ? state.unlockedTitleIds
          : [...state.unlockedTitleIds, titleId];

      final updated = state.copyWith(
        achievedStreakMilestones: achievedList.toList(growable: false),
        lastStreakMilestoneAwarded:
            titleMilestone > state.lastStreakMilestoneAwarded
                ? titleMilestone
                : state.lastStreakMilestoneAwarded,
        unlockedTitleIds: unlocked,
      );
      await _service.saveProfile(updated);
      state = updated;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(animationServiceProvider.notifier).onStreakMilestone();
      });
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
    if (_rankIndex(newRank) < _rankIndex('C') && profile.longestStreak >= 14) {
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
    if (_rankIndex(newRank) < _rankIndex('S') && profile.longestStreak >= 30) {
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
}

final equippedTitleEffectsProvider = Provider<AggregatedTitleEffects>((ref) {
  final profile = ref.watch(progressionProvider);
  return ref
      .read(progressionProvider.notifier)
      ._aggregateEquippedTitleEffects(profile);
});

bool _isWeeklyBalanceMet({
  required WeeklyStats weeklyStats,
  required DomainState domainState,
}) {
  final active = domainState.activeDomains;
  if (active.length < 2) return false;
  final values = <double>[];
  for (final domain in active) {
    final p = weeklyStats.weeklyProgress[domain] ?? 0.0;
    if (p <= 0.0) return false;
    values.add(p);
  }
  if (values.length < 2) return false;
  final minP = values.reduce(min);
  final maxP = values.reduce(max);
  return minP >= 0.40 && (maxP - minP) <= 0.25;
}

final effectiveStatsProvider = Provider<Map<String, int>>((ref) {
  final profile = ref.watch(progressionProvider);
  final weeklyStats = ref.watch(weeklyStatsProvider);
  final domains = ref.watch(domainProvider);

  final allocations = <String, int>{
    ...PlayerProfile.defaultStatAllocations,
    ...profile.statAllocations,
  };

  final bonusByKey = <String, double>{
    for (final k in PlayerProfile.defaultStats.keys) k: 0.0,
  };

  final weeklyBalanced = _isWeeklyBalanceMet(
    weeklyStats: weeklyStats,
    domainState: domains,
  );

  for (final id in profile.equippedTitleIds) {
    // Ruler’s Authority is conditional, so handle explicitly.
    if (id == 'rulers_authority' && weeklyBalanced) {
      for (final k in bonusByKey.keys) {
        bonusByKey[k] = (bonusByKey[k] ?? 0.0) + 0.10;
      }
      continue;
    }

    final def = TitleDefinitions.findById(id);
    if (def == null) continue;
    for (final e in def.effects) {
      if (e.type == TitleEffectType.allStatsBonus) {
        for (final k in bonusByKey.keys) {
          bonusByKey[k] = (bonusByKey[k] ?? 0.0) + e.percent;
        }
      }
      if (e.type == TitleEffectType.statBonus && e.statKey != null) {
        final key = e.statKey!;
        if (bonusByKey.containsKey(key)) {
          bonusByKey[key] = (bonusByKey[key] ?? 0.0) + e.percent;
        }
      }
    }
  }

  return calculateStats(
    allocations: allocations,
    allocationBonusByKey: bonusByKey,
  );
});

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
  return ref
      .read(progressionProvider.notifier)
      .requiredXPForLevel(profile.level);
});
