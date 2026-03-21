import '../models/player_profile.dart';

/// Handles schema normalization and incremental migrations for backup JSON.
///
/// Goals:
/// - Backward compatible: accept older payload shapes.
/// - Forward safe: ignore unknown fields.
/// - Always output the latest envelope shape.
class BackupMigrationService {
  static const int latestSchemaVersion = 2;

  /// Normalizes a decoded JSON map into the latest envelope.
  ///
  /// Accepts:
  /// - Legacy v1 where lists lived at the root.
  /// - v1+ envelopes with a `data` object.
  ///
  /// Throws [FormatException] if required minimum structure is missing.
  Map<String, dynamic> normalizeAndMigrate(Map<String, dynamic> decoded) {
    final normalized = _normalize(decoded);
    var current = normalized;

    while (current['schemaVersion'] as int < latestSchemaVersion) {
      final v = current['schemaVersion'] as int;
      switch (v) {
        case 1:
          current = _migrateV1toV2(current);
          break;
        default:
          // Unknown historical step; bump defensively to avoid infinite loops.
          current['schemaVersion'] = latestSchemaVersion;
          break;
      }
    }

    // Ensure aliases are consistent.
    current['schemaVersion'] = latestSchemaVersion;
    current['version'] = latestSchemaVersion;
    return current;
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> decoded) {
    final normalized = Map<String, dynamic>.from(decoded);

    // Accept either `schemaVersion` or legacy `version`.
    final schemaVersion = normalized['schemaVersion'] ?? normalized['version'];
    if (schemaVersion is! int) {
      throw const FormatException('"version"/"schemaVersion" must be an integer.');
    }

    normalized['schemaVersion'] = schemaVersion;
    normalized['version'] = schemaVersion;

    // Legacy v1 stored lists at root.
    if (normalized['data'] is! Map) {
      normalized['data'] = <String, dynamic>{
        'domains': normalized['domains'] ?? const [],
        'tasks': normalized['tasks'] ?? const [],
        'dailyLogs': normalized['dailyLogs'] ?? const [],
        'rivals': normalized['rivals'] ?? const [],
        'fuelVault': normalized['fuelVault'] ?? const [],
        // v1 did not have profile; keep null for migration to fill.
        'playerProfile': normalized['playerProfile'],
        'weeklyStats': normalized['weeklyStats'],
      };
    }

    if (normalized['settings'] is! Map) {
      normalized['settings'] = <String, dynamic>{};
    }

    // Be lenient: older backups might miss timestamp/device/appVersion.
    if (normalized['timestamp'] is! String) {
      normalized['timestamp'] = DateTime.now().toUtc().toIso8601String();
    }
    normalized['device'] ??= 'unknown';
    normalized['appVersion'] ??= 'unknown';

    final data = normalized['data'];
    if (data is! Map) {
      throw const FormatException('"data" must be a JSON object.');
    }

    return normalized;
  }

  Map<String, dynamic> _migrateV1toV2(Map<String, dynamic> v1) {
    final next = Map<String, dynamic>.from(v1);
    next['schemaVersion'] = 2;
    next['version'] = 2;

    final data = Map<String, dynamic>.from(next['data'] as Map);

    // Ensure required collections exist.
    data['domains'] ??= const [];
    data['tasks'] ??= const [];
    data['dailyLogs'] ??= const [];
    data['rivals'] ??= const [];
    data['fuelVault'] ??= const [];

    // Ensure profile exists.
    final profile = data['playerProfile'] ?? next['playerProfile'];
    if (profile is Map) {
      data['playerProfile'] = Map<String, dynamic>.from(profile);
    } else {
      data['playerProfile'] = const PlayerProfile().toJson();
    }

    // Weekly stats are derived; store an optional snapshot slot.
    if (data['weeklyStats'] is Map) {
      data['weeklyStats'] = Map<String, dynamic>.from(data['weeklyStats'] as Map);
    }

    next['data'] = data;
    return next;
  }
}
