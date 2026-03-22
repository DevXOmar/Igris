# IGRIS

> Not a productivity app.  
> A mirror.  
> A blade.  
> A witness.

---

## What Is Igris?

Igris is not built to help me “get things done.”

It exists to make sure I do not forget who I am becoming.

Every domain inside this system is not a category.
It is a fragment of identity.

Each one is a pillar.

And every week is a campaign.

---

## Philosophy

Perfection is cheap when it resets daily.

Igris does not reward daily spikes.
It rewards sustained pressure.

You do not reach 100% in a day.

You climb toward it.
Task by task.
Hour by hour.
Across the week.

If everything scheduled is completed —
only then does the bar reach 100.

Not because you tapped a checkbox.

But because you endured.

---

## The System

Each domain has:

- A weekly campaign.
- A cumulative score from 0 → 100.
- A quiet streak that survives only through consistency.

Daily effort feeds weekly strength.

Weekly strength defines momentum.

Momentum defines identity.

---

## Grace

There are 2 grace tokens per week.

Not excuses.

Not laziness passes.

Strategic resets.

Grace does not inflate score.
It removes unfair penalty.

Because discipline is not self-destruction.
It is controlled intensity.

---

## The Bars

The home screen does not show tasks.

It shows pressure.

Vertical bars rise slowly through the week.
They do not jump to full height in a single day.

They fill only as much as has been earned.

Every bar is a domain.
Every domain is a front.
Every front demands consistency.

---

## The Calendar

The calendar does not show numbers.

It shows memory.

Tap a day and it reveals:

What was trained.
What was built.
What was skipped.
What was protected with grace.

This is not history.

It is accountability.

---

## Architecture (Minimal. Intentional.)

Built with:

- Flutter
- Riverpod
- Hive
- Silence

No cloud.
No noise.
No external validation.

Local.
Personal.
Controlled.

---

## Scoring Formula

For each domain:

WeeklyScore =  
(CompletedTasksThisWeek / ScheduledTasksThisWeek) × 100

If grace is used on a day,
that day’s scheduled tasks are removed from the denominator.

Nothing artificial.
Nothing inflated.

Only earned percentage.

---

## Streaks

A week is considered successful if:

WeeklyScore ≥ Threshold.

Streaks are not fragile daily threads.

They are weekly verdicts.

---

## Why This Exists

Because ambition without structure decays.

Because intensity without tracking lies.

Because becoming “better” requires measurement.

Igris is not here to motivate.

It is here to measure.

And to remind.

---

## Status

Private.
Personal.
Evolving.

Built not to impress others.

Built to make sure I never become ordinary.

---

IGRIS.

---

**Developer Quickstart**

- **Install dependencies:** run `flutter pub get` in the project root.
- **Analyze:** run `flutter analyze` and address info/warnings as desired.
- **Tests:** run `flutter test` (this repo's unit tests currently pass).
- **Run:** `flutter run -d <device>` (choose an emulator, desktop target, or web).

## Recent Changes (work since v1.1.1)

- Versioning & Release: runtime app version read from platform metadata instead of a hardcoded value.
- Onboarding & Cinematic Boot: added a cinematic first-launch name flow and `SystemBootScreen` (prewarm + one-frame delay to avoid flicker and smooth transitions).
- Backup & Restore (Schema v2): complete overhaul — export/import as portable JSON, migration paths, preview/confirm UX, atomic restore with rollback, and Fuel Vault images embedded as base64 so restores are device-portable.
- Backup export UX: exports now save to user-visible storage (Downloads/save dialog) and Settings shows the saved location with an `OPEN` action to reveal the file in the system file UI when available.
- Domain progress & Stats refactor: switched to allocation-only storage and pure derived stats via `DomainProgressService` (expected-so-far vs completed-so-far weekly progress) — fixes weekly progress semantics and improves testability.
- Tasks & Scheduling: `Task` model extended with scheduling metadata (`activeDays`, `createdAt`, `scheduledFor`) to support recurring and one-off schedules.
- XP & Streaks: XP rebalance, streak milestones, and title unlocks added; persisted and migrated across schema changes.
- Rivals UX: network overlay edit/delete restored; detail views use latest rival state.
- Backup reliability: fallback test-mode file write to app documents to keep tests deterministic; cross-platform save helpers for web/IO supported.
- App icon pipeline & repo hygiene: source icon handling + launcher icon tooling; refined .gitignore to keep critical lockfiles and ignore generated intermediates.
- Transition polish: navigation delayed by one frame, prewarm for boot screen, and lightweight first frame rendering to reduce visual jank on startup.
- Misc: many analyzer-friendly small fixes and refactors; new unit tests for `DomainProgressService` and backup migrations.


**Backup & Restore**

- Igris provides a full JSON backup/export and atomic restore flow (schema v2). Read the full specification and safety guarantees in [BACKUP_SYSTEM.md](BACKUP_SYSTEM.md).
- Export/restore orchestration is implemented in [lib/services/backup_service.dart](lib/services/backup_service.dart) with schema normalization in [lib/services/backup_migration_service.dart](lib/services/backup_migration_service.dart).
- From the app UI: open Settings → Data Safety → `Backup Data` / `Restore Backup` (see [lib/screens/settings/settings_screen.dart](lib/screens/settings/settings_screen.dart)). After a successful export, the app shows the saved location and (when supported by the platform) an `OPEN` action to reveal/open it in the system file UI.

**App Icon Pipeline**

- Source icon: `assets/icon/app_icon.png` (PNG preferred; JPEG is supported as a fallback).
- To regenerate platform icons:
	1. Convert source to a square 1024 PNG: `dart run tool/icon/convert_app_icon.dart`
	2. Run the launcher icons generator: `flutter pub run flutter_launcher_icons:main` (configured via `flutter_launcher_icons.yaml`).
- The intermediate generated 1024 PNG is ignored from git; keep only the source (`assets/icon/app_icon.png`) tracked.

**Where to look next (key files)**

- Backup system: [lib/services/backup_service.dart](lib/services/backup_service.dart)
- Migration helpers: [lib/services/backup_migration_service.dart](lib/services/backup_migration_service.dart)
- Backup platform helpers (IO / Web): [lib/services/backup_platform_io.dart](lib/services/backup_platform_io.dart) and [lib/services/backup_platform_web.dart](lib/services/backup_platform_web.dart)
- Settings UI (backup UX): [lib/screens/settings/settings_screen.dart](lib/screens/settings/settings_screen.dart)
- Icon converter: [tool/icon/convert_app_icon.dart](tool/icon/convert_app_icon.dart)
- Icon config: [flutter_launcher_icons.yaml](flutter_launcher_icons.yaml)

**Repository Notes**

- Commit `pubspec.lock` (this repo should not ignore lockfiles).
- The analyzer may report info-level suggestions (prefer_const, etc.); these are not blocking but useful to clean up.

If you'd like, I can add a short CI job to run `flutter analyze` + `flutter test` on every push, and/or add a unit test that validates v1→v2 migration behavior.