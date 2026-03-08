import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_system.dart';
import '../../models/fuel_vault_entry.dart';
import '../../providers/fuel_vault_provider.dart';

class AddFuelBottomSheet extends ConsumerStatefulWidget {
  const AddFuelBottomSheet({super.key});

  @override
  ConsumerState<AddFuelBottomSheet> createState() => _AddFuelBottomSheetState();
}

class _AddFuelBottomSheetState extends ConsumerState<AddFuelBottomSheet> {
  String? _imagePath;
  Uint8List? _webPreviewBytes; // used on web for live preview
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _isSaving = false;

  static const _uuid = Uuid();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  /// Formats natively rendered by Flutter's Image.file().
  static const _supportedExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'wbmp',
  };

  /// HEIC/HEIF are converted to JPEG by image_picker internally on iOS,
  /// so we store them as .jpg so Flutter can render them.
  static const _heicExtensions = {'heic', 'heif'};

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // imageQuality: 85 triggers HEIC→JPEG conversion on iOS via image_picker.
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;

    if (kIsWeb) {
      // HEIC/HEIF cannot be decoded by any browser (except Safari).
      // Detect early and show a friendly error instead of a codec crash.
      final rawExtWeb = xFile.name.split('.').last.toLowerCase();
      if (_heicExtensions.contains(rawExtWeb)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'HEIC/HEIF is not supported in browsers. '
                'Please convert the photo to JPG or PNG first.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // On web image_picker returns a blob URL. Read bytes for reliable preview
      // and store the blob URL as the path (Image.network can resolve blob URLs).
      final bytes = await xFile.readAsBytes();
      setState(() {
        _imagePath = xFile.path;
        _webPreviewBytes = bytes;
      });
      return;
    }

    // Copy image to app documents directory for persistence.
    final docsDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${docsDir.path}/fuel_vault');
    if (!vaultDir.existsSync()) {
      vaultDir.createSync(recursive: true);
    }

    // Normalize extension: HEIC/HEIF → jpg (already JPEG bytes from image_picker).
    final rawExt = xFile.path.split('.').last.toLowerCase();
    final ext = _heicExtensions.contains(rawExt)
        ? 'jpg'
        : (_supportedExtensions.contains(rawExt) ? rawExt : 'jpg');

    final destPath = '${vaultDir.path}/${_uuid.v4()}.$ext';
    await File(xFile.path).copy(destPath);

    setState(() => _imagePath = destPath);
  }

  Future<void> _save() async {
    if (_imagePath == null) return;
    setState(() => _isSaving = true);

    final entry = FuelVaultEntry(
      id: _uuid.v4(),
      imagePath: _imagePath!,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    await ref.read(fuelVaultProvider.notifier).addEntry(entry);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _imagePath != null && !_isSaving;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      'Add Fuel',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppColors.dividerColor),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image picker area
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundElevated,
                            borderRadius: DesignSystem.radiusStandard,
                            border: Border.all(
                              color: _imagePath != null
                                  ? AppColors.neonBlue.withOpacity(0.5)
                                  : AppColors.dividerColor,
                              width: 1.5,
                            ),
                          ),
                          child: _imagePath != null
                              ? ClipRRect(
                                  borderRadius: DesignSystem.radiusStandard,
                                  child: _buildPreviewImage(),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.neonBlue.withOpacity(0.7),
                                      size: 40,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Tap to select image',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title (optional)
                      _buildField(
                        controller: _titleCtrl,
                        label: 'Title (optional)',
                        hint: 'e.g. Power',
                      ),

                      const SizedBox(height: 12),

                      // Note (optional)
                      _buildField(
                        controller: _noteCtrl,
                        label: 'Note (optional)',
                        hint: 'A reminder or thought...',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 12),

                      // Category (optional)
                      _buildField(
                        controller: _categoryCtrl,
                        label: 'Category (optional)',
                        hint: 'e.g. Mind, Power, Revenge',
                      ),

                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: canSave ? _save : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSave
                                ? AppColors.neonBlue.withOpacity(0.15)
                                : AppColors.backgroundElevated,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: BorderSide(
                              color: canSave ? AppColors.neonBlue : AppColors.dividerColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: DesignSystem.radiusStandard,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonBlue,
                                  ),
                                )
                              : const Text(
                                  'Add to Vault',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage() {
    if (kIsWeb && _webPreviewBytes != null) {
      return Image.memory(
        _webPreviewBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    if (!kIsWeb && _imagePath != null) {
      return Image.file(
        File(_imagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
    return const Icon(Icons.image, color: AppColors.textSecondary, size: 48);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundElevated,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: const BorderSide(color: AppColors.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: const BorderSide(color: AppColors.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DesignSystem.radiusStandard,
              borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
