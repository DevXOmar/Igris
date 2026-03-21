# Igris — System Architecture & Integrity Specification

> Igris is not a to‑do app.
> It is a personal progression engine: a set of rules that turn consistent execution into identity.

This document is a full-system validation and reference for the Igris Flutter app.
It describes the runtime architecture, the persistence model, the progression philosophy,
and the constraints/safeguards that keep the system consistent.

---

## 1. Overview

Igris is built around a simple loop:

- You define **Domains** (life arenas).
- You define **Tasks** within those domains.
- Each day you complete tasks (or consciously invoke **Grace**).
- Completion produces:
  - **Weekly progress** (score + per-domain bars)
  - **Streak continuity** (via ≥70% completion or Grace)
  - **XP** (level/rank/title unlock progression)
  - **Stat growth** (Domain → stat contribution weights)
- Equipped **Titles** shape the meaning of your work by modifying rewards.

The system is implemented in Flutter/Dart using Riverpod Notifiers and Hive persistence.

---

## 2. Core Philosophy

Igris assumes:

- **Identity emerges from repeated execution**, not motivation.
- **Domains** represent where you choose to become strong.
- **Stats** represent what that strength becomes.
- **Grace** preserves continuity, but does not create power.
- **Titles** are not cosmetics. They are *doctrines*—small, deliberate biases.

A consistent system is one where every layer agrees:

- What counts as work today
- What counts as progress this week
- What counts as a streak day
- What creates XP
- What creates stat growth
- What titles modify (and when)

---

## 3. Domain System

### 3.1 Data Model

A **Domain** is stored in Hive (`domainsBox`) and represented by the `Domain` model.

Fields:

- `id: String` — stable identifier
- `name: String` — user-visible label
- `strength: int` — long-term domain strength (currently increments on completion)
- `isActive: bool` — whether this domain’s tasks appear in daily/weekly computation
- `statWeights: Map<String,double>` — Domain → stat contribution mapping

### 3.2 Stat Weight Rules

Rules are enforced by normalization utilities:

- Only known stat keys are allowed:
  - `presence, strength, agility, intelligence, discipline, endurance`
- Only positive finite weights are allowed
- Maximum of **3** stats per domain
- Weights are normalized to sum to **1.0**
- If missing or invalid, fallback weights are used:
  - `{ discipline: 0.5, intelligence: 0.5 }`

### 3.3 Creation Flow

Domain creation supports:

- Presets
- Custom domain names

During creation:

1. A name is selected/entered.
2. Weights are inferred from keywords.
3. UI previews “This domain contributes to …”.
4. Optional: the user can open an “Adjust Mapping” sheet and override weights.
5. Saved Domain persists `statWeights` in Hive.

### 3.4 Storage & Retrieval Integrity

- Hive adapter for Domain is backward-compatible: older domains without `statWeights`
  infer weights from the domain name.

---

## 4. Task System

### 4.1 Data Model

A **Task** is stored in Hive (`tasksBox`) and represented by the `Task` model.

Fields:

- `id: String`
- `domainId: String`
- `title: String`
- `isRecurring: bool`

### 4.2 Creation Flow

Tasks are created from the Domain screen:

- The user provides a title.
- The user chooses whether it is recurring.
- A UUID is assigned.
- Task is written to Hive.

### 4.3 Daily Task Generation

Current behavior (V1):

- “Today’s tasks” include **all tasks** that belong to **active domains**.
- Recurring tasks are not duplicated per day; they are simply always visible.
- One-time tasks are also visible (no due date logic yet).

Design implication:

- One-time tasks function like a backlog list that remains present until deleted.

---

## 5. Daily Flow (Completion Pipeline)

### 5.1 Source of Truth

The **DailyLog** is the source of truth for daily completion state.
It is stored in Hive (`dailyLogsBox`) keyed by date key `yyyy-MM-dd`.

DailyLog fields:

- `date: DateTime`
- `completedTaskIds: List<String>`
- `graceUsed: bool`
- `rewardedTaskIds: List<String>` — prevents reward re-awarding on toggles

### 5.2 Complete Task

When a user completes a task:

1. DailyLog is updated (task ID added).
2. Domain strength is incremented.
3. Rewards are granted only if:
   - Grace is not used today
   - AND the task hasn’t already granted rewards today (via `rewardedTaskIds`)
