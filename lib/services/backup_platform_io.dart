import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
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

  final baseName = fileName.replaceFirst(RegExp(r'\.json\$', caseSensitive: false), '');
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
  return normalized;
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
