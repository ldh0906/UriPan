import '../models/board_item.dart';
import 'friendly_date.dart';

enum BoardItemTimeLabelStyle { card, detail, compact }

String? formatBoardItemTimeLabel(
  BoardItemType type, {
  DateTime? startsAt,
  DateTime? dueAt,
  DateTime? now,
  BoardItemTimeLabelStyle style = BoardItemTimeLabelStyle.card,
}) {
  final value = type == BoardItemType.schedule ? startsAt : dueAt;
  if (value == null) return null;

  if (type == BoardItemType.schedule) {
    final end = dueAt;
    if (end != null && end.isAfter(value)) {
      return '${_formatEndpoint(value, now: now, style: style)} - '
          '${_formatEndpoint(end, now: now, style: style)}';
    }
  }

  return _formatEndpoint(value, now: now, style: style);
}

String _formatEndpoint(
  DateTime value, {
  required DateTime? now,
  required BoardItemTimeLabelStyle style,
}) {
  final local = value.toLocal();
  final time = _isMidnight(local)
      ? ''
      : '${_two(local.hour)}:${_two(local.minute)}';

  switch (style) {
    case BoardItemTimeLabelStyle.card:
      final day = friendlyDayLabel(value, now: now) ?? '';
      return [day, time].where((part) => part.isNotEmpty).join(' ');
    case BoardItemTimeLabelStyle.detail:
      final dateLabel = '${local.year}.${_two(local.month)}.${_two(local.day)}';
      final absoluteLabel = time.isEmpty ? dateLabel : '$dateLabel $time';
      final friendlyLabel = friendlyDayLabel(value, now: now);
      return friendlyLabel == null
          ? absoluteLabel
          : '$friendlyLabel \u00B7 $absoluteLabel';
    case BoardItemTimeLabelStyle.compact:
      if (time.isNotEmpty) return time;
      return '${local.month}/${local.day}';
  }
}

bool _isMidnight(DateTime value) => value.hour == 0 && value.minute == 0;

String _two(int value) => value.toString().padLeft(2, '0');
