# Setup Guide for Igris

This guide will help you set up and run the Igris Flutter app.

## Prerequisites

Before you begin, ensure you have:

1. **Flutter SDK** installed (version 3.0 or later)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter --version`

2. **Dart SDK** (comes with Flutter)

3. **IDE/Editor** (VS Code or Android Studio recommended)

4. **Device or Emulator**
   - iOS Simulator (macOS only)
   - Android Emulator
   - Physical device connected via USB

## Step-by-Step Setup

### 1. Navigate to Project Directory

```bash
cd /Users/shaikmohammedomar/IgrisE/Igris
```

### 2. Install Dependencies

Run the following command to install all required packages:

```bash
flutter pub get
```

This will install:
- flutter_riverpod (state management)
- hive & hive_flutter (local storage)
- table_calendar (calendar UI)
- uuid (ID generation)
- intl (date formatting)
- And development dependencies

### 3. Generate Hive Type Adapters

The app uses Hive for local storage with custom type adapters. You **must** generate these before running the app:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This command will generate three files:
- `lib/models/domain.g.dart`
- `lib/models/task.g.dart`
- `lib/models/daily_log.g.dart`

**Important**: The app will **not compile** without these generated files!

If you need to regenerate (after model changes):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch for changes (auto-regenerates):
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Verify Everything is Ready

Check that there are no errors:

```bash
flutter analyze
```

### 5. Run the App

#### Option A: Run with Flutter Command
```bash
flutter run
```

#### Option B: Run in Debug Mode
```bash
flutter run --debug
```

#### Option C: Run in Release Mode (optimized)
```bash
flutter run --release
```

#### Option D: Select Specific Device
First, list available devices:
```bash
flutter devices
```

Then run on specific device:
```bash
flutter run -d <device-id>
```

### 6. Hot Reload During Development

While the app is running:
- Press `r` to hot reload
- Press `R` to hot restart
- Press `q` to quit

## Troubleshooting

### Issue: "flutter: command not found"

**Solution**: Flutter is not in your PATH. 

Add Flutter to your PATH by editing your shell profile:

```bash
# For zsh (default on macOS)
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bash_profile
source ~/.bash_profile
```

Replace `/path/to/flutter` with your actual Flutter installation path.

### Issue: "Cannot find .g.dart files"

**Solution**: You forgot to run build_runner. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: "HiveError: Cannot read, unknown typeId"

**Solution**: The Hive adapters are not registered properly. Make sure:
1. The `.g.dart` files exist
2. `main.dart` registers all adapters before opening boxes

### Issue: "version solving failed"

**Solution**: Check your Flutter version compatibility:

```bash
flutter --version
flutter upgrade
flutter pub get
```

### Issue: No devices available

**Solution**: 
- For iOS: Open Xcode and install simulators
- For Android: Open Android Studio and create an emulator
- Or connect a physical device with USB debugging enabled

### Issue: Build errors on iOS

**Solution**:
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: Build errors on Android

**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

## Project Structure Overview

After setup, your project structure should look like:

```
lib/
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── date_utils.dart
├── models/
│   ├── domain.dart
│   ├── domain.g.dart          # ← Generated file
│   ├── task.dart
│   ├── task.g.dart            # ← Generated file
│   ├── daily_log.dart
│   └── daily_log.g.dart       # ← Generated file
├── services/
│   ├── domain_service.dart
│   ├── task_service.dart
│   ├── daily_log_service.dart
│   └── settings_service.dart
├── providers/
│   ├── domain_provider.dart
│   ├── task_provider.dart
│   ├── daily_log_provider.dart
│   ├── grace_provider.dart
│   └── navigation_provider.dart
├── screens/
│   ├── home/
│   ├── calendar/
│   ├── domains/
│   └── settings/
├── widgets/
│   ├── task_item.dart
│   └── grace_tokens_display.dart
└── main.dart
```

## Running Tests (Future)

Currently no tests are implemented. To add tests:

```bash
flutter test
```

## Building for Release

### Android APK
```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS App
```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to archive and distribute.

## Clean Build (If Issues Persist)

If you encounter persistent build issues:

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## Next Steps

1. Generate the Hive adapters (most important!)
2. Run the app
3. Create your first domain
4. Add some tasks
5. Track your progress!

## Need Help?

- Flutter Documentation: https://flutter.dev/docs
- Riverpod Documentation: https://riverpod.dev
- Hive Documentation: https://docs.hivedb.dev

---

**Happy coding! 🚀**
