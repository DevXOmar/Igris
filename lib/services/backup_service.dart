import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

import 'backup_platform.dart';
import 'platform_info.dart';

import '../models/daily_log.dart';
import '../models/domain.dart';
import '../models/fuel_vault_entry.dart';
import '../models/rival.dart';
import '../models/task.dart';

/// Current schema version.  Increment this when the backup JSON structure
/// changes and add a matching migration branch inside [runMigration].
const int schemaVersion = 1;

/// Backup metadata `appVersion`.
///
/// Note: this is intentionally decoupled from pubspec `version` to avoid
/// adding runtime dependencies (e.g. package_info_plus) just for backups.
const String backupAppVersion = '0.1.0';

/// Handles exporting and importing a full Igris data backup as JSON.
///
/// All heavy I/O is awaited but never blocks the UI thread — callers should
/// `await` these methods from an async handler (e.g. a button callback).
class BackupService {
  // ── Box names ──────────────────────────────────────────────────────────────
  static const _domainsBox = 'domainsBox';
  static const _tasksBox = 'tasksBox';
  static const _dailyLogsBox = 'dailyLogsBox';
  static const _rivalsBox = 'rivalsBox';
  static const _fuelVaultBox = 'fuelVaultBox';

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Reads every Hive box, serialises the data, and writes a JSON file to the
  /// application documents directory.
  ///
  /// Returns the absolute path of the written file.
  Future<String> exportBackup() async {
    final domains =
        Hive.box<Domain>(_domainsBox).values.map((d) => d.toJson()).toList();

    final tasks =
        Hive.box<Task>(_tasksBox).values.map((t) => t.toJson()).toList();

    final dailyLogs =
        Hive.box<DailyLog>(_dailyLogsBox).values.map((l) => l.toJson()).toList();

    final rivals =
        Hive.box<Rival>(_rivalsBox).values.map((r) => r.toJson()).toList();

    final fuelVault = Hive.box<FuelVaultEntry>(_fuelVaultBox)
        .values
        .map((e) => e.toJson())
        .toList();

    final payload = <String, dynamic>{
      'version': schemaVersion,
      'appVersion': backupAppVersion,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device': getBackupDevice(),
      'data': <String, dynamic>{
        'domains': domains,
        'tasks': tasks,
        'dailyLogs': dailyLogs,
        'rivals': rivals,
        'fuelVault': fuelVault,
      },
    };

    final now = DateTime.now();
    final dateTag =
        '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
    final fileName = 'igris_backup_$dateTag.json';

    return saveBackupFile(jsonEncode(payload), fileName);
  }

  // ── Restore ────────────────────────────────────────────────────────────────

  /// Opens the system file picker, validates the selected file, migrates if
  /// needed, clears all Hive boxes, then writes the restored data.
  ///
  /// Throws a [BackupException] with a human-readable message on any failure
  /// so the UI can display it without inspecting raw exception types.
  Future<void> restoreBackup() async {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true, // ensures bytes are available on web
    );
    if (result == null) {
      // User cancelled — treat as no-op
      return;
    }

    final raw = await readPickedBackupFile(result);

    // 2. Validate
    Map<String, dynamic> data;
    try {
      data = validateBackup(raw);
    } catch (e) {
      throw BackupException('Invalid backup file: $e');
    }

    // 3. Migrate if needed
    final backupVersion = data['version'] as int;
    if (backupVersion < schemaVersion) {
      data = runMigration(data, backupVersion);
    }

    final restored = data['data'] as Map<String, dynamic>;

    // 4. Clear all boxes
    await Hive.box<Domain>(_domainsBox).clear();
    await Hive.box<Task>(_tasksBox).clear();
    await Hive.box<DailyLog>(_dailyLogsBox).clear();
    await Hive.box<Rival>(_rivalsBox).clear();
    await Hive.box<FuelVaultEntry>(_fuelVaultBox).clear();

