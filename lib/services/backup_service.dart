import 'dart:convert';
import 'dart:developer' as developer;

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';

import 'backup_platform.dart';
import 'backup_migration_service.dart';
import 'platform_info.dart';

import '../models/daily_log.dart';
import '../models/domain.dart';
import '../models/fuel_vault_entry.dart';
import '../models/player_profile.dart';
import '../models/rival.dart';
import '../models/task.dart';
import '../core/utils/date_utils.dart' as app_date_utils;
import 'domain_progress_service.dart';

/// Current schema version.  Increment this when the backup JSON structure
/// changes and add a matching migration branch inside [runMigration].
const int schemaVersion = 2;

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
  static const _settingsBox = 'settingsBox';
  static const _playerProfileBox = 'playerProfileBox';
  static const _playerProfileKey = 'profile';

  final BackupMigrationService _migrationService = BackupMigrationService();

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'BackupService',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Reads every Hive box, serialises the data, and writes a JSON file using
  /// the platform's user-visible save mechanism (Downloads / file save dialog).
  ///
  /// Returns the saved path/URI (platform-dependent).
  Future<String> exportBackup() async {
    final domainObjects = Hive.box<Domain>(_domainsBox).values.toList();
    final taskObjects = Hive.box<Task>(_tasksBox).values.toList();
    final logObjects = Hive.box<DailyLog>(_dailyLogsBox).values.toList();
    final rivalObjects = Hive.box<Rival>(_rivalsBox).values.toList();

    final domains = domainObjects.map((d) => d.toJson()).toList();
    final tasks = taskObjects.map((t) => t.toJson()).toList();
    final dailyLogs = logObjects.map((l) => l.toJson()).toList();
    final rivals = rivalObjects.map((r) => r.toJson()).toList();

    final fuelVault = <Map<String, dynamic>>[];
    for (final entry in Hive.box<FuelVaultEntry>(_fuelVaultBox).values) {
      final json = entry.toJson();

      // Persist the actual file path (on mobile/desktop) in imagePath.
      // Additionally embed bytes so restore can recreate files on a new device.
      final ext = _extractFileExtension(entry.imagePath);
      final imageFileName = '${entry.id}.$ext';
      final imageBytesBase64 = await tryReadFileAsBase64(entry.imagePath);

      json['imageFileName'] = imageFileName;
      json['imageBytesBase64'] = imageBytesBase64;
      fuelVault.add(json);
    }

    final settingsBox = Hive.box(_settingsBox);
    final settings = <String, dynamic>{};
    for (final key in settingsBox.keys) {
      if (key is! String) continue;
      final value = settingsBox.get(key);
      final encoded = _encodeSettingValue(value);
      if (encoded == null && value != null) continue;
      settings[key] = encoded;
    }

    final profile =
        Hive.box<PlayerProfile>(_playerProfileBox).get(_playerProfileKey) ??
            const PlayerProfile();

    final weeklyStats = _buildWeeklyStatsSnapshot(
      domains: domainObjects,
      tasks: taskObjects,
      dailyLogs: logObjects,
    );

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'version': schemaVersion, // legacy alias
      'appVersion': backupAppVersion,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'device': getBackupDevice(),
      'settings': settings,
      'data': <String, dynamic>{
        'domains': domains,
        'tasks': tasks,
        'dailyLogs': dailyLogs,
        'rivals': rivals,
        'fuelVault': fuelVault,
        'playerProfile': profile.toJson(),
        'weeklyStats': weeklyStats,
      },
    };

    final now = DateTime.now();
    final dateTag =
        '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
    final fileName = 'igris_backup_$dateTag.json';

    return saveBackupFile(jsonEncode(payload), fileName);
  }

  Map<String, dynamic> _buildWeeklyStatsSnapshot({
    required List<Domain> domains,
    required List<Task> tasks,
    required List<DailyLog> dailyLogs,
  }) {
    final today = app_date_utils.DateUtils.today;
    final startOfWeek = app_date_utils.DateUtils.getStartOfWeek(today);

    // Build fast lookup: dateKey -> DailyLog
    final logsByKey = <String, DailyLog>{
      for (final l in dailyLogs)
        app_date_utils.DateUtils.getDateKey(l.date): l,
    };

    final activeDomainIds =
      domains.where((d) => d.isActive).map((d) => d.id).toSet();
    final activeTasks =
      tasks.where((t) => activeDomainIds.contains(t.domainId)).toList();

    final progressService = DomainProgressService(
      tasks: activeTasks,
      getLogForDate: (date) => logsByKey[app_date_utils.DateUtils.getDateKey(date)],
      now: today,
    );

    int totalTasksThisWeek = 0;
    int completedTasksThisWeek = 0;
    int graceUsedThisWeek = 0;

    for (var i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      if (date.isAfter(today)) continue;
      final key = app_date_utils.DateUtils.getDateKey(date);
      final log = logsByKey[key];
      if (log?.graceUsed == true) graceUsedThisWeek++;
    }

    // Per-domain snapshot: { domainId: progress0to1 }
    final progressByDomain = <String, double>{};
    for (final domain in domains.where((d) => d.isActive)) {
      final domainTasks =
          activeTasks.where((t) => t.domainId == domain.id).toList();
      if (domainTasks.isEmpty) {
        progressByDomain[domain.id] = 0.0;
        continue;
      }

      var domainExpectedSoFar = 0;
      var domainCompletedSoFar = 0;
      for (final task in domainTasks) {
        domainExpectedSoFar += progressService.getExpectedOccurrences(task, today);
        domainCompletedSoFar += progressService.getCompletedOccurrences(task, today);
      }

      totalTasksThisWeek += domainExpectedSoFar;
      completedTasksThisWeek += domainCompletedSoFar;

      progressByDomain[domain.id] = domainExpectedSoFar > 0
          ? (domainCompletedSoFar / domainExpectedSoFar).clamp(0.0, 1.0)
          : 0.0;
    }

    final weeklyScore = totalTasksThisWeek > 0
        ? (completedTasksThisWeek / totalTasksThisWeek) * 100
        : 0.0;

    final currentStreak = _calculateStreak(
      today: today,
      activeTasks: activeTasks,
      logsByKey: logsByKey,
    );

    return {
      'weeklyScore': weeklyScore,
      'currentStreak': currentStreak,
      'totalTasksThisWeek': totalTasksThisWeek,
      'completedTasksThisWeek': completedTasksThisWeek,
      'graceUsedThisWeek': graceUsedThisWeek,
      'progressByDomain': progressByDomain,
    };
  }

  int _calculateStreak({
    required DateTime today,
    required List<Task> activeTasks,
    required Map<String, DailyLog> logsByKey,
  }) {
    if (activeTasks.isEmpty) return 0;

    var streak = 0;
    var checkDate = today;

    const int maxLookbackDays = 3660;
    var lookedBack = 0;

    while (true) {
      if (lookedBack++ >= maxLookbackDays) break;
      final key = app_date_utils.DateUtils.getDateKey(checkDate);
      final log = logsByKey[key];

      if (log?.graceUsed == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      final completedCount = activeTasks
          .where((task) => log?.isTaskCompleted(task.id) ?? false)
          .length;

      final completionPercentage = (completedCount / activeTasks.length) * 100;
      if (completionPercentage >= 70.0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ── Preview ───────────────────────────────────────────────────────────────

  /// Picks a backup file and returns a parsed preview summary.
  ///
  /// Returns `null` if the user cancels the picker.
  Future<BackupPreview?> pickBackupPreview() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null) return null;
    final raw = await readPickedBackupFile(result);
    return previewBackup(raw);
  }

  /// Parses [jsonContent], migrates to latest schema, and returns a summary.
  BackupPreview previewBackup(String jsonContent) {
    final envelope = validateBackup(jsonContent);
    final data = Map<String, dynamic>.from(envelope['data'] as Map);

    final profileJson = data['playerProfile'];
    final profile = (profileJson is Map)
        ? PlayerProfile.fromJson(Map<String, dynamic>.from(profileJson))
        : const PlayerProfile();

    return BackupPreview(
      envelope: envelope,
      schemaVersion: envelope['schemaVersion'] as int,
      timestampUtc: envelope['timestamp'] as String,
      device: envelope['device'] as String,
      appVersion: envelope['appVersion'] as String,
      domainsCount: (data['domains'] as List).length,
      tasksCount: (data['tasks'] as List).length,
      dailyLogsCount: (data['dailyLogs'] as List).length,
      rivalsCount: (data['rivals'] as List).length,
      fuelVaultCount: (data['fuelVault'] as List).length,
      profileLevel: profile.level,
      profileRank: profile.rank,
      profileName: profile.name,
    );
  }

  // ── Restore ────────────────────────────────────────────────────────────────

  /// Opens the system file picker, validates the selected file, migrates if
  /// needed, clears all Hive boxes, then writes the restored data.
  ///
  /// Throws a [BackupException] with a human-readable message on any failure
  /// so the UI can display it without inspecting raw exception types.
  Future<void> restoreBackup() async {
    final preview = await pickBackupPreview();
    if (preview == null) return;
    await restoreFromEnvelope(preview.envelope);
  }

  /// Restores from a pre-validated, migrated envelope. This is the recommended
  /// entrypoint when the UI already showed a preview/confirmation.
  Future<void> restoreFromEnvelope(Map<String, dynamic> envelope) async {
    try {
      await _restoreAtomic(envelope);
    } catch (e, st) {
      _log('Restore failed', error: e, stackTrace: st);
      if (e is BackupException) rethrow;
      throw BackupException('Restore failed: $e');
    }
  }

  Future<void> _restoreAtomic(Map<String, dynamic> envelope) async {
    final restoredData = Map<String, dynamic>.from(envelope['data'] as Map);
    final settingsRaw = (envelope['settings'] is Map)
        ? Map<String, dynamic>.from(envelope['settings'] as Map)
        : <String, dynamic>{};

    // Pre-parse everything before touching local data.
    final domains = (restoredData['domains'] as List)
        .map((e) => Domain.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final tasks = (restoredData['tasks'] as List)
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final dailyLogs = (restoredData['dailyLogs'] as List)
        .map((e) => DailyLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final rivals = (restoredData['rivals'] as List)
        .map((e) => Rival.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final profileJson = restoredData['playerProfile'];
    final profile = (profileJson is Map)
        ? PlayerProfile.fromJson(Map<String, dynamic>.from(profileJson))
        : const PlayerProfile();

    final fuelVaultEntries = <FuelVaultEntry>[];
    for (final raw in (restoredData['fuelVault'] as List)) {
      final map = Map<String, dynamic>.from(raw as Map);

      final imageBytesBase64 = map['imageBytesBase64'];
      if (imageBytesBase64 is String && imageBytesBase64.isNotEmpty) {
        final imageFileName = (map['imageFileName'] is String)
            ? map['imageFileName'] as String
            : _buildFallbackFuelVaultFileName(
                id: map['id'] as String,
                imagePath: map['imagePath'] as String?,
              );

        try {
          final newPath = await writeFuelVaultImageFromBase64(
            imageBytesBase64,
            imageFileName,
          );
          map['imagePath'] = newPath;
        } catch (e, st) {
          _log('Fuel Vault image restore failed (best-effort)', error: e, stackTrace: st);
        }
      }

      fuelVaultEntries.add(FuelVaultEntry.fromJson(map));
    }

    final decodedSettings = <String, Object?>{};
    for (final entry in settingsRaw.entries) {
      final key = entry.key;
      final decoded = _decodeSettingValue(entry.value);
      decodedSettings[key] = decoded;
    }

    // Snapshot current state for rollback (JSON-based).
    final oldDomains = Hive.box<Domain>(_domainsBox).values.map((e) => e.toJson()).toList();
    final oldTasks = Hive.box<Task>(_tasksBox).values.map((e) => e.toJson()).toList();
    final oldDailyLogs = Hive.box<DailyLog>(_dailyLogsBox).values.map((e) => e.toJson()).toList();
    final oldRivals = Hive.box<Rival>(_rivalsBox).values.map((e) => e.toJson()).toList();
    final oldFuelVault = Hive.box<FuelVaultEntry>(_fuelVaultBox).values.map((e) => e.toJson()).toList();
    final oldProfile =
        Hive.box<PlayerProfile>(_playerProfileBox).get(_playerProfileKey)?.toJson();

    final oldSettingsBox = Hive.box(_settingsBox);
    final oldSettings = <String, dynamic>{};
    for (final key in oldSettingsBox.keys) {
      if (key is! String) continue;
      oldSettings[key] = _encodeSettingValue(oldSettingsBox.get(key));
    }

    try {
      // Clear boxes.
      await Hive.box<Domain>(_domainsBox).clear();
      await Hive.box<Task>(_tasksBox).clear();
      await Hive.box<DailyLog>(_dailyLogsBox).clear();
      await Hive.box<Rival>(_rivalsBox).clear();
      await Hive.box<FuelVaultEntry>(_fuelVaultBox).clear();
      await Hive.box<PlayerProfile>(_playerProfileBox).clear();
      await Hive.box(_settingsBox).clear();

      // Restore settings.
      final settingsBox = Hive.box(_settingsBox);
      for (final entry in decodedSettings.entries) {
        final key = entry.key;
        final value = entry.value;
        if (value == null) {
          await settingsBox.delete(key);
        } else {
          await settingsBox.put(key, value);
        }
      }

      // Restore data.
      final domainsBox = Hive.box<Domain>(_domainsBox);
      for (final d in domains) {
        await domainsBox.put(d.id, d);
      }

      final tasksBox = Hive.box<Task>(_tasksBox);
      for (final t in tasks) {
        await tasksBox.put(t.id, t);
      }

      final dailyLogsBox = Hive.box<DailyLog>(_dailyLogsBox);
      for (final l in dailyLogs) {
        final key = app_date_utils.DateUtils.getDateKey(l.date);
        await dailyLogsBox.put(key, l);
      }

      final rivalsBox = Hive.box<Rival>(_rivalsBox);
      for (final r in rivals) {
        await rivalsBox.put(r.id, r);
      }

      final fuelVaultBox = Hive.box<FuelVaultEntry>(_fuelVaultBox);
      for (final e in fuelVaultEntries) {
        await fuelVaultBox.put(e.id, e);
      }

      await Hive.box<PlayerProfile>(_playerProfileBox).put(_playerProfileKey, profile);
    } catch (e, st) {
      _log('Restore failed mid-flight; attempting rollback', error: e, stackTrace: st);
      await _rollback(
        domains: oldDomains,
        tasks: oldTasks,
        dailyLogs: oldDailyLogs,
        rivals: oldRivals,
        fuelVault: oldFuelVault,
        settings: oldSettings,
        profile: oldProfile,
      );
      rethrow;
    }
  }

  Future<void> _rollback({
    required List<dynamic> domains,
    required List<dynamic> tasks,
    required List<dynamic> dailyLogs,
    required List<dynamic> rivals,
    required List<dynamic> fuelVault,
    required Map<String, dynamic> settings,
    required Map<String, dynamic>? profile,
  }) async {
    try {
      await Hive.box<Domain>(_domainsBox).clear();
      await Hive.box<Task>(_tasksBox).clear();
      await Hive.box<DailyLog>(_dailyLogsBox).clear();
      await Hive.box<Rival>(_rivalsBox).clear();
      await Hive.box<FuelVaultEntry>(_fuelVaultBox).clear();
      await Hive.box<PlayerProfile>(_playerProfileBox).clear();
      await Hive.box(_settingsBox).clear();

      final settingsBox = Hive.box(_settingsBox);
      for (final entry in settings.entries) {
        final decoded = _decodeSettingValue(entry.value);
        if (decoded == null) {
          await settingsBox.delete(entry.key);
        } else {
          await settingsBox.put(entry.key, decoded);
        }
      }

      final domainsBox = Hive.box<Domain>(_domainsBox);
      for (final raw in domains) {
        final d = Domain.fromJson(Map<String, dynamic>.from(raw as Map));
        await domainsBox.put(d.id, d);
      }

      final tasksBox = Hive.box<Task>(_tasksBox);
      for (final raw in tasks) {
        final t = Task.fromJson(Map<String, dynamic>.from(raw as Map));
        await tasksBox.put(t.id, t);
      }

      final dailyLogsBox = Hive.box<DailyLog>(_dailyLogsBox);
      for (final raw in dailyLogs) {
        final l = DailyLog.fromJson(Map<String, dynamic>.from(raw as Map));
        final key = app_date_utils.DateUtils.getDateKey(l.date);
        await dailyLogsBox.put(key, l);
      }

      final rivalsBox = Hive.box<Rival>(_rivalsBox);
      for (final raw in rivals) {
        final r = Rival.fromJson(Map<String, dynamic>.from(raw as Map));
        await rivalsBox.put(r.id, r);
      }

      final fuelVaultBox = Hive.box<FuelVaultEntry>(_fuelVaultBox);
      for (final raw in fuelVault) {
        final e = FuelVaultEntry.fromJson(Map<String, dynamic>.from(raw as Map));
        await fuelVaultBox.put(e.id, e);
      }

      if (profile != null) {
        final p = PlayerProfile.fromJson(profile);
        await Hive.box<PlayerProfile>(_playerProfileBox).put(_playerProfileKey, p);
      }
    } catch (e, st) {
      _log('Rollback failed', error: e, stackTrace: st);
    }
  }

  static String _extractFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return 'jpg';
    final ext = path.substring(lastDot + 1).toLowerCase();
    if (ext.isEmpty) return 'jpg';
    // Basic sanity: keep alphanumerics only.
    final cleaned = ext.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned.isEmpty ? 'jpg' : cleaned;
  }

  static String _buildFallbackFuelVaultFileName({
    required String id,
    required String? imagePath,
  }) {
    final ext = (imagePath == null) ? 'jpg' : _extractFileExtension(imagePath);
    return '$id.$ext';
  }

  static Object? _encodeSettingValue(Object? value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is DateTime) {
      return <String, dynamic>{'__t': 'DateTime', 'v': value.toIso8601String()};
    }
    // Unknown type — skip to avoid corrupt restore.
    return null;
  }

  static Object? _decodeSettingValue(Object? value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map['__t'] == 'DateTime' && map['v'] is String) {
        return DateTime.parse(map['v'] as String);
      }
    }
    return null;
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

    final migrated = _migrationService.normalizeAndMigrate(decoded);
    _validateLatestEnvelope(migrated);
    return migrated;
  }

  void _validateLatestEnvelope(Map<String, dynamic> envelope) {
    final version = envelope['schemaVersion'];
    if (version is! int) {
      throw const FormatException('"schemaVersion" must be an integer.');
    }
    if (version != schemaVersion) {
      // We only ever output the latest; treat mismatch as invalid.
      throw FormatException('Unsupported schemaVersion: $version');
    }

    if (envelope['timestamp'] is! String) {
      throw const FormatException('"timestamp" must be a string.');
    }

    if (envelope['data'] is! Map) {
      throw const FormatException('"data" must be a JSON object.');
    }

    final data = Map<String, dynamic>.from(envelope['data'] as Map);
    const listKeys = ['domains', 'tasks', 'dailyLogs', 'rivals', 'fuelVault'];
    for (final key in listKeys) {
      if (data[key] is! List) {
        throw FormatException('"data.$key" must be a JSON array.');
      }
    }

    if (data['playerProfile'] != null && data['playerProfile'] is! Map) {
      throw const FormatException('"data.playerProfile" must be a JSON object.');
    }
    if (data['weeklyStats'] != null && data['weeklyStats'] is! Map) {
      throw const FormatException('"data.weeklyStats" must be a JSON object.');
    }
  }
}

class BackupPreview {
  final Map<String, dynamic> envelope;
  final int schemaVersion;
  final String timestampUtc;
  final String device;
  final String appVersion;

  final int domainsCount;
  final int tasksCount;
  final int dailyLogsCount;
  final int rivalsCount;
  final int fuelVaultCount;

  final int profileLevel;
  final String profileRank;
  final String profileName;

  const BackupPreview({
    required this.envelope,
    required this.schemaVersion,
    required this.timestampUtc,
    required this.device,
    required this.appVersion,
    required this.domainsCount,
    required this.tasksCount,
    required this.dailyLogsCount,
    required this.rivalsCount,
    required this.fuelVaultCount,
    required this.profileLevel,
    required this.profileRank,
    required this.profileName,
  });
}

/// Thrown by [BackupService] when an unrecoverable error occurs during restore.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}
