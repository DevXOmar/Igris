# Igris - Personal Productivity & Identity Tracking App

A Flutter mobile app for tracking personal productivity across different life domains with a weekly grace system.

## 🚀 Features

- **Domain Management**: Create and manage life domains (Health, Work, Learning, etc.)
- **Task Tracking**: Add recurring and one-time tasks to each domain
- **Daily Progress**: Track daily task completion with an intuitive interface
- **Domain Strength**: Domain strength increases as you complete tasks
- **Grace System**: 2 weekly grace tokens to prevent streak breaks
- **Calendar View**: Visual monthly calendar showing task completion history
- **Dark Theme**: Modern minimal dark design

## 🏗️ Architecture

The app follows a clean architecture with separation of concerns:

```
lib/
├── core/
│   ├── theme/          # App theme configuration
│   └── utils/          # Utility functions (date helpers)
├── models/             # Data models with Hive adapters
│   ├── domain.dart
│   ├── task.dart
│   └── daily_log.dart
├── services/           # Business logic and Hive operations
│   ├── domain_service.dart
│   ├── task_service.dart
│   ├── daily_log_service.dart
│   └── settings_service.dart
├── providers/          # Riverpod state management
│   ├── domain_provider.dart
│   ├── task_provider.dart
│   ├── daily_log_provider.dart
│   ├── grace_provider.dart
│   └── navigation_provider.dart
├── screens/            # UI screens
│   ├── home/
│   ├── calendar/
│   ├── domains/
│   └── settings/
├── widgets/            # Reusable widgets
│   ├── task_item.dart
│   └── grace_tokens_display.dart
└── main.dart           # App entry point
```

## 📦 Tech Stack

- **Flutter** (latest stable)
- **Dart** 
- **Hive** for local storage
- **Riverpod** for state management
- **table_calendar** for calendar view
- **uuid** for generating unique IDs

## 🔧 Setup Instructions

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- iOS Simulator (for macOS) or Android Emulator

### Installation Steps

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate Hive Adapters**
   
   The app uses Hive for local storage with type adapters. Generate them with:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   
   This will generate:
   - `lib/models/domain.g.dart`
   - `lib/models/task.g.dart`
   - `lib/models/daily_log.g.dart`

3. **Run the App**
   ```bash
   flutter run
   ```

## 🎯 How It Works

### State Management with Riverpod

The app uses Riverpod 2.x with `NotifierProvider` for clean, reactive state management:

- **DomainProvider**: Manages life domains (add, update, toggle active, adjust strength)
- **TaskProvider**: Manages tasks (add, update, delete, filter by domain)
- **DailyLogProvider**: Tracks daily task completion and updates domain strength
- **GraceProvider**: Manages weekly grace tokens with auto-reset
- **NavigationProvider**: Handles bottom navigation state

### Data Flow

```
UI (ConsumerWidget)
  ↓
ref.watch(provider) / ref.read(provider.notifier)
  ↓
Notifier methods
  ↓
Service layer
  ↓
Hive (local storage)
  ↓
State updated → UI rebuilds
```

### Grace System

- **2 grace tokens per week**
- Automatically resets every 7 days
- Stored in `settingsBox` with `lastResetDate`
- Use grace to skip a day without breaking streak
- Grace usage stored in `DailyLog` model

### Today's Tasks Logic

The `todayTasksProvider` automatically:
- Includes all recurring tasks (appear every day)
- Includes all one-time tasks (V1 shows all; V2 will add date filtering)
- Filters tasks from inactive domains
- Sorts: recurring first, then alphabetically

### Domain Strength

- Increments when task is marked complete
- Decrements when completion is removed (never goes below 0)
- Provides visual feedback on progress in each domain

## 📱 Screens

1. **Home Screen**: Today's date, task list, grace tokens display
2. **Calendar Screen**: Monthly calendar with completion indicators
3. **Domains Screen**: Manage domains and their tasks
4. **Settings Screen**: Grace system info, statistics, domain strengths

## 🗂️ Data Models

### Domain
- `id`: String (UUID)
- `name`: String
- `strength`: int (increments with task completion)
- `isActive`: bool (active domains show in today's tasks)

### Task
- `id`: String (UUID)
- `domainId`: String
- `title`: String
- `isRecurring`: bool (recurring tasks appear daily)

### DailyLog
- `date`: DateTime (normalized to midnight)
- `completedTaskIds`: List<String>
- `graceUsed`: bool

## 🔄 Weekly Reset

The grace system automatically resets weekly:

1. On app start, `GraceProvider` checks `lastResetDate`
2. If 7+ days have passed, triggers reset:
   - `weeklyGraceLeft` = 2
   - `lastResetDate` = now
3. Persists to `settingsBox` in Hive

## 🎨 Theme

Dark theme only with:
- Primary color: Purple (#6C63FF)
- Secondary color: Green (#4CAF50)
- Background: Dark (#121212)
- Material 3 design system

## 📝 Future Enhancements (V2+)

- Date-specific one-time tasks
- Streak tracking and visualization
- Task completion history per domain
- Export data
- Cloud backup
- Notifications and reminders
- Task notes and attachments

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

## 📄 License

See LICENSE file for details.

---

**Igris** - Track your progress, build your identity.