import 'package:hive/hive.dart';

part 'rival.g.dart';

enum RivalCategory { proximal, apex, mythic }

extension RivalCategoryX on RivalCategory {
  String get key {
    return switch (this) {
      RivalCategory.proximal => 'proximal',
      RivalCategory.apex => 'apex',
      RivalCategory.mythic => 'mythic',
    };
  }

  String get label {
    return switch (this) {
      RivalCategory.proximal => 'PROXIMAL',
      RivalCategory.apex => 'APEX',
      RivalCategory.mythic => 'MYTHIC',
    };
  }

  static RivalCategory? fromKey(String? key) {
    switch (key) {
      // Backwards compatibility: older backups may store "personal".
      case 'personal':
      case 'proximal':
        return RivalCategory.proximal;
      case 'apex':
        return RivalCategory.apex;
      case 'mythic':
        return RivalCategory.mythic;
      default:
        return null;
    }
  }

  static RivalCategory deriveFromThreat(int? threatLevel) {
    final t = threatLevel ?? 0;
    if (t >= 5) return RivalCategory.mythic;
    if (t >= 4) return RivalCategory.apex;
    return RivalCategory.proximal;
  }
}

/// Rival model — a peer, competitor, or aspirational figure the user tracks.
///
/// Everything is entered manually and stored locally via Hive.
@HiveType(typeId: 4)
class Rival extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  /// Domain this rival is tracked in (e.g. "AI", "Fitness", "Career").
  @HiveField(2)
  late String domain;

  /// Why this rival matters — private notes visible only in the detail view.
  @HiveField(3)
  late String description;

  @HiveField(4)
  late String lastAchievement;

  @HiveField(5)
  late DateTime lastUpdated;

  /// Optional 1–5 intensity indicator (null if not set).
  @HiveField(6)
  int? threatLevel;

  /// Optional local image path.
  @HiveField(7)
  String? imagePath;

  /// Optional explicit category (proximal/Apex/Mythic) stored as a string key.
  /// If null, UI can fall back to a derived category.
  @HiveField(8)
  String? categoryKey;

  Rival({
    required this.id,
    required this.name,
    required this.domain,
    required this.description,
    required this.lastAchievement,
    required this.lastUpdated,
    this.threatLevel,
    this.imagePath,
    this.categoryKey,
  });

  RivalCategory get category {
    return RivalCategoryX.fromKey(categoryKey) ??
        RivalCategoryX.deriveFromThreat(threatLevel);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'domain': domain,
      'description': description,
      'lastAchievement': lastAchievement,
      'lastUpdated': lastUpdated.toIso8601String(),
      'threatLevel': threatLevel,
      'imagePath': imagePath,
      'categoryKey': categoryKey,
    };
  }

  factory Rival.fromJson(Map<String, dynamic> json) {
    return Rival(
      id: json['id'] as String,
      name: json['name'] as String,
      domain: json['domain'] as String,
      description: json['description'] as String,
      lastAchievement: json['lastAchievement'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      threatLevel: json['threatLevel'] as int?,
      imagePath: json['imagePath'] as String?,
      categoryKey: json['categoryKey'] as String?,
    );
  }

  Rival copyWith({
    String? id,
    String? name,
    String? domain,
    String? description,
    String? lastAchievement,
    DateTime? lastUpdated,
    int? threatLevel,
    String? imagePath,
    RivalCategory? category,
    bool clearThreatLevel = false,
    bool clearImagePath = false,
    bool clearCategory = false,
  }) {
    return Rival(
      id: id ?? this.id,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      description: description ?? this.description,
      lastAchievement: lastAchievement ?? this.lastAchievement,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      threatLevel: clearThreatLevel ? null : (threatLevel ?? this.threatLevel),
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      categoryKey: clearCategory
          ? null
          : (category != null ? category.key : categoryKey),
    );
  }
}
