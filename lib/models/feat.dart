import 'package:hive/hive.dart';

part 'feat.g.dart';

/// A feat is a manually or automatically recorded major achievement.
/// Feats are permanent records displayed in the Hall of Feats.
@HiveType(typeId: 6)
class Feat {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final DateTime timestamp;

  const Feat({
    required this.name,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Feat.fromJson(Map<String, dynamic> json) => Feat(
        name: json['name'] as String,
        description: json['description'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
