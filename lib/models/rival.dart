import 'package:hive/hive.dart';

part 'rival.g.dart';

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

  Rival({
    required this.id,
    required this.name,
    required this.domain,
    required this.description,
    required this.lastAchievement,
    required this.lastUpdated,
    this.threatLevel,
    this.imagePath,
  });

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
    bool clearThreatLevel = false,
    bool clearImagePath = false,
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
    );
  }
}
