# Igris - State Management & Architecture Guide

## Overview

Igris uses **Riverpod 2.x** for state management with a clean separation of concerns. This document explains how everything works together.

## State Management Architecture

### Layers

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│    (ConsumerWidgets)                │
└──────────────┬──────────────────────┘
               │ ref.watch() / ref.read()
               ↓
┌─────────────────────────────────────┐
│      Provider Layer                 │
│  (NotifierProvider & Notifiers)     │
└──────────────┬──────────────────────┘
               │ Business Logic
               ↓
┌─────────────────────────────────────┐
│       Service Layer                 │
│   (Domain, Task, DailyLog Services) │
└──────────────┬──────────────────────┘
               │ CRUD Operations
               ↓
┌─────────────────────────────────────┐
│       Storage Layer                 │
│         (Hive Boxes)                │
└─────────────────────────────────────┘
```

## Providers

### 1. DomainProvider

**Purpose**: Manages life domains (Health, Work, Learning, etc.)

**State Class**: `DomainState`
- `domains`: List<Domain>
- `activeDomains`: Filtered list of active domains
- `getDomainById()`: Find domain by ID

**Notifier Methods**:
```dart
// Load domains from Hive
loadDomains()

// CRUD operations
addDomain(Domain domain)
updateDomain(Domain domain)
deleteDomain(String id)

// Domain actions
toggleDomainActive(String id)
updateDomainStrength(String id, int strength)
incrementDomainStrength(String domainId)  // +1 on task completion
decrementDomainStrength(String domainId)  // -1 on task uncompletion
```

**Usage in UI**:
```dart
// Watch state
final domainState = ref.watch(domainProvider);
final activeDomains = domainState.activeDomains;

// Call methods
ref.read(domainProvider.notifier).addDomain(domain);
```

---

### 2. TaskProvider

**Purpose**: Manages tasks within domains

**State Class**: `TaskState`
- `tasks`: List<Task>
- `recurringTasks`: Filtered recurring tasks
- `oneTimeTasks`: Filtered one-time tasks
- `getTaskById()`: Find task by ID
- `getTasksByDomain()`: Filter by domain

**Notifier Methods**:
```dart
// Load tasks from Hive
loadTasks()

// CRUD operations
addTask(Task task)
updateTask(Task task)
deleteTask(String id)
deleteTasksByDomain(String domainId)  // When domain deleted
```

**Usage in UI**:
```dart
// Watch state
final taskState = ref.watch(taskProvider);
final tasks = taskState.tasks;

// Call methods
ref.read(taskProvider.notifier).addTask(task);
```

---

### 3. TodayTasksProvider

**Purpose**: Computed provider for today's task list

**Type**: `Provider<List<Task>>` (computed, not a notifier)

**Logic**:
1. Watch `taskProvider` and `domainProvider`
2. Filter tasks:
   - Include all recurring tasks (appear every day)
   - Include all one-time tasks (V1 logic)
   - Exclude tasks from inactive domains
3. Sort: Recurring first, then alphabetically

**Usage in UI**:
```dart
// Watch today's tasks
final todayTasks = ref.watch(todayTasksProvider);

// No notifier methods - computed automatically
```

---

### 4. DailyLogProvider

**Purpose**: Tracks daily task completion and updates domain strength

**State Class**: `DailyLogState`
- `todayLog`: DailyLog? for today
- `today`: DateTime (normalized)
- `isTaskCompletedToday()`: Quick check

**Notifier Methods**:
```dart
// Load today's log
loadTodayLog()

// Get log for any date
getLogForDate(DateTime date)

// Task completion (also updates domain strength)
toggleTaskCompletion(String taskId, String domainId)
completeTask(String taskId, String domainId)
uncompleteTask(String taskId, String domainId)

// Check completion
isTaskCompletedOnDate(DateTime date, String taskId)

// Grace usage
useGraceForToday()
getGraceUsedThisWeek()
```

**Key Feature**: When task completion changes, domain strength auto-updates:
```dart
// Task completed → domain strength +1
// Task uncompleted → domain strength -1 (never below 0)
```

**Usage in UI**:
```dart
// Watch state
final logState = ref.watch(dailyLogProvider);
final isCompleted = logState.isTaskCompletedToday(taskId);

// Toggle completion
ref.read(dailyLogProvider.notifier)
   .toggleTaskCompletion(taskId, domainId);
```

---

### 5. GraceProvider

**Purpose**: Manages weekly grace token system

**State Class**: `GraceState`
- `weeklyGraceLeft`: int (0-2)
- `maxGraceTokens`: int (always 2)
- `lastResetDate`: DateTime?
- `hasGraceAvailable`: bool getter

**Notifier Methods**:
```dart
// Auto-checks on app start
checkAndResetWeekly()

// Use a grace token
useGraceToken()  // Returns bool (success/failure)

// Manual reset (testing/admin)
forceWeeklyReset()

// Helper
getDaysUntilReset()  // Returns days until next auto-reset
```

**Weekly Reset Logic**:
```
1. On app start → checkAndResetWeekly()
2. Check: days since lastResetDate >= 7?
3. If yes:
   - weeklyGraceLeft = 2
   - lastResetDate = now
   - Persist to settingsBox
```

**Usage in UI**:
```dart
// Watch state
final graceState = ref.watch(graceProvider);
final remaining = graceState.weeklyGraceLeft;

// Use grace
final success = await ref.read(graceProvider.notifier).useGraceToken();
```

---

### 6. NavigationProvider

**Purpose**: Bottom navigation state

**State Class**: `NavigationState`
- `currentIndex`: int (0-3)

**Notifier Methods**:
```dart
setIndex(int index)
goToHome()      // index = 0
goToCalendar()  // index = 1
goToDomains()   // index = 2
goToSettings()  // index = 3
```

**Usage in UI**:
```dart
// Watch state
final navState = ref.watch(navigationProvider);
final currentIndex = navState.currentIndex;

