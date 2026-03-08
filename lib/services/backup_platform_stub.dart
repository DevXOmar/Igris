import 'package:file_picker/file_picker.dart';

Future<String> saveBackupFile(String jsonContent, String fileName) async {
  throw UnsupportedError('Backup is not supported on this platform.');
}

Future<String> readPickedBackupFile(FilePickerResult result) async {
  throw UnsupportedError('Restore is not supported on this platform.');
}
