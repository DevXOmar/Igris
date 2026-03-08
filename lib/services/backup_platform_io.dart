import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Saves [jsonContent] to the app documents directory and returns the file path.
Future<String> saveBackupFile(String jsonContent, String fileName) async {
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
