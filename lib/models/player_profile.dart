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
  static const int defaultStatValue = 1;
  static const int defaultMaxStatValue = 99;

  static const Map<String, int> defaultStats = {
    'presence': defaultStatValue,
    'strength': defaultStatValue,
    'agility': defaultStatValue,
    'endurance': defaultStatValue,
    'intelligence': defaultStatValue,
    'discipline': defaultStatValue,
  };

  /// Allocation map (spent stat points) — stored separately from final stats.
  ///
  /// Final display stats are derived from:
  /// - base stats = [defaultStats]
  /// - allocations = [statAllocations]
  static const Map<String, int> defaultStatAllocations = {
    'presence': 0,
    'strength': 0,
    'agility': 0,
    'endurance': 0,
    'intelligence': 0,
    'discipline': 0,
  };

  /// Current hunter level (starts at 1).
  @HiveField(0)
  final int level;

  /// XP accumulated toward the NEXT level (resets on level-up).
  @HiveField(1)
  final int currentXP;

  /// Lifetime XP earned (never decreases).
  @HiveField(11)
  final int totalXP;

  /// Current rank string: 'E' | 'D' | 'C' | 'B' | 'A' | 'S' | 'National' | 'Monarch'.
  @HiveField(2)
  final String rank;

  /// IDs of titles currently equipped (shown in profile header).
  @HiveField(3)
  final List<String> activeTitleIds;

  /// IDs of titles currently equipped (gameplay effects + header display).
  ///
  /// This is the authoritative equip list going forward (max 2).
  /// [activeTitleIds] is kept for backward compatibility with older saves.
  @HiveField(15)
  final List<String> equippedTitleIds;

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

  /// Editable hunter name shown on the profile screen.
  @HiveField(10)
  final String name;

  /// Unspent stat points earned from XP milestones.
  @HiveField(12)
  final int unspentStatPoints;

  /// Total stat points already awarded from XP milestones.
  ///
  /// Stored to prevent double-awarding when loading older profiles.
  @HiveField(13)
  final int statPointsAwarded;

  /// Hunter stats. Keys are stable strings (e.g. 'presence').
  @HiveField(14)
  final Map<String, int> stats;

  /// Stat allocations (spent points). Keys are stable strings (e.g. 'presence').
  ///
  /// This is the new source of truth for the allocation UI.
  @HiveField(16)
  final Map<String, int> statAllocations;

  const PlayerProfile({
    this.level = 1,
    this.currentXP = 0,
    this.totalXP = 0,
    this.rank = 'E',
    this.activeTitleIds = const [],
    this.equippedTitleIds = const [],
    this.unlockedTitleIds = const [],
    this.feats = const [],
    this.totalTasksCompleted = 0,
    this.weeklyGoalsCompleted = 0,
    this.longestStreak = 0,
    this.lastStreakMilestoneAwarded = 0,
    this.name = '',
    this.unspentStatPoints = 0,
    this.statPointsAwarded = 0,
    this.stats = defaultStats,
    this.statAllocations = defaultStatAllocations,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'currentXP': currentXP,
        'totalXP': totalXP,
        'rank': rank,
        'activeTitleIds': activeTitleIds,
        'equippedTitleIds': equippedTitleIds,
        'unlockedTitleIds': unlockedTitleIds,
        'feats': feats.map((f) => f.toJson()).toList(),
        'totalTasksCompleted': totalTasksCompleted,
        'weeklyGoalsCompleted': weeklyGoalsCompleted,
        'longestStreak': longestStreak,
        'lastStreakMilestoneAwarded': lastStreakMilestoneAwarded,
        'name': name,
        'unspentStatPoints': unspentStatPoints,
        'statPointsAwarded': statPointsAwarded,
        'stats': stats,
        'statAllocations': statAllocations,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final featsJson = json['feats'];
    final feats = (featsJson is List)
        ? featsJson
            .whereType<Map>()
            .map((e) => Feat.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <Feat>[];

    final statsJson = json['stats'];
    final stats = (statsJson is Map)
        ? statsJson.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          )
        : Map<String, int>.from(PlayerProfile.defaultStats);

    final allocJson = json['statAllocations'];
    final allocations = (allocJson is Map)
        ? allocJson.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          )
        : Map<String, int>.from(PlayerProfile.defaultStatAllocations);

    return PlayerProfile(
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentXP: (json['currentXP'] as num?)?.toInt() ?? 0,
      totalXP: (json['totalXP'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as String?) ?? 'E',
      activeTitleIds:
          (json['activeTitleIds'] as List?)?.whereType<String>().toList() ??
              const <String>[],
      equippedTitleIds:
          (json['equippedTitleIds'] as List?)?.whereType<String>().toList() ??
              const <String>[],
      unlockedTitleIds:
          (json['unlockedTitleIds'] as List?)?.whereType<String>().toList() ??
              const <String>[],
      feats: feats,
      totalTasksCompleted: (json['totalTasksCompleted'] as num?)?.toInt() ?? 0,
      weeklyGoalsCompleted: (json['weeklyGoalsCompleted'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      lastStreakMilestoneAwarded:
          (json['lastStreakMilestoneAwarded'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      unspentStatPoints: (json['unspentStatPoints'] as num?)?.toInt() ?? 0,
      statPointsAwarded: (json['statPointsAwarded'] as num?)?.toInt() ?? 0,
      stats: {
        ...PlayerProfile.defaultStats,
        ...stats,
      },
      statAllocations: {
        ...PlayerProfile.defaultStatAllocations,
        ...allocations,
      },
    );
  }

  PlayerProfile copyWith({
    int? level,
    int? currentXP,
    int? totalXP,
    String? rank,
    List<String>? activeTitleIds,
    List<String>? equippedTitleIds,
    List<String>? unlockedTitleIds,
    List<Feat>? feats,
    int? totalTasksCompleted,
    int? weeklyGoalsCompleted,
    int? longestStreak,
    int? lastStreakMilestoneAwarded,
    String? name,
    int? unspentStatPoints,
    int? statPointsAwarded,
    Map<String, int>? stats,
    Map<String, int>? statAllocations,
  }) {
    return PlayerProfile(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      totalXP: totalXP ?? this.totalXP,
      rank: rank ?? this.rank,
      activeTitleIds: activeTitleIds ?? this.activeTitleIds,
      equippedTitleIds: equippedTitleIds ?? this.equippedTitleIds,
      unlockedTitleIds: unlockedTitleIds ?? this.unlockedTitleIds,
      feats: feats ?? this.feats,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      weeklyGoalsCompleted: weeklyGoalsCompleted ?? this.weeklyGoalsCompleted,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakMilestoneAwarded:
          lastStreakMilestoneAwarded ?? this.lastStreakMilestoneAwarded,
      name: name ?? this.name,
      unspentStatPoints: unspentStatPoints ?? this.unspentStatPoints,
      statPointsAwarded: statPointsAwarded ?? this.statPointsAwarded,
      stats: stats ?? this.stats,
      statAllocations: statAllocations ?? this.statAllocations,
    );
  }
}
