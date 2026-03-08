import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';

/// Triggers a JSON file download in the browser and returns the file name.
Future<String> saveBackupFile(String jsonContent, String fileName) async {
  final bytes = utf8.encode(jsonContent);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}

/// Reads the file content from the in-memory bytes provided by file_picker on web.
Future<String> readPickedBackupFile(FilePickerResult result) async {
  final bytes = result.files.single.bytes;
  if (bytes == null) throw Exception('No file data received from picker.');
  return utf8.decode(bytes);
}
