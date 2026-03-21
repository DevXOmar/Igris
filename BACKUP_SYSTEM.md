# Igris Backup & Restore System (Schema v2)

This document describes the backup/export and restore/import system implemented in the Igris Flutter app.

## Goals

- Export a complete, portable snapshot of user data to a JSON file.
- Support schema evolution with backward compatibility (older backups restore on newer app versions).
- Be forward-safe (unknown fields are ignored where possible).
- Restore safely with validation and rollback to avoid partial/corrupt state.
- Preserve Fuel Vault images across devices via embedded base64 bytes.

## Where It Lives

- Export/restore orchestration: `lib/services/backup_service.dart`
- Schema normalization + migrations: `lib/services/backup_migration_service.dart`
- Platform file helpers:
  - IO: `lib/services/backup_platform_io.dart`
  - Web: `lib/services/backup_platform_web.dart`

## Data Included

Backups include the following persisted state:

- Domains (Hive `domainsBox`)
- Tasks (Hive `tasksBox`)
- Daily Logs (Hive `dailyLogsBox`) — includes completed tasks, grace usage, and rewarded-task tracking
- Rivals (Hive `rivalsBox`)
- Fuel Vault entries (Hive `fuelVaultBox`) + embedded images
- Player profile / progression (Hive `playerProfileBox`, key `profile`) — level, XP, stats, streak milestones, titles, feats
- Settings (Hive `settingsBox`) — grace tokens/reset state, vault PIN, and other preferences stored as primitives/DateTime
- Weekly stats snapshot (derived) — score/progress/streak snapshot at export time

Notes:
- Weekly stats are *derived* from tasks + logs at runtime; the backup stores a snapshot for visibility/debugging, but restore correctness relies on the underlying tasks/logs/profile.

## JSON Envelope (Schema v2)

Top-level structure:

```json
{
  "schemaVersion": 2,
  "version": 2,
  "appVersion": "0.1.0",
  "timestamp": "2026-03-21T12:34:56.000Z",
  "device": "ios|android|macos|web|unknown",
  "settings": { "someKey": "someValue" },
  "data": {
    "domains": [ { "id": "..." } ],
    "tasks": [ { "id": "..." } ],
    "dailyLogs": [ { "date": "..." } ],
    "rivals": [ { "id": "..." } ],
    "fuelVault": [ { "id": "...", "imageBytesBase64": "..." } ],
    "playerProfile": { "level": 1, "stats": { "presence": 1 } },
    "weeklyStats": { "weeklyScore": 0.0, "currentStreak": 0 }
  }
}
```

### `version` vs `schemaVersion`

- `schemaVersion` is the authoritative schema value.
- `version` is a legacy alias maintained for compatibility with older backup files.

## Migrations

Migrations run in two phases:

1. **Normalization**: accepts older shapes (including legacy v1 where lists lived at the root) and coerces them into an envelope with a `data` object.
2. **Incremental migrations**: upgrades `schemaVersion` step-by-step until the latest schema is reached.

Implementation: `BackupMigrationService.normalizeAndMigrate()`.

### v1 → v2

- Wraps root lists into `data.*` if needed
- Ensures missing `playerProfile` is filled with a default profile
- Adds/normalizes `schemaVersion` and other metadata

## Restore Safety & Atomicity

Restore is designed to avoid leaving the app in a partial state:

- The selected backup is decoded, normalized, migrated, and validated.
- All collections are **pre-parsed** into model objects before modifying Hive.
- Current state is **snapshotted** (as JSON) for rollback.
- Hive boxes are cleared and restored in a safe order:
  1. settings
  2. domains
  3. tasks
  4. daily logs
  5. rivals
  6. fuel vault
  7. player profile
- If any error occurs after data removal begins, the system attempts an in-memory **rollback** to the previous snapshot.

## Fuel Vault Images

Fuel Vault entries may contain:

- `imagePath`: the local file path (or a blob URL on web)
- `imageBytesBase64`: base64-encoded bytes of the image file
- `imageFileName`: a stable filename used when reconstructing the file on restore

On restore:

- If `imageBytesBase64` is present, the image is reconstructed into the app documents directory (`/fuel_vault/<fileName>`) on IO targets.
- On web, a blob URL is created so the restored entry can render without real filesystem access.

Image restore is *best-effort*:
- If writing fails, the entry is still restored, keeping the original `imagePath` from the backup.

## UI Flow (Preview + Confirm)

The Settings screen performs restore as:

1. Pick `.json` backup file
2. Parse + migrate + validate
3. Show a preview summary (counts + profile info)
4. Confirm to apply restore
5. Apply atomic restore + show completion message

## Extending the Schema

When adding new persisted data:

1. Add it to export in `BackupService.exportBackup()`.
2. Add validation expectations in `BackupService._validateLatestEnvelope()`.
3. Update `BackupMigrationService` to fill defaults and migrate from older schemas.
4. Update this document.