    // 5. Restore
    final domainsBox = Hive.box<Domain>(_domainsBox);
    for (final json in restored['domains'] as List<dynamic>) {
      final d = Domain.fromJson(json as Map<String, dynamic>);
      await domainsBox.put(d.id, d);
    }

    final tasksBox = Hive.box<Task>(_tasksBox);
    for (final json in restored['tasks'] as List<dynamic>) {
      final t = Task.fromJson(json as Map<String, dynamic>);
      await tasksBox.put(t.id, t);
    }

    final dailyLogsBox = Hive.box<DailyLog>(_dailyLogsBox);
    for (final json in restored['dailyLogs'] as List<dynamic>) {
      final l = DailyLog.fromJson(json as Map<String, dynamic>);
      await dailyLogsBox.put(l.date.toIso8601String(), l);
    }

    final rivalsBox = Hive.box<Rival>(_rivalsBox);
    for (final json in restored['rivals'] as List<dynamic>) {
      final r = Rival.fromJson(json as Map<String, dynamic>);
      await rivalsBox.put(r.id, r);
    }

    final fuelVaultBox = Hive.box<FuelVaultEntry>(_fuelVaultBox);
    for (final json in restored['fuelVault'] as List<dynamic>) {
      final e = FuelVaultEntry.fromJson(json as Map<String, dynamic>);
      await fuelVaultBox.put(e.id, e);
    }
  }

  // ── Validate ───────────────────────────────────────────────────────────────

  /// Decodes [jsonContent] and verifies the required top-level keys exist.
  ///
  /// Returns the parsed map on success; throws [FormatException] on failure.
  Map<String, dynamic> validateBackup(String jsonContent) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } catch (_) {
      throw const FormatException('File is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Root of backup must be a JSON object.');
    }

    if (decoded['version'] is! int) {
      throw const FormatException('"version" must be an integer.');
    }

    // Normalize to the latest structure:
    // {
    //   version, appVersion?, timestamp, device?, data: { domains, tasks, ... }
    // }
    // Also supports the legacy v1 format where lists lived at root.
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(decoded);

    if (normalized['data'] is! Map<String, dynamic>) {
      normalized['data'] = <String, dynamic>{
        'domains': normalized['domains'] ?? const [],
        'tasks': normalized['tasks'] ?? const [],
        'dailyLogs': normalized['dailyLogs'] ?? const [],
        'rivals': normalized['rivals'] ?? const [],
        'fuelVault': normalized['fuelVault'] ?? const [],
      };
    }

    final data = normalized['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('"data" must be a JSON object.');
    }

    const requiredDataKeys = ['domains', 'tasks', 'dailyLogs', 'rivals', 'fuelVault'];
    for (final key in requiredDataKeys) {
      if (!data.containsKey(key)) {
        throw FormatException('Missing required key: "data.$key".');
      }
      if (data[key] is! List) {
        throw FormatException('"data.$key" must be a JSON array.');
      }
    }

    if (normalized['timestamp'] == null || normalized['timestamp'] is! String) {
      throw const FormatException('"timestamp" must be a string.');
    }

    // Optional metadata keys: appVersion, device.
    normalized['appVersion'] ??= backupAppVersion;
    normalized['device'] ??= 'unknown';

    return normalized;
  }

  // ── Migration ──────────────────────────────────────────────────────────────

  /// Applies incremental schema migrations from [fromVersion] to [schemaVersion].
  ///
  /// Add a new `case` block here whenever [schemaVersion] is incremented.
  Map<String, dynamic> runMigration(
    Map<String, dynamic> data,
    int fromVersion,
  ) {
    var current = fromVersion;

    while (current < schemaVersion) {
      switch (current) {
        // When migrating from v1 → v2, add the v2 transforms here.
        // case 1:
        //   data = _migrateV1toV2(data);
        default:
          // No migration defined for this step — skip.
          break;
      }
      current++;
    }

    data['version'] = schemaVersion;
    return data;
  }
}

/// Thrown by [BackupService] when an unrecoverable error occurs during restore.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
