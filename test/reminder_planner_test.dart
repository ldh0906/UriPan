import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/notifications/reminder_planner.dart';

void main() {
  final now = DateTime(2026, 6, 2, 9);

  group('buildReminderPlan tasks', () {
    test('reminds assigned task for current user only', () {
      final dueAt = DateTime(2026, 6, 2, 12);
      final plan = buildReminderPlan(
        items: [
          _task(
            id: 'mine',
            title: 'Buy milk',
            createdById: 'other',
            assignedToId: 'me',
            dueAt: dueAt,
          ),
          _task(
            id: 'theirs',
            title: 'Pay bill',
            createdById: 'other',
            assignedToId: 'someone-else',
            dueAt: dueAt,
          ),
        ],
        currentUserId: 'me',
        now: now,
      );

      expect(plan, hasLength(1));
      expect(plan.single.title, '\uD560 \uC77C');
      expect(plan.single.body, 'Buy milk');
      expect(
        plan.single.scheduledAt,
        dueAt.subtract(const Duration(minutes: 10)),
      );
    });

    test('reminds unassigned task created by current user only', () {
      final dueAt = DateTime(2026, 6, 2, 12);
      final plan = buildReminderPlan(
        items: [
          _task(
            id: 'created-by-me',
            title: 'Pack lunch',
            createdById: 'me',
            dueAt: dueAt,
          ),
          _task(
            id: 'created-by-other',
            title: 'Clean desk',
            createdById: 'someone-else',
            dueAt: dueAt,
          ),
        ],
        currentUserId: 'me',
        now: now,
      );

      expect(plan, hasLength(1));
      expect(plan.single.body, 'Pack lunch');
    });

    test('drops completed and past task reminders', () {
      final plan = buildReminderPlan(
        items: [
          _task(
            id: 'done',
            title: 'Done task',
            createdById: 'me',
            dueAt: DateTime(2026, 6, 2, 12),
            isDone: true,
          ),
          _task(
            id: 'past',
            title: 'Past task',
            createdById: 'me',
            dueAt: DateTime(2026, 6, 2, 9, 5),
          ),
        ],
        currentUserId: 'me',
        now: now,
      );

      expect(plan, isEmpty);
    });
  });

  group('buildReminderPlan schedules', () {
    test('creates a single one-hour-before reminder for a future schedule', () {
      final startsAt = DateTime(2026, 6, 2, 11);
      final plan = buildReminderPlan(
        items: [
          _schedule(id: 'schedule', title: 'Dentist', startsAt: startsAt),
        ],
        currentUserId: 'me',
        now: now,
      );

      expect(plan, hasLength(1));
      expect(plan.single.title, '\uC77C\uC815');
      expect(
        plan.single.scheduledAt,
        startsAt.subtract(const Duration(hours: 1)),
      );
      expect(plan.single.body, contains('Dentist'));
    });

    test('drops the schedule when one hour before is already past', () {
      final startsAt = DateTime(2026, 6, 2, 9, 30);
      final plan = buildReminderPlan(
        items: [
          _schedule(id: 'schedule', title: 'Breakfast', startsAt: startsAt),
        ],
        currentUserId: 'me',
        now: now,
      );

      expect(plan, isEmpty);
    });
  });

  test('disabled settings returns empty plan', () {
    final plan = buildReminderPlan(
      items: [
        _schedule(
          id: 'schedule',
          title: 'Dinner',
          startsAt: DateTime(2026, 6, 2, 11),
        ),
      ],
      currentUserId: 'me',
      now: now,
      settings: const ReminderSettings(enabled: false),
    );

    expect(plan, isEmpty);
  });

  test('maxCount caps reminders and keeps the soonest', () {
    final plan = buildReminderPlan(
      items: [
        _task(
          id: 'later',
          title: 'Later',
          createdById: 'me',
          dueAt: DateTime(2026, 6, 2, 13),
        ),
        _schedule(
          id: 'soon',
          title: 'Soon',
          startsAt: DateTime(2026, 6, 2, 11),
        ),
      ],
      currentUserId: 'me',
      now: now,
      maxCount: 2,
    );

    expect(plan, hasLength(2));
    expect(plan.map((reminder) => reminder.scheduledAt), [
      DateTime(2026, 6, 2, 10),
      DateTime(2026, 6, 2, 12, 50),
    ]);
  });

  test('drops reminders scheduled more than 30 days from now', () {
    final plan = buildReminderPlan(
      items: [
        _schedule(
          id: 'inside-window',
          title: 'Inside window',
          startsAt: now.add(const Duration(days: 30)),
        ),
        _schedule(
          id: 'outside-window',
          title: 'Outside window',
          startsAt: now.add(const Duration(days: 31, hours: 2)),
        ),
      ],
      currentUserId: 'me',
      now: now,
    );

    expect(plan, hasLength(1));
    expect(plan.single.body, contains('Inside window'));
  });

  test('stable ids repeat for the same logical reminders', () {
    final items = [
      _task(
        id: 'task',
        title: 'Task',
        createdById: 'me',
        dueAt: DateTime(2026, 6, 2, 12),
      ),
      _schedule(
        id: 'schedule',
        title: 'Schedule',
        startsAt: DateTime(2026, 6, 2, 11),
      ),
    ];

    final first = buildReminderPlan(
      items: items,
      currentUserId: 'me',
      now: now,
    );
    final second = buildReminderPlan(
      items: items,
      currentUserId: 'me',
      now: now,
    );

    expect(
      first.map((reminder) => reminder.id),
      second.map((reminder) => reminder.id),
    );
    expect(first.map((reminder) => reminder.id), everyElement(isNonNegative));
  });
}

BoardItem _task({
  required String id,
  required String title,
  required String createdById,
  required DateTime dueAt,
  String? assignedToId,
  bool isDone = false,
}) {
  return BoardItem(
    id: id,
    type: BoardItemType.task,
    title: title,
    detail: '',
    owner: 'Owner',
    createdById: createdById,
    assignedToId: assignedToId,
    timeLabel: '',
    dueAt: dueAt,
    isDone: isDone,
  );
}

BoardItem _schedule({
  required String id,
  required String title,
  required DateTime startsAt,
}) {
  return BoardItem(
    id: id,
    type: BoardItemType.schedule,
    title: title,
    detail: '',
    owner: 'Owner',
    timeLabel: '',
    startsAt: startsAt,
  );
}
