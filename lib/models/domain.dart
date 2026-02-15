import 'package:hive/hive.dart';

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
  
  Domain({
    required this.id,
    required this.name,
    this.strength = 0,
    this.isActive = true,
  });
  
  /// Create a copy of this domain with modified fields
  Domain copyWith({
    String? id,
    String? name,
    int? strength,
    bool? isActive,
  }) {
    return Domain(
      id: id ?? this.id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      isActive: isActive ?? this.isActive,
    );
  }
  
  /// Convert domain to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'strength': strength,
      'isActive': isActive,
    };
  }
  
  /// Create domain from JSON
  factory Domain.fromJson(Map<String, dynamic> json) {
    return Domain(
      id: json['id'] as String,
      name: json['name'] as String,
      strength: json['strength'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
