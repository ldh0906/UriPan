import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/services/friendly_date.dart';

void main() {
  group('friendlyDayLabel', () {
    final now = DateTime(2026, 6, 2, 15, 30);

    test('returns null when the date is missing', () {
      expect(friendlyDayLabel(null, now: now), isNull);
    });

    test('labels today, tomorrow, and yesterday', () {
      expect(
        friendlyDayLabel(DateTime(2026, 6, 2, 9), now: now),
        '\uC624\uB298',
      );
      expect(
        friendlyDayLabel(DateTime(2026, 6, 3, 9), now: now),
        '\uB0B4\uC77C',
      );
      expect(
        friendlyDayLabel(DateTime(2026, 6, 1, 9), now: now),
        '\uC5B4\uC81C',
      );
    });

    test('labels upcoming days within six days by weekday', () {
      expect(
        friendlyDayLabel(DateTime(2026, 6, 4, 9), now: now),
        '\uBAA9\uC694\uC77C',
      );
      expect(
        friendlyDayLabel(DateTime(2026, 6, 8, 9), now: now),
        '\uC6D4\uC694\uC77C',
      );
    });

    test('labels past dates by elapsed days', () {
      expect(
        friendlyDayLabel(DateTime(2026, 5, 30, 9), now: now),
        '3\uC77C \uC9C0\uB0A8',
      );
    });

    test('labels later dates as month and day', () {
      expect(
        friendlyDayLabel(DateTime(2026, 6, 9, 9), now: now),
        '6\uC6D4 9\uC77C',
      );
    });
  });

  group('friendlyRelativeTime', () {
    final now = DateTime(2026, 6, 2, 15, 30);

    test('labels times under a minute as just now', () {
      expect(
        friendlyRelativeTime(DateTime(2026, 6, 2, 15, 29, 30), now: now),
        '\uBC29\uAE08',
      );
    });

    test('labels times under an hour in minutes', () {
      expect(
        friendlyRelativeTime(DateTime(2026, 6, 2, 15, 5), now: now),
        '25\uBD84 \uC804',
      );
    });

    test('labels times under a day in hours', () {
      expect(
        friendlyRelativeTime(DateTime(2026, 6, 2, 10, 0), now: now),
        '5\uC2DC\uAC04 \uC804',
      );
    });

    test('labels the previous local calendar day as yesterday', () {
      expect(
        friendlyRelativeTime(DateTime(2026, 6, 1, 8), now: now),
        '\uC5B4\uC81C',
      );
    });

    test('labels older dates as month dot day', () {
      expect(friendlyRelativeTime(DateTime(2026, 5, 31, 8), now: now), '5.31');
    });
  });
}
