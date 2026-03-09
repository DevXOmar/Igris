import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feat.dart';
import '../models/player_profile.dart';
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
  final bool Function(PlayerProfile profile) checkCondition;

  const TitleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockCondition,
    required this.icon,
    required this.checkCondition,
  });
}

// ignore: avoid_classes_with_only_static_members
class TitleDefinitions {
  static final List<TitleDefinition> all = [
    TitleDefinition(
      id: 'wolf_assassin',
      name: 'Wolf Assassin',
      description: 'Swift, precise, relentless in execution.',
      unlockCondition: 'Complete 100 tasks',
      icon: Icons.flash_on,
      checkCondition: (p) => p.totalTasksCompleted >= 100,
    ),
    TitleDefinition(
      id: 'relentless',
      name: 'Relentless',
      description: 'Consistency is your weapon.',
      unlockCondition: '7-day streak',
      icon: Icons.local_fire_department,
      checkCondition: (p) => p.longestStreak >= 7,
    ),
    TitleDefinition(
      id: 'architect',
      name: 'Architect',
      description: 'Builds mastery across multiple domains.',
      unlockCondition: 'Reach level 10',
      icon: Icons.account_tree,
      checkCondition: (p) => p.level >= 10,
    ),
    TitleDefinition(
      id: 'scholar',
      name: 'Scholar',
      description: 'Knowledge through persistent discipline.',
      unlockCondition: 'Complete 500 tasks',
      icon: Icons.menu_book,
      checkCondition: (p) => p.totalTasksCompleted >= 500,
    ),
    TitleDefinition(
      id: 'iron_discipline',
      name: 'Iron Discipline',
      description: 'Thirty days of unbreakable will.',
      unlockCondition: '30-day streak',
      icon: Icons.shield,
      checkCondition: (p) => p.longestStreak >= 30,
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

  final ProgressionService _service = ProgressionService();

  @override
  PlayerProfile build() => _service.getProfile();

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
    profile = profile.copyWith(currentXP: profile.currentXP + amount);

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
    final profile =
        state.copyWith(feats: [...state.feats, feat]);
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
    for (final title in TitleDefinitions.all) {
      if (!unlocked.contains(title.id) && title.checkCondition(profile)) {
        unlocked.add(title.id);
      }
    }
    if (unlocked.length == profile.unlockedTitleIds.length) return profile;
    return profile.copyWith(unlockedTitleIds: unlocked);
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
