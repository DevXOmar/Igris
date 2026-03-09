import 'package:hive/hive.dart';
import 'feat.dart';

part 'player_profile.g.dart';

/// Core player progression model.
///
/// Stored as a single keyed entry in [playerProfileBox] ('profile').
/// All mutations go through [ProgressionNotifier] which creates a new
/// instance via [copyWith] so Riverpod detects state changes correctly.
@HiveType(typeId: 5)
class PlayerProfile {
  /// Current hunter level (starts at 1).
  @HiveField(0)
  final int level;

  /// XP accumulated toward the NEXT level (resets on level-up).
  @HiveField(1)
  final int currentXP;

  /// Current rank string: 'E' | 'D' | 'C' | 'B' | 'A' | 'S' | 'National' | 'Monarch'.
  @HiveField(2)
  final String rank;

  /// IDs of titles currently equipped (shown in profile header).
  @HiveField(3)
  final List<String> activeTitleIds;

  /// IDs of all titles that have been unlocked.
  @HiveField(4)
  final List<String> unlockedTitleIds;

  /// Permanent achievement records (Hall of Feats).
  @HiveField(5)
  final List<Feat> feats;

  /// Cumulative tasks completed — used for rank/title conditions.
  @HiveField(6)
  final int totalTasksCompleted;

  /// Number of weeks where the weekly campaign (100% score) was completed.
  @HiveField(7)
  final int weeklyGoalsCompleted;

  /// All-time longest streak in days — used for rank/title conditions.
  @HiveField(8)
  final int longestStreak;

  /// Highest streak milestone that already had XP awarded (0/7/14/21/30).
  @HiveField(9)
  final int lastStreakMilestoneAwarded;

  const PlayerProfile({
    this.level = 1,
    this.currentXP = 0,
    this.rank = 'E',
    this.activeTitleIds = const [],
    this.unlockedTitleIds = const [],
    this.feats = const [],
    this.totalTasksCompleted = 0,
    this.weeklyGoalsCompleted = 0,
    this.longestStreak = 0,
    this.lastStreakMilestoneAwarded = 0,
  });

  PlayerProfile copyWith({
    int? level,
    int? currentXP,
    String? rank,
    List<String>? activeTitleIds,
    List<String>? unlockedTitleIds,
    List<Feat>? feats,
    int? totalTasksCompleted,
    int? weeklyGoalsCompleted,
    int? longestStreak,
    int? lastStreakMilestoneAwarded,
  }) {
    return PlayerProfile(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      rank: rank ?? this.rank,
      activeTitleIds: activeTitleIds ?? this.activeTitleIds,
      unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
      feats: feats ?? this.feats,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      weeklyGoalsCompleted: weeklyGoalsCompleted ?? this.weeklyGoalsCompleted,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakMilestoneAwarded:
          lastStreakMilestoneAwarded ?? this.lastStreakMilestoneAwarded,
    );
  }
}
