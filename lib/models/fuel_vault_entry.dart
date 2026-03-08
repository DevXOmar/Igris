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
