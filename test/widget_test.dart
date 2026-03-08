import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:igris/main.dart';
import 'package:igris/models/daily_log.dart';
import 'package:igris/models/domain.dart';
import 'package:igris/models/fuel_vault_entry.dart';
import 'package:igris/models/task.dart';

void main() {
  late Directory hiveTestDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    hiveTestDir = await Directory.systemTemp.createTemp('igris_hive_test_');
    Hive.init(hiveTestDir.path);

    Hive.registerAdapter(DomainAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(DailyLogAdapter());
    Hive.registerAdapter(FuelVaultEntryAdapter());

    await Hive.openBox<Domain>('domainsBox');
    await Hive.openBox<Task>('tasksBox');
    await Hive.openBox<DailyLog>('dailyLogsBox');
    await Hive.openBox<FuelVaultEntry>('fuelVaultBox');
    await Hive.openBox('settingsBox');
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveTestDir.existsSync()) {
      await hiveTestDir.delete(recursive: true);
    }
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: IgrisApp()));

    // Verify that the app has loaded (check for "Igris" title)
    expect(find.text('Igris'), findsOneWidget);
  });
}
