import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';

void main() {
  group('date safety', () {
    test('BoardItem.isForDate normalizes UTC filter dates to local days', () {
      final offset = DateTime.now().timeZoneOffset;
      if (offset == Duration.zero) {
        return;
      }

      final localTargetDay = DateTime(2026, 6, 1);
      final localFilterInstant = offset.isNegative
          ? DateTime(2026, 6, 1, 23, 30)
          : localTargetDay;
      final utcFilterDate = localFilterInstant.toUtc();
      final utcScheduleStart = DateTime(2026, 6, 1, 12).toUtc();

      final item = BoardItem(
        id: 'schedule-utc',
        type: BoardItemType.schedule,
        title: 'Schedule',
        detail: '',
        owner: 'Mina',
        timeLabel: '12:00',
        startsAt: utcScheduleStart,
      );

      expect(utcFilterDate.toLocal().day, localTargetDay.day);
      expect(item.isForDate(utcFilterDate), isTrue);
    });
  });
}
