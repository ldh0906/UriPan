import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/services/notifications/reminder_scheduler.dart';

void main() {
  test('ScheduledReminder compares by value', () {
    final scheduledAt = DateTime(2026, 6, 2, 9, 30);
    final first = ScheduledReminder(
      id: 7,
      title: 'title',
      body: 'body',
      scheduledAt: scheduledAt,
    );
    final second = ScheduledReminder(
      id: 7,
      title: 'title',
      body: 'body',
      scheduledAt: scheduledAt,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('NoopReminderScheduler completes without platform plugins', () async {
    final scheduler = NoopReminderScheduler();

    await scheduler.init();
    expect(await scheduler.requestPermission(), isFalse);
    await scheduler.sync([
      ScheduledReminder(
        id: 1,
        title: 'title',
        body: 'body',
        scheduledAt: DateTime(2026, 6, 2, 10),
      ),
    ]);
  });
}
