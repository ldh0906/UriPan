import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/screens/today_board_screen.dart';

void main() {
  group('startOfCalendarWeek (Sunday-first)', () {
    test('returns the Sunday on/before a weekday', () {
      // 2026-06-03 is a Wednesday; its week starts Sunday 2026-05-31.
      expect(
        startOfCalendarWeek(DateTime(2026, 6, 3, 9)),
        DateTime(2026, 5, 31),
      );
    });

    test('returns the same day for a Sunday', () {
      expect(
        startOfCalendarWeek(DateTime(2026, 6, 7, 14)),
        DateTime(2026, 6, 7),
      );
    });

    test('returns the previous Sunday for a Monday', () {
      expect(
        startOfCalendarWeek(DateTime(2026, 6, 8, 1)),
        DateTime(2026, 6, 7),
      );
    });

    test('normalizes UTC input before finding the local week start', () {
      // expected는 러너 타임존에 맞춰 동적 계산한다. 하드코딩하면 KST에서만
      // 통과하고 UTC CI 러너에서는 깨진다(2026-06-14 CI red 원인).
      final instant = DateTime.utc(2026, 6, 6, 15, 30);
      final local = instant.toLocal();
      final expected = DateTime(local.year, local.month, local.day)
          .subtract(Duration(days: local.weekday % 7));

      expect(startOfCalendarWeek(instant), expected);
    });
  });

  group('calendarWeekdayLabels', () {
    test('is Sunday-first (Sun..Sat)', () {
      expect(calendarWeekdayLabels, const ['일', '월', '화', '수', '목', '금', '토']);
    });
  });

  group('calendarWeekBars', () {
    final weekStart = DateTime(2026, 6, 1);

    test('renders a Sunday-to-Monday schedule as one contiguous bar', () {
      // Sunday-first week starting 2026-06-07; schedule spans Sun -> Mon.
      final segments = calendarWeekBars(
        schedules: [
          _schedule(
            id: 'sun-mon',
            startsAt: DateTime(2026, 6, 7, 9),
            dueAt: DateTime(2026, 6, 8, 18),
          ),
        ],
        weekStart: DateTime(2026, 6, 7),
      );

      expect(segments, hasLength(1));
      expect(segments.single.startColumn, 0);
      expect(segments.single.endColumn, 1);
      expect(segments.single.roundedLeft, isTrue);
      expect(segments.single.roundedRight, isTrue);
    });

    test('creates a rounded one-column segment for a single-day schedule', () {
      final segments = calendarWeekBars(
        schedules: [_schedule(id: 'single', startsAt: DateTime(2026, 6, 3, 9))],
        weekStart: weekStart,
      );

      expect(segments, hasLength(1));
      expect(segments.single.startColumn, 2);
      expect(segments.single.endColumn, 2);
      expect(segments.single.lane, 0);
      expect(segments.single.roundedLeft, isTrue);
      expect(segments.single.roundedRight, isTrue);
    });

    test(
      'creates one segment across columns for an in-week multiday schedule',
      () {
        final segments = calendarWeekBars(
          schedules: [
            _schedule(
              id: 'multi',
              startsAt: DateTime(2026, 6, 2, 9),
              dueAt: DateTime(2026, 6, 5, 18),
            ),
          ],
          weekStart: weekStart,
        );

        expect(segments, hasLength(1));
        expect(segments.single.startColumn, 1);
        expect(segments.single.endColumn, 4);
        expect(segments.single.roundedLeft, isTrue);
        expect(segments.single.roundedRight, isTrue);
      },
    );

    test('uses square ends where a schedule crosses the week boundary', () {
      final segments = calendarWeekBars(
        schedules: [
          _schedule(
            id: 'from-previous',
            startsAt: DateTime(2026, 5, 30, 9),
            dueAt: DateTime(2026, 6, 2, 18),
          ),
          _schedule(
            id: 'to-next',
            startsAt: DateTime(2026, 6, 6, 9),
            dueAt: DateTime(2026, 6, 9, 18),
          ),
        ],
        weekStart: weekStart,
      );

      expect(segments[0].startColumn, 0);
      expect(segments[0].endColumn, 1);
      expect(segments[0].roundedLeft, isFalse);
      expect(segments[0].roundedRight, isTrue);
      expect(segments[1].startColumn, 5);
      expect(segments[1].endColumn, 6);
      expect(segments[1].roundedLeft, isTrue);
      expect(segments[1].roundedRight, isFalse);
    });

    test('places overlapping schedules in separate lanes', () {
      final segments = calendarWeekBars(
        schedules: [
          _schedule(
            id: 'first',
            startsAt: DateTime(2026, 6, 1, 9),
            dueAt: DateTime(2026, 6, 3, 18),
          ),
          _schedule(
            id: 'second',
            startsAt: DateTime(2026, 6, 2, 9),
            dueAt: DateTime(2026, 6, 4, 18),
          ),
          _schedule(
            id: 'third',
            startsAt: DateTime(2026, 6, 4, 9),
            dueAt: DateTime(2026, 6, 5, 18),
          ),
        ],
        weekStart: weekStart,
      );

      expect(segments.map((segment) => segment.lane), [0, 1, 0]);
    });

    test('drops schedules that need more than three lanes', () {
      final segments = calendarWeekBars(
        schedules: [
          for (var index = 0; index < 4; index += 1)
            _schedule(
              id: 'overlap-$index',
              startsAt: DateTime(2026, 6, 2, 9 + index),
              dueAt: DateTime(2026, 6, 4, 18),
            ),
        ],
        weekStart: weekStart,
      );

      expect(segments, hasLength(3));
      expect(segments.map((segment) => segment.lane), [0, 1, 2]);
    });

    test('guards reversed end dates as a single-day schedule', () {
      final segments = calendarWeekBars(
        schedules: [
          _schedule(
            id: 'reversed',
            startsAt: DateTime(2026, 6, 4, 9),
            dueAt: DateTime(2026, 6, 2, 18),
          ),
        ],
        weekStart: weekStart,
      );

      expect(segments, hasLength(1));
      expect(segments.single.startColumn, 3);
      expect(segments.single.endColumn, 3);
      expect(segments.single.roundedLeft, isTrue);
      expect(segments.single.roundedRight, isTrue);
    });
  });
}

BoardItem _schedule({
  required String id,
  required DateTime startsAt,
  DateTime? dueAt,
}) {
  return BoardItem(
    id: id,
    type: BoardItemType.schedule,
    title: id,
    detail: '',
    owner: 'Us',
    timeLabel: '09:00',
    startsAt: startsAt,
    dueAt: dueAt,
  );
}
