// QA Track C-core / 2026-06-14: recurring item semantics must match server A2.
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/recurrence.dart';

void main() {
  group('QA recurrence pure functions', () {
    test('daily occurrences include start and end dates only', () {
      final dates = recurrenceOccurrenceDates(
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          startsOn: _date(2026, 6, 1),
          endsOn: _date(2026, 6, 3),
          localTime: const Duration(hours: 9),
        ),
        from: _date(2026, 6, 1),
        through: _date(2026, 6, 4),
      );

      expect(_dateKeys(dates), ['2026-06-01', '2026-06-02', '2026-06-03']);
    });

    test('weekly occurrences keep the start weekday and seven-day spacing', () {
      final dates = recurrenceOccurrenceDates(
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.weekly,
          startsOn: _date(2026, 6, 3), // Wednesday.
          endsOn: _date(2026, 6, 24),
          localTime: const Duration(hours: 9),
        ),
        from: _date(2026, 6, 1),
        through: _date(2026, 6, 24),
      );

      expect(_dateKeys(dates), [
        '2026-06-03',
        '2026-06-10',
        '2026-06-17',
        '2026-06-24',
      ]);
    });

    test('monthly day 31 clamps to the last day of each month', () {
      final dates = recurrenceOccurrenceDates(
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.monthly,
          startsOn: _date(2026, 1, 31),
          endsOn: _date(2026, 12, 31),
          localTime: const Duration(hours: 9),
        ),
        from: _date(2026, 1, 1),
        through: _date(2026, 12, 31),
      );

      expect(_dateKeys(dates), [
        '2026-01-31',
        '2026-02-28',
        '2026-03-31',
        '2026-04-30',
        '2026-05-31',
        '2026-06-30',
        '2026-07-31',
        '2026-08-31',
        '2026-09-30',
        '2026-10-31',
        '2026-11-30',
        '2026-12-31',
      ]);
    });

    test('monthly day 31 clamps February for leap and non-leap years', () {
      expect(
        _dateKeys(
          recurrenceOccurrenceDates(
            rule: RecurrenceRule(
              frequency: RecurrenceFrequency.monthly,
              startsOn: _date(2028, 1, 31),
              endsOn: _date(2028, 2, 29),
              localTime: const Duration(hours: 9),
            ),
            from: _date(2028, 2, 1),
            through: _date(2028, 2, 29),
          ),
        ),
        ['2028-02-29'],
      );
      expect(
        _dateKeys(
          recurrenceOccurrenceDates(
            rule: RecurrenceRule(
              frequency: RecurrenceFrequency.monthly,
              startsOn: _date(2027, 1, 31),
              endsOn: _date(2027, 2, 28),
              localTime: const Duration(hours: 9),
            ),
            from: _date(2027, 2, 1),
            through: _date(2027, 2, 28),
          ),
        ),
        ['2027-02-28'],
      );
    });

    test('end date boundary includes the same day and excludes later days', () {
      final rule = RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        startsOn: _date(2026, 6, 1),
        endsOn: _date(2026, 6, 3),
        localTime: const Duration(hours: 9),
      );

      expect(
        _dateKeys(
          recurrenceOccurrenceDates(
            rule: rule,
            from: _date(2026, 6, 3),
            through: _date(2026, 6, 4),
          ),
        ),
        ['2026-06-03'],
      );
      expect(
        recurrenceOccurrenceDates(
          rule: RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            startsOn: _date(2026, 6, 1),
            endsOn: _date(2026, 6, 1),
            localTime: const Duration(hours: 9),
          ),
          from: _date(2026, 6, 1),
          through: _date(2026, 6, 10),
        ),
        hasLength(1),
      );
    });

    test('from and through window clips occurrences after an old start date', () {
      final dates = recurrenceOccurrenceDates(
        rule: RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
          startsOn: _date(2026, 5, 28),
          endsOn: _date(2026, 6, 5),
          localTime: const Duration(hours: 9),
        ),
        from: _date(2026, 6, 2),
        through: _date(2026, 6, 4),
      );

      expect(_dateKeys(dates), ['2026-06-02', '2026-06-03', '2026-06-04']);
    });
  });

  group('QA recurrence summary text', () {
    test('summarizes daily, weekly, and monthly rules in Korean', () {
      expect(
        recurrenceSummaryText(
          RecurrenceRule(
            frequency: RecurrenceFrequency.daily,
            startsOn: _date(2026, 6, 1),
            endsOn: _date(2026, 6, 30),
            localTime: const Duration(hours: 9),
          ),
        ),
        '매일, 2026.06.30까지',
      );
      expect(
        recurrenceSummaryText(
          RecurrenceRule(
            frequency: RecurrenceFrequency.weekly,
            startsOn: _date(2026, 6, 3),
            endsOn: _date(2026, 7, 1),
            localTime: const Duration(hours: 9),
          ),
        ),
        '매주 수요일, 2026.07.01까지',
      );
      expect(
        recurrenceSummaryText(
          RecurrenceRule(
            frequency: RecurrenceFrequency.monthly,
            startsOn: _date(2026, 1, 31),
            endsOn: _date(2026, 12, 31),
            localTime: const Duration(hours: 9),
          ),
        ),
        '매월 31일(없는 달은 말일), 2026.12.31까지',
      );
    });
  });

  group('QA MemoryBoardRepository recurrence semantics', () {
    test('createRecurringItem materializes expected task occurrences undone', () async {
      final repository = MemoryBoardRepository([]);
      final today = _today();

      await repository.createRecurringItem(
        'memory-board',
        _taskDraft(
          title: 'Water plants',
          dueAt: _atHour(today, 9),
          recurrenceEndsOn: _offsetDate(today, 2),
        ),
      );

      final items = await repository.loadBoardItems(boardId: 'memory-board');

      expect(items, hasLength(3));
      expect(_dateKeys(items.map((item) => item.occurrenceLocalDate!)), [
        _dateKey(today),
        _dateKey(_offsetDate(today, 1)),
        _dateKey(_offsetDate(today, 2)),
      ]);
      expect(items.every((item) => item.recurrenceId != null), isTrue);
      expect(items.every((item) => item.isDone), isFalse);
    });

    test('completeTask only completes the selected occurrence', () async {
      final repository = MemoryBoardRepository([]);
      final today = _today();

      await repository.createRecurringItem(
        'memory-board',
        _taskDraft(
          title: 'Take vitamins',
          dueAt: _atHour(today, 9),
          recurrenceEndsOn: _offsetDate(today, 2),
        ),
      );
      final before = await repository.loadBoardItems(boardId: 'memory-board');

      await repository.completeTask(before.first.id, true);

      final after = await repository.loadBoardItems(boardId: 'memory-board');
      expect(after.where((item) => item.isDone), hasLength(1));
      expect(
        after.firstWhere((item) => item.id == before.first.id).isDone,
        isTrue,
      );
      expect(
        after
            .where((item) => item.id != before.first.id)
            .every((item) => !item.isDone),
        isTrue,
      );
    });

    test('updateRecurringSeries preserves past occurrences and regenerates future ones', () async {
      final repository = MemoryBoardRepository([]);
      final today = _today();

      await repository.createRecurringItem(
        'memory-board',
        _taskDraft(
          title: 'Old title',
          dueAt: _atHour(_offsetDate(today, -2), 9),
          recurrenceEndsOn: _offsetDate(today, 2),
        ),
      );
      final before = await repository.loadBoardItems(boardId: 'memory-board');
      final recurrenceId = before.singleWhere(
        (item) => _sameDate(item.occurrenceLocalDate!, today),
      ).recurrenceId!;

      await repository.updateRecurringSeries(
        recurrenceId,
        _taskDraft(
          title: 'New title',
          dueAt: _atHour(today, 10),
          recurrenceEndsOn: _offsetDate(today, 1),
        ),
      );

      final after = await repository.loadBoardItems(boardId: 'memory-board');
      final past = after.where(
        (item) => item.occurrenceLocalDate!.isBefore(today),
      );
      final future = after.where(
        (item) => !item.occurrenceLocalDate!.isBefore(today),
      );

      expect(past, hasLength(2));
      expect(past.every((item) => item.title == 'Old title'), isTrue);
      expect(_dateKeys(future.map((item) => item.occurrenceLocalDate!)), [
        _dateKey(today),
        _dateKey(_offsetDate(today, 1)),
      ]);
      expect(future.every((item) => item.title == 'New title'), isTrue);
      expect(after, hasLength(4));
    });

    test('createRecurringItem rejects notice type', () async {
      final repository = MemoryBoardRepository([]);

      expect(
        () => repository.createRecurringItem(
          'memory-board',
          BoardItemDraft(
            type: BoardItemType.notice,
            title: 'Notice',
            detail: '',
            recurrenceFrequency: RecurrenceFrequency.daily,
            recurrenceEndsOn: _today(),
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('recurring_type_not_supported'),
          ),
        ),
      );
    });
  });
}

BoardItemDraft _taskDraft({
  required String title,
  required DateTime dueAt,
  required DateTime recurrenceEndsOn,
}) {
  return BoardItemDraft(
    type: BoardItemType.task,
    title: title,
    detail: '',
    dueAt: dueAt,
    recurrenceFrequency: RecurrenceFrequency.daily,
    recurrenceEndsOn: recurrenceEndsOn,
  );
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _date(int year, int month, int day) => DateTime(year, month, day);

DateTime _offsetDate(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

DateTime _atHour(DateTime date, int hour) {
  return DateTime(date.year, date.month, date.day, hour);
}

List<String> _dateKeys(Iterable<DateTime> dates) => dates.map(_dateKey).toList();

String _dateKey(DateTime value) {
  final local = value.toLocal();
  final date = DateTime(local.year, local.month, local.day);
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

bool _sameDate(DateTime left, DateTime right) {
  return _dateKey(left) == _dateKey(right);
}