4. Rewards include:
   - XP (with title modifiers)
   - Stat growth (via domain stat weights + title stat bonuses)

### 5.3 Uncomplete Task

When a user uncompletes a task:

1. DailyLog is updated (task ID removed).
2. Domain strength is decremented.
3. XP/stat rewards are not reversed.

This is a deliberate simplification but has philosophical consequences.
See “Edge Cases & Safeguards”.

---

## 6. Streak & Grace System

### 6.1 Streak Definition

A day counts toward streak if either:

- Daily completion ≥ 70% (among tasks in active domains)
- OR `graceUsed == true`

The streak is computed by scanning backward from today until a day fails criteria.

Safeguards:

- If there are no active tasks at all, streak is defined as **0**.
- The streak computation has a bounded lookback to prevent underflow.

### 6.2 Grace Tokens

Grace is a weekly resource:

- Maximum tokens per week: 2
- Reset aligned to Monday week boundaries

Using Grace:

- Marks `DailyLog.graceUsed = true` for the day
- Preserves streak continuity
- Blocks XP awards for that date
- Prevents additional XP/stat reward grants for tasks completed on that date

### 6.3 Weekly Enforcement Window

Grace enforcement is computed by counting `graceUsed` logs within the week
containing the **target date** (not always the current week).

---

## 7. Weekly Progress System

Weekly stats compute:

- Per-domain weekly progress (0.0 → 1.0)
- Weekly score (0.0 → 100.0)
- Completed tasks this week
- Total scheduled task instances for the full week

Current weekly denominator model:

- For each active domain: `domainTasks.length * 7`
- Progress counts completions Monday → today
- Weekly score is the ratio of completed instances over full-week scheduled instances

Design implication:

- Weekly score is cumulative and intentionally “hard”: you only hit 100% if you
  complete all tasks for all days of the week.

---

## 8. XP & Leveling System

### 8.1 XP Sources

XP is currently awarded from:

- Task completion (`XpRewards.taskComplete`)
- Domain complete (when triggered by UI/logic)
- Weekly goal completion
- Streak milestones (7/14/21/30)

### 8.2 XP Formula

Required XP to level up from level `L` is:

- `requiredXP = 100 * L^1.5`

Level-ups are handled in a loop so multi-level jumps are safe.

### 8.3 Grace Rule

If Grace is used today, XP awards are blocked.

---

## 9. Stat System

Stats are stored in the player profile:

- `presence, strength, agility, endurance, intelligence, discipline`

Constraints:

- Default stat value: 1
- Max stat value: 99

Two growth pathways exist:

1. **Allocation points** (manual): unspent stat points earned from XP milestones
2. **Organic growth** (automatic): per-task stat gains distributed via domain weights

---

## 10. Domain → Stat Mapping

Each domain has `statWeights` (max 3 keys; sum=1.0).

When a task is completed (and rewards are allowed):

1. Compute base stat distribution from domain weights.
2. Apply title stat bonuses **after** domain distribution:
   - `allStatsBonus`
   - `statBonus`
   - Conditional weekly-balance bonus for `rulers_authority` if active
3. Apply deterministic rounding so small fractional gains resolve consistently.
4. Clamp stats to max.

This ordering preserves the philosophy:

- Domain decides *what you become*
- Titles decide *how strongly you lean*

---

## 11. Allocation Points System

Allocation points are earned from XP milestones:

- Every 250 total XP yields 1 stat point (baseline)
- Equipped titles can add a stat point bonus multiplier

Spending points:

- UI writes through a single method that clamps stats and prevents negative unspent values.

---

## 12. Title System

Titles are a static catalogue with:

- `id, name, description, unlockCondition (text), icon`
- `checkCondition(context)` — pure unlock logic
- `effects` — numeric and informational modifiers

Unlock behavior:

- Titles unlock automatically during XP award pipeline (`addXP`).
- Unlocks are permanent once achieved.

---

## 13. Title Effects & Stacking Rules

### 13.1 Effects

Supported effect types include:

- XP modifiers:
  - `xpBonus` (all XP)
  - `streakXpBonus` (streak awards)
  - `taskXpBonus` (category-aware)
  - `weeklyGoalXpBonus`
- Stat point growth modifier:
  - `statPointBonus`
- Stat modifiers:
  - `statBonus`
  - `allStatsBonus`
- Notes:
  - informational only

### 13.2 Stacking Model