// Navigate
ref.read(navigationProvider.notifier).setIndex(index);
```

---

## Data Flow Examples

### Example 1: Completing a Task

```
User taps task checkbox
  ↓
TaskItem.onToggle()
  ↓
ref.read(dailyLogProvider.notifier)
   .toggleTaskCompletion(taskId, domainId)
  ↓
DailyLogNotifier:
  1. Update DailyLog in Hive
  2. Call domainProvider.incrementDomainStrength()
  3. loadTodayLog() → state updated
  ↓
UI rebuilds (because watching dailyLogProvider)
  ↓
Checkbox shows completed state
```

### Example 2: Weekly Grace Reset

```
App starts
  ↓
main() → runApp(ProviderScope(...))
  ↓
GraceProvider initialized
  ↓
GraceNotifier.build()
  ↓
_initializeAndCheckReset()
  ↓
checkAndResetWeekly()
  ↓
SettingsService.needsWeeklyReset()?
  ↓
If yes: performWeeklyReset()
  1. weeklyGraceLeft = 2
  2. lastResetDate = now
  3. Save to Hive
  ↓
_loadState() → GraceState updated
  ↓
UI shows refreshed grace tokens
```

### Example 3: Filtering Today's Tasks

```
TodayTasksProvider watched
  ↓
Watches: taskProvider, domainProvider
  ↓
Get all tasks and active domains
  ↓
Filter logic:
  - task.domainId in activeDomainIds?
  ↓
Sort:
  - Recurring first
  - Then alphabetically
  ↓
Return List<Task>
  ↓
UI rebuilds list
```

---

## Services (Business Logic)

### DomainService
- `getAllDomains()` → List<Domain>
- `getActiveDomains()` → List<Domain>
- `getDomainById(id)` → Domain?
- `addDomain(domain)` → Future<void>
- `updateDomain(domain)` → Future<void>
- `deleteDomain(id)` → Future<void>
- `toggleDomainActive(id)` → Future<void>
- `updateDomainStrength(id, strength)` → Future<void>

### TaskService
- `getAllTasks()` → List<Task>
- `getTasksByDomain(domainId)` → List<Task>
- `getRecurringTasks()` → List<Task>
- `getOneTimeTasks()` → List<Task>
- `addTask(task)` → Future<void>
- `updateTask(task)` → Future<void>
- `deleteTask(id)` → Future<void>
- `deleteTasksByDomain(domainId)` → Future<void>

### DailyLogService
- `getAllLogs()` → List<DailyLog>
- `getLogForDate(date)` → DailyLog?
- `getOrCreateLogForDate(date)` → DailyLog
- `saveLog(log)` → Future<void>
- `toggleTaskCompletion(date, taskId)` → Future<void>
- `isTaskCompleted(date, taskId)` → bool
- `useGrace(date)` → Future<void>
- `getCurrentWeekLogs()` → List<DailyLog>
- `getGraceUsedThisWeek()` → int

### SettingsService
- `getLastResetDate()` → DateTime?
- `setLastResetDate(date)` → Future<void>
- `getRemainingGraceTokens()` → int
- `setRemainingGraceTokens(count)` → Future<void>
- `useGraceToken()` → Future<bool>
- `needsWeeklyReset()` → bool
- `performWeeklyReset()` → Future<void>
- `checkAndResetWeekly()` → Future<void>
- `initialize()` → Future<void>

---

## Hive Boxes

### domainsBox
- Type: `Box<Domain>`
- Key: domain.id
- Stores all domains

### tasksBox
- Type: `Box<Task>`
- Key: task.id
- Stores all tasks

### dailyLogsBox
- Type: `Box<DailyLog>`
- Key: date string (yyyy-MM-dd format)
- Stores daily completion logs

### settingsBox
- Type: `Box` (dynamic)
- Keys:
  - `'lastWeeklyReset'`: String (ISO 8601 date)
  - `'remainingGraceTokens'`: int
- Stores app settings

---

## UI Patterns

### Using Riverpod in Widgets

**1. ConsumerWidget** (for stateless widgets):
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    return Text(state.value);
  }
}
```

**2. ConsumerStatefulWidget** (for stateful widgets):
```dart
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProvider);
    return Text(state.value);
  }
}
```

### Watching vs Reading

**ref.watch()** - Rebuilds when state changes:
```dart
final state = ref.watch(myProvider);
```

**ref.read()** - One-time read, no rebuild:
```dart
ref.read(myProvider.notifier).doSomething();
```

---

## Best Practices

1. **Keep logic in providers**, not UI
2. **Use services for Hive operations**
3. **Watch providers in build()** for reactive UI
4. **Read providers in callbacks** for actions
5. **Create computed providers** for derived state
6. **Never mutate state directly** - use copyWith()
7. **Keep notifiers focused** - single responsibility
8. **Handle async properly** - use Future/async/await
9. **Commented code** - explain why, not what

---

## Common Patterns

### Adding a New Feature

1. **Model**: Create/update model class in `models/`
2. **Service**: Add service methods in `services/`
3. **Provider**: Create provider in `providers/`
4. **UI**: Use provider in screen/widget

### Debugging State

```dart
// Print state when it changes
ref.listen(myProvider, (previous, next) {
  print('State changed: $previous → $next');
});
```

### Conditional Updates

```dart
// Only update if value actually changed
if (state.value != newValue) {
  state = state.copyWith(value: newValue);
}
```

---

**Remember**: Keep it simple. The architecture is designed to be straightforward and maintainable.
