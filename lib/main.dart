import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'models/domain.dart';
import 'models/task.dart';
import 'models/daily_log.dart';
import 'screens/home/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters
  Hive.registerAdapter(DomainAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(DailyLogAdapter());
  
  // Open Hive Boxes
  await Hive.openBox<Domain>('domainsBox');
  await Hive.openBox<Task>('tasksBox');
  await Hive.openBox<DailyLog>('dailyLogsBox');
  await Hive.openBox('settingsBox');
  
  runApp(
    // ProviderScope is required for Riverpod
    // All providers must be descendants of ProviderScope
    const ProviderScope(
      child: IgrisApp(),
    ),
  );
}

/// Main application widget
class IgrisApp extends StatelessWidget {
  const IgrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Igris',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
