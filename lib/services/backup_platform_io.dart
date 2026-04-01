import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [jsonContent] as a user-visible file and returns the saved path/URI.
///
/// On Android this is written to public storage (e.g. Downloads) via
/// platform APIs (scoped storage compliant). On desktop/iOS this uses the
/// platform save mechanism provided by `file_saver`.
Future<String> saveBackupFile(String jsonContent, String fileName) async {
  // In `flutter test`, plugin channels are often not registered.
  // Fall back to app documents so tests can run deterministically.
  if (const bool.fromEnvironment('FLUTTER_TEST')) {
    return _saveBackupFileToAppDocuments(jsonContent, fileName);
  }

  final baseName = _stripTrailingJsonExtensions(fileName);
  final bytes = Uint8List.fromList(utf8.encode(jsonContent));

  final savedTo = await FileSaver.instance.saveFile(
    name: baseName,
    bytes: bytes,
    fileExtension: 'json',
    mimeType: MimeType.custom,
    customMimeType: 'application/json',
  );

  final normalized = savedTo.trim();
  if (normalized.isEmpty || normalized.toLowerCase().contains('something went wrong')) {
    throw Exception('Unable to save backup file to user storage.');
  }

  if (Platform.isAndroid) {
    // `file_saver` may return a content:// URI. The file is still stored in the
    // public Downloads collection, so return a consistent, user-visible path.
    if (normalized.startsWith('content://') || !normalized.contains('/')) {
      return '/storage/emulated/0/Download/$baseName.json';
    }
  }

  return normalized;
}

Future<void> openBackupLocation(String savedTo) async {
  final v = savedTo.trim();
  if (v.isEmpty) return;

  // On Android, exports should land in the public Downloads collection.
  // Most file explorers can open this directory directly.
  if (Platform.isAndroid) {
    await OpenFilex.open('/storage/emulated/0/Download');
    return;
  }

  // Prefer revealing the parent folder when we have a real file path.
  if (v.startsWith('/')) {
    try {
      final dir = File(v).parent.path;
      await OpenFilex.open(dir);
      return;
    } catch (_) {
      // Fall through to opening the original target.
    }
  }

  await OpenFilex.open(v);
}

String _stripTrailingJsonExtensions(String fileName) {
  final trimmed = fileName.trim();
  // Remove one or more trailing ".json" segments to prevent ".json.json".
  return trimmed.replaceAll(RegExp(r'(\\.json)+\\z', caseSensitive: false), '');
}

Future<String> _saveBackupFileToAppDocuments(String jsonContent, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(jsonContent);
  return file.path;
}

/// Reads the file content selected by [result] as a UTF-8 string.
Future<String> readPickedBackupFile(FilePickerResult result) async {
  final file = File(result.files.single.path!);
  return file.readAsString();
}

/// Returns base64-encoded file bytes for [path], or `null` if it doesn't exist.
Future<String?> tryReadFileAsBase64(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  } catch (_) {
    return null;
  }
}

/// Writes Fuel Vault image bytes into app documents directory under /fuel_vault
/// and returns the absolute file path.
Future<String> writeFuelVaultImageFromBase64(
  String base64Data,
  String fileName,
) async {
  final dir = await getApplicationDocumentsDirectory();
  final vaultDir = Directory('${dir.path}/fuel_vault');
  if (!vaultDir.existsSync()) {
    vaultDir.createSync(recursive: true);
  }

  final file = File('${vaultDir.path}/$fileName');
  final bytes = base64Decode(base64Data);
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
