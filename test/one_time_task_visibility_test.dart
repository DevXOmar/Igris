import 'package:flutter_test/flutter_test.dart';

import 'package:igris/models/task.dart';
import 'package:igris/providers/task_provider.dart';

void main() {
  test('One-time task shows only on scheduled/created day', () {
    final day1 = DateTime(2026, 4, 1);
    final day2 = DateTime(2026, 4, 2);

    final task = Task(
      id: 'ot1',
      domainId: 'd1',
      title: 'One-time',
      isRecurring: false,
      createdAt: day1,
    );

    expect(isTaskActiveOnDate(task, day1), isTrue);
    expect(isTaskActiveOnDate(task, day2), isFalse);
  });

  test('One-time scheduledFor overrides createdAt', () {
    final created = DateTime(2026, 4, 1);
    final scheduled = DateTime(2026, 4, 3);

    final task = Task(
      id: 'ot2',
      domainId: 'd1',
      title: 'Scheduled one-time',
      isRecurring: false,
      createdAt: created,
      scheduledFor: scheduled,
    );

    expect(isTaskActiveOnDate(task, created), isFalse);
    expect(isTaskActiveOnDate(task, scheduled), isTrue);
  });

  test('Recurring task respects activeDays', () {
    final date = DateTime(2026, 4, 1);
    final weekdayIndex = date.weekday - 1; // Mon=0..Sun=6

    final task = Task(
      id: 'r1',
      domainId: 'd1',
      title: 'Recurring',
      isRecurring: true,
      activeDays: [weekdayIndex],
    );

    expect(isTaskActiveOnDate(task, date), isTrue);
    expect(isTaskActiveOnDate(task, date.add(const Duration(days: 1))), isFalse);
  });

  test('Recurring task is inactive before createdAt', () {
    final created = DateTime(2026, 4, 2);
    final dayBefore = DateTime(2026, 4, 1);

    final weekdayIndex = dayBefore.weekday - 1; // Mon=0..Sun=6
    final task = Task(
      id: 'r2',
      domainId: 'd1',
      title: 'Recurring created later',
      isRecurring: true,
      activeDays: [weekdayIndex],
      createdAt: created,
    );

    expect(isTaskActiveOnDate(task, dayBefore), isFalse);
  });
}