- XP bonuses are additive and capped (to prevent runaway growth):
  - Total additive XP bonus capped at 50%
- Stat point bonus is additive and capped similarly
- Task/weekly goal bonuses are additive and currently uncapped (but limited by max 2 equipped titles)

### 13.3 Equip Limits

- Max 2 titles can be equipped.
- Equipped titles are the authoritative list; legacy active titles are sanitized.

---

## 14. System Flow Diagram (Text)

```
USER ACTION
  ├─ Create Domain
  │    ├─ inferStatWeights(name)
  │    ├─ optional adjust mapping (max 3, normalize)
  │    └─ persist Domain (Hive)
  │
  ├─ Create Task
  │    └─ persist Task (Hive)
  │
  └─ Complete Task (today)
       ├─ write DailyLog.completedTaskIds
       ├─ increment Domain.strength
       ├─ if graceUsed(today) => STOP (no rewards)
       ├─ if task already rewarded today => STOP (no duplicate rewards)
       ├─ Domain → Stat distribution (weights)
       │    └─ apply title stat bonuses AFTER distribution
       ├─ award XP (apply title XP effects)
       └─ check pipeline:
            level-ups → rank promotion → title unlocks → stat point milestones

WEEKLY LOOP (derived)
  ├─ weeklyStatsProvider
  │    ├─ weeklyProgress per domain
  │    ├─ weeklyScore
  │    └─ streak calculation (>=70% or grace)
  └─ UI renders bars + score + streak

GRACE LOOP
  ├─ weekly reset at Monday boundary
  ├─ applyGraceForDate(date)
  │    ├─ enforce max 2 in that week
  │    └─ mark DailyLog.graceUsed
  └─ XP blocked on grace-used days
```

---

## 15. Edge Cases Handling (Validated)

### No Domains / No Tasks

- Weekly score: 0
- Weekly progress: empty map
- Streak: 0 (explicitly guarded)
- Grace: still trackable, but typically irrelevant until tasks exist

### Rapid Task Toggling

- Rewards are granted at most once per task per day (via `rewardedTaskIds`).

### Retroactive Grace Attempts

- Weekly enforcement is computed for the target date’s week.

### Midnight Transitions

- Date normalization uses “today at midnight” (`DateUtils.today`).
- Caution: time zones and DST can still produce surprising behavior if the
  device clock changes abruptly; see “Suggested Improvements”.

---

## 16. Constraints & Safeguards

Hard constraints:

- Max 2 titles equipped
- Max 2 grace tokens per week
- Domain stat weights:
  - max 3 stats
  - sum to 1.0
- Stats clamped to 0..99 at write
- XP additive bonuses capped at 50%

Key safeguards implemented during audit:

- Backup restore stores DailyLogs under the correct Hive key format
- Streak computation cannot underflow due to missing tasks/logs
- Duplicate daily rewards prevented even with rapid toggles

---

## Appendix A — Audit Findings & Recommended Fixes

### Fixed in this audit

- Backup restore wrote `dailyLogsBox` entries using an ISO timestamp key instead of `yyyy-MM-dd`, making restored logs unreachable.
- Streak calculation previously ended (or could loop indefinitely) based on log existence; now it is bounded and defined sensibly for “no tasks” scenarios.
- Debug `print()` statements in core providers removed to avoid performance/log spam.
- `TaskService.getTaskById` and `DomainService.getDomainById` were nullable APIs that could throw; now they are truly nullable.
- Added per-day reward de-duplication to prevent farming XP/stats via rapid toggling.
- Applied conditional weekly-balance stat bonus to stat gains for consistency.
- Grace weekly enforcement now uses the week window containing the target date.

### Not fixed (but important decisions)

- **Uncomplete does not reverse XP/stats**. This is consistent with “rewards are irrevocable”, but it means:
  - A user can earn XP and then uncomplete, leaving the day incomplete.
  - If you want perfect accounting, rewards must become log-derived or reversible.

### Suggested next improvements (scalability + correctness)

- Introduce a “scheduled tasks per date” layer so one-time tasks don’t inflate weekly denominators.
- Consider making domain strength and organic stat growth derive from logs (recomputable) rather than incrementally mutating.
- Add migration schema versioning for models (especially when adding new Hive fields).
- Add targeted unit tests for:
  - grace week boundaries
  - streak boundaries
  - duplicate reward prevention
  - backup export/restore round-trip for DailyLogs
