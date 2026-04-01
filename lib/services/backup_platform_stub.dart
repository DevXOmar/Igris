import 'package:file_picker/file_picker.dart';

Future<String> saveBackupFile(String jsonContent, String fileName) async {
  throw UnsupportedError('Backup is not supported on this platform.');
}

Future<void> openBackupLocation(String savedTo) async {
  throw UnsupportedError('Open backup location is not supported on this platform.');
}

Future<String> readPickedBackupFile(FilePickerResult result) async {
  throw UnsupportedError('Restore is not supported on this platform.');
}

/// Returns base64-encoded file bytes for [path], or `null` if unsupported.
Future<String?> tryReadFileAsBase64(String path) async {
  return null;
}

/// Writes bytes to a restored image location and returns a path/URL.
Future<String> writeFuelVaultImageFromBase64(
  String base64Data,
  String fileName,
) async {
  throw UnsupportedError('Fuel Vault image restore is not supported on this platform.');
}
