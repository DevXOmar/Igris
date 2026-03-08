import 'package:hive/hive.dart';

part 'fuel_vault_entry.g.dart';

/// A single fuel image entry stored in the private Fuel Vault.
///
/// Images are stored as local file paths (not asset paths).
/// Use Image.file(File(imagePath)) to display.
@HiveType(typeId: 3)
class FuelVaultEntry extends HiveObject {
  @HiveField(0)
  late String id;

  /// Absolute path to the image file on the device.
  @HiveField(1)
  late String imagePath;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? note;

  @HiveField(4)
  String? category;

  @HiveField(5)
  late DateTime createdAt;

  FuelVaultEntry({
    required this.id,
    required this.imagePath,
    this.title,
    this.note,
    this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'title': title,
      'note': note,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FuelVaultEntry.fromJson(Map<String, dynamic> json) {
    return FuelVaultEntry(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      title: json['title'] as String?,
      note: json['note'] as String?,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  FuelVaultEntry copyWith({
    String? id,
    String? imagePath,
    String? title,
    String? note,
    String? category,
    DateTime? createdAt,
  }) {
    return FuelVaultEntry(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
