import 'package:hive/hive.dart';

import '../core/utils/domain_stat_weights.dart';

part 'domain.g.dart';

/// Domain model represents a life domain/area (e.g., Health, Work, Learning)
/// Each domain has a strength level and can be active or inactive
@HiveType(typeId: 0)
class Domain extends HiveObject {
  @HiveField(0)
  late String id;
  
  @HiveField(1)
  late String name;
  
  @HiveField(2)
  late int strength;
  
  @HiveField(3)
  late bool isActive;

  // NEW: stat contribution weights (max 3 stats; sum = 1.0)
  @HiveField(4)
  late Map<String, double> statWeights;
  
  Domain({
    required this.id,
    required this.name,
    this.strength = 0,
    this.isActive = true,
    Map<String, double>? statWeights,
  }) : statWeights = normalizeStatWeights(
          statWeights ?? inferStatWeights(name),
        );
  
  /// Create a copy of this domain with modified fields
  Domain copyWith({
    String? id,
    String? name,
    int? strength,
    bool? isActive,
    Map<String, double>? statWeights,
  }) {
    final nextName = name ?? this.name;
    return Domain(
      id: id ?? this.id,
      name: nextName,
      strength: strength ?? this.strength,
      isActive: isActive ?? this.isActive,
      statWeights: statWeights ?? this.statWeights,
    );
  }
  
  /// Convert domain to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strength': strength,
      'isActive': isActive,
      'statWeights': statWeights,
    };
  }
  
  /// Create domain from JSON
  factory Domain.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    return Domain(
      id: json['id'] as String,
      name: name,
      strength: json['strength'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      statWeights: (json['statWeights'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
    );
  }
}
