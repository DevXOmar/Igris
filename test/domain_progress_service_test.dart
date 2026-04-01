import 'package:flutter_test/flutter_test.dart';

import 'package:igris/core/utils/date_utils.dart' as app_date_utils;
import 'package:igris/models/daily_log.dart';
import 'package:igris/models/domain.dart';
import 'package:igris/models/task.dart';
import 'package:igris/services/domain_progress_service.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

DailyLog _log(DateTime date, List<String> completed) => DailyLog(
      date: date,
      completedTaskIds: completed,
    );

void main() {
  group('DomainProgressService', () {
    test('Daily recurring task grows evenly across week', () {
      // Week of 2026-03-16 is Monday.
      final now = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(now);

      final domain = Domain(id: 'd1', name: 'Health');
      final task = Task(
        id: 't1',
        domainId: domain.id,
        title: 'Run',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
      );

      final logs = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(start): _log(start, ['t1']), // Mon done
        app_date_utils.DateUtils.getDateKey(start.add(const Duration(days: 1))):
            _log(start.add(const Duration(days: 1)), ['t1']), // Tue done
      };

      final svc = DomainProgressService(
        tasks: [task],
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      // Expected so far (Mon..Wed) = 3 occurrences, completed = 2
      expect(svc.getExpectedOccurrences(task, now), 3);
      expect(svc.getCompletedOccurrences(task, now), 2);
      expect(svc.calculateDomainProgress(domain), closeTo(2 / 3, 0.0001));
    });

    test('Task only on Saturday is 0% before Saturday and 100% after completion', () {
      final domain = Domain(id: 'd1', name: 'Study');
      final task = Task(
        id: 't1',
        domainId: domain.id,
        title: 'Mock exam',
        isRecurring: true,
        activeDays: const [5], // Saturday (Mon=0)
      );

      // Wednesday
      final nowWed = _d(2026, 3, 18);
      final svcWed = DomainProgressService(
        tasks: [task],
        getLogForDate: (_) => null,
        now: nowWed,
      );
      expect(svcWed.getExpectedOccurrences(task, nowWed), 0);
      expect(svcWed.calculateDomainProgress(domain), 0.0);

      // Saturday with completion
      final nowSat = _d(2026, 3, 21);
      final start = app_date_utils.DateUtils.getStartOfWeek(nowSat);
      final logs = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(start.add(const Duration(days: 5))):
            _log(start.add(const Duration(days: 5)), ['t1']),
      };
      final svcSat = DomainProgressService(
        tasks: [task],
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
        now: nowSat,
      );
      expect(svcSat.getExpectedOccurrences(task, nowSat), 1);
      expect(svcSat.getCompletedOccurrences(task, nowSat), 1);
      expect(svcSat.calculateDomainProgress(domain), 1.0);
    });

    test('Mix of recurring + one-time aggregates correctly', () {
      final domain = Domain(id: 'd1', name: 'Work');
      final now = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(now);

      final recurring = Task(
        id: 'r1',
        domainId: domain.id,
        title: 'Deep work',
        isRecurring: true,
        activeDays: const [0, 2, 4],
      );
      final oneTime = Task(
        id: 'o1',
        domainId: domain.id,
        title: 'Send report',
        isRecurring: false,
        createdAt: now,
        scheduledFor: now,
      );

      final logs = <String, DailyLog>{
        // Monday: deep work done
        app_date_utils.DateUtils.getDateKey(start): _log(start, ['r1']),
        // Wednesday: one-time done
        app_date_utils.DateUtils.getDateKey(now): _log(now, ['o1']),
      };

      final svc = DomainProgressService(
        tasks: [recurring, oneTime],
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      // Expected so far:
      // recurring active (Mon, Wed) = 2, one-time scheduled today = 1 => 3
      // Completed so far: recurring Mon = 1, one-time today = 1 => 2
      expect(svc.calculateDomainProgress(domain), closeTo(2 / 3, 0.0001));
    });

    test('Adding a one-time task mid-week increases expected immediately', () {
      final domain = Domain(id: 'd1', name: 'Learn');
      final now = _d(2026, 3, 18); // Wednesday

      final baseRecurring = Task(
        id: 'r1',
        domainId: domain.id,
        title: 'Read',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
      );

      final logs = <String, DailyLog>{};

      final before = DomainProgressService(
        tasks: [baseRecurring],
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      final midWeekOneTime = Task(
        id: 'o1',
        domainId: domain.id,
        title: 'Finish chapter',
        isRecurring: false,
        createdAt: now,
      );

      final after = DomainProgressService(
        tasks: [baseRecurring, midWeekOneTime],
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      // Before: expected = 3 (Mon..Wed)
      expect(before.getExpectedOccurrences(baseRecurring, now), 3);
      // After: expected includes one-time (+1)
      expect(after.calculateDomainProgress(domain), 0.0);
      expect(
        after.getExpectedOccurrences(baseRecurring, now) +
            after.getExpectedOccurrences(midWeekOneTime, now),
        4,
      );
    });

    test('Undo completion decreases progress', () {
      final domain = Domain(id: 'd1', name: 'Fitness');
      final now = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(now);

      final task = Task(
        id: 't1',
        domainId: domain.id,
        title: 'Workout',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
      );

      final logsDone = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(start): _log(start, ['t1']),
        app_date_utils.DateUtils.getDateKey(start.add(const Duration(days: 1))):
            _log(start.add(const Duration(days: 1)), ['t1']),
      };

      final svcDone = DomainProgressService(
        tasks: [task],
        getLogForDate: (date) => logsDone[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      final progressDone = svcDone.calculateDomainProgress(domain);
      expect(progressDone, closeTo(2 / 3, 0.0001));

      // Undo Tuesday completion
      final logsUndone = <String, DailyLog>{
        app_date_utils.DateUtils.getDateKey(start): _log(start, ['t1']),
        app_date_utils.DateUtils.getDateKey(start.add(const Duration(days: 1))):
            _log(start.add(const Duration(days: 1)), []),
      };

      final svcUndone = DomainProgressService(
        tasks: [task],
        getLogForDate: (date) => logsUndone[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      final progressUndone = svcUndone.calculateDomainProgress(domain);
      expect(progressUndone, closeTo(1 / 3, 0.0001));
      expect(progressUndone, lessThan(progressDone));
    });

    test('Recurring task expected occurrences start from createdAt', () {
      // Week of 2026-03-16 is Monday.
      final now = _d(2026, 3, 20); // Friday
      final start = app_date_utils.DateUtils.getStartOfWeek(now);

      final domain = Domain(id: 'd1', name: 'Health');
      final createdAt = start.add(const Duration(days: 2)); // Wednesday
      final task = Task(
        id: 't1',
        domainId: domain.id,
        title: 'Run',
        isRecurring: true,
        // Daily recurring
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: createdAt,
      );

      final logs = <String, DailyLog>{
        // Completed only on Wednesday.
        app_date_utils.DateUtils.getDateKey(createdAt): _log(createdAt, ['t1']),
      };

      final svc = DomainProgressService(
        tasks: [task],
        getLogForDate: (date) => logs[app_date_utils.DateUtils.getDateKey(date)],
        now: now,
      );

      // Expected so far should be Wed..Fri = 3, not Mon..Fri = 5.
      expect(svc.getExpectedOccurrences(task, now), 3);
      expect(svc.getCompletedOccurrences(task, now), 1);
      expect(svc.calculateDomainProgress(domain), closeTo(1 / 3, 0.0001));
    });

    test('Recurring task created after today has 0 expected/completed', () {
      final now = _d(2026, 3, 18); // Wednesday
      final start = app_date_utils.DateUtils.getStartOfWeek(now);
      final domain = Domain(id: 'd1', name: 'Work');

      final createdAt = start.add(const Duration(days: 4)); // Friday
      final task = Task(
        id: 't1',
        domainId: domain.id,
        title: 'Deep work',
        isRecurring: true,
        activeDays: const [0, 1, 2, 3, 4, 5, 6],
        createdAt: createdAt,
      );

      final svc = DomainProgressService(
        tasks: [task],
        getLogForDate: (_) => null,
        now: now,
      );

      expect(svc.getExpectedOccurrences(task, now), 0);
      expect(svc.getCompletedOccurrences(task, now), 0);
      expect(svc.calculateDomainProgress(domain), 0.0);
    });
  });
}
