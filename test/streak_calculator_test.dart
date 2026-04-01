import 'package:flutter_test/flutter_test.dart';

import 'package:igris/core/utils/date_utils.dart' as app_date_utils;
import 'package:igris/models/daily_log.dart';
import 'package:igris/models/task.dart';
import 'package:igris/services/streak_calculator.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

DailyLog _log(DateTime date, {List<String> completed = const [], bool grace = false}) {
  return DailyLog(
    date: date,
    completedTaskIds: List<String>.from(completed),
    graceUsed: grace,
  );
}

void main() {
  group('calculateCurrentStreak', () {
    test('New recurring task created today does not penalize yesterday', () {
      final today = _d(2026, 4, 2);

      final task = Task(
        id: 't1',
        domainId: 'd1',
        title: 'Daily',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: today,
      );

      final logs = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(today): _log(today, completed: const ['t1']),
        // No log for yesterday; should not matter because task didn't exist then.
        // (Eligibility is createdAt-aware.)
      };

      final streak = calculateCurrentStreak(
        today: today,
        tasks: [task],
        isDomainActive: (_) => true,
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
      );

      expect(streak, 1);
    });

    test('Off-days (no eligible tasks) are neutral and do not break streak', () {
      // Task only on Mon+Wed+Fri.
      final today = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(today); // Monday

      final task = Task(
        id: 't1',
        domainId: 'd1',
        title: 'MWF',
        isRecurring: true,
        activeDays: const [0, 2, 4],
        createdAt: start,
      );

      final monday = start;
      final wednesday = start.add(const Duration(days: 2));

      final logs = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(monday): _log(monday, completed: const ['t1']),
        app_date_utils.DateUtils.getDateKey(wednesday): _log(wednesday, completed: const ['t1']),
        // Tuesday intentionally has no eligible tasks; no log required.
      };

      final streak = calculateCurrentStreak(
        today: today,
        tasks: [task],
        isDomainActive: (_) => true,
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
      );

      // Eligible days ending today: Wed (done), Mon (done) => streak = 2.
      expect(streak, 2);
    });

    test('Missed eligible day ends streak', () {
      final today = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(today);

      final task = Task(
        id: 't1',
        domainId: 'd1',
        title: 'Daily',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: start,
      );

      final tuesday = start.add(const Duration(days: 1));
      final wednesday = start.add(const Duration(days: 2));

      final logs = <String, DailyLog>{
        // Wednesday done.
        app_date_utils.DateUtils.getDateKey(wednesday): _log(wednesday, completed: const ['t1']),
        // Tuesday log exists but not completed => should break.
        app_date_utils.DateUtils.getDateKey(tuesday): _log(tuesday, completed: const []),
      };

      final streak = calculateCurrentStreak(
        today: today,
        tasks: [task],
        isDomainActive: (_) => true,
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
      );

      expect(streak, 1);
    });

    test('Grace qualifies an eligible day', () {
      final today = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(today);

      final task = Task(
        id: 't1',
        domainId: 'd1',
        title: 'Daily',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: start,
      );

      final tuesday = start.add(const Duration(days: 1));
      final wednesday = start.add(const Duration(days: 2));

      final logs = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(wednesday): _log(wednesday, completed: const ['t1']),
        app_date_utils.DateUtils.getDateKey(tuesday): _log(tuesday, grace: true),
      };

      final streak = calculateCurrentStreak(
        today: today,
        tasks: [task],
        isDomainActive: (_) => true,
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
      );

      expect(streak, 2);
    });
  });
}
