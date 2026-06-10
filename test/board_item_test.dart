import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_item_time_label.dart';

void main() {
  group('BoardItem.isForDate', () {
    test('matches every local day in a multiday schedule range', () {
      final item = BoardItem(
        id: 'schedule-1',
        type: BoardItemType.schedule,
        title: 'Trip',
        detail: '',
        owner: 'Mina',
        timeLabel: '09:00',
        startsAt: DateTime(2026, 6, 1, 9),
        dueAt: DateTime(2026, 6, 3, 18),
      );

      expect(item.isForDate(DateTime(2026, 6, 1)), isTrue);
      expect(item.isForDate(DateTime(2026, 6, 2)), isTrue);
      expect(item.isForDate(DateTime(2026, 6, 3)), isTrue);
      expect(item.isForDate(DateTime(2026, 5, 31)), isFalse);
      expect(item.isForDate(DateTime(2026, 6, 4)), isFalse);
    });

    test('treats an invalid schedule end as a single-day schedule', () {
      final item = BoardItem(
        id: 'schedule-1',
        type: BoardItemType.schedule,
        title: 'Trip',
        detail: '',
        owner: 'Mina',
        timeLabel: '09:00',
        startsAt: DateTime(2026, 6, 3, 9),
        dueAt: DateTime(2026, 6, 1, 18),
      );

      expect(item.isForDate(DateTime(2026, 6, 3)), isTrue);
      expect(item.isForDate(DateTime(2026, 6, 2)), isFalse);
    });

    test('keeps task and notice date behavior unchanged', () {
      final task = BoardItem(
        id: 'task-1',
        type: BoardItemType.task,
        title: 'Task',
        detail: '',
        owner: 'Mina',
        timeLabel: 'Today',
        dueAt: DateTime(2026, 6, 2, 18),
      );
      const notice = BoardItem(
        id: 'notice-1',
        type: BoardItemType.notice,
        title: 'Notice',
        detail: '',
        owner: 'Mina',
        timeLabel: 'Read',
      );

      expect(task.isForDate(DateTime(2026, 6, 2)), isTrue);
      expect(task.isForDate(DateTime(2026, 6, 3)), isFalse);
      expect(notice.isForDate(DateTime(2026, 6, 3)), isTrue);
    });
  });

  group('formatBoardItemTimeLabel', () {
    test('renders a start-end range for multiday schedules', () {
      final now = DateTime(2026, 6, 1, 8);

      expect(
        formatBoardItemTimeLabel(
          BoardItemType.schedule,
          startsAt: DateTime(2026, 6, 1, 9),
          dueAt: DateTime(2026, 6, 3, 18),
          now: now,
        ),
        '\uC624\uB298 09:00 - \uC218\uC694\uC77C 18:00',
      );
    });

    test('keeps a reversed schedule end as the start label', () {
      expect(
        formatBoardItemTimeLabel(
          BoardItemType.schedule,
          startsAt: DateTime(2026, 6, 3, 9),
          dueAt: DateTime(2026, 6, 1, 18),
          now: DateTime(2026, 6, 1),
        ),
        '\uC218\uC694\uC77C 09:00',
      );
    });
  });

  group('boardItemMatchesQuery', () {
    const item = BoardItem(
      id: 'item-1',
      type: BoardItemType.task,
      title: 'Buy milk',
      detail: 'Use the family card',
      owner: 'Nari',
      assigneeName: 'Dami',
      timeLabel: 'Today',
      tags: ['Errand', 'Kitchen'],
    );

    test('matches title case-insensitively', () {
      expect(boardItemMatchesQuery(item, 'MILK'), isTrue);
    });

    test('matches tags case-insensitively', () {
      expect(boardItemMatchesQuery(item, 'kitchen'), isTrue);
    });

    test('misses when no searchable field contains the query', () {
      expect(boardItemMatchesQuery(item, 'soccer'), isFalse);
    });

    test('empty query matches', () {
      expect(boardItemMatchesQuery(item, '   '), isTrue);
    });
  });
}
