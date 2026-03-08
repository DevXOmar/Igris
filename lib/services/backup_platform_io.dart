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
