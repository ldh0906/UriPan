enum RecurrenceFrequency { daily, weekly, monthly }

extension RecurrenceFrequencyWire on RecurrenceFrequency {
  String get wireName {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'daily';
      case RecurrenceFrequency.weekly:
        return 'weekly';
      case RecurrenceFrequency.monthly:
        return 'monthly';
    }
  }

  static RecurrenceFrequency fromWireName(String value) {
    switch (value) {
      case 'daily':
        return RecurrenceFrequency.daily;
      case 'weekly':
        return RecurrenceFrequency.weekly;
      case 'monthly':
        return RecurrenceFrequency.monthly;
      default:
        throw ArgumentError.value(
          value,
          'value',
          'Unknown recurrence frequency',
        );
    }
  }
}

class RecurrenceRule {
  const RecurrenceRule({
    required this.frequency,
    required this.startsOn,
    required this.endsOn,
    required this.localTime,
  });

  final RecurrenceFrequency frequency;
  final DateTime startsOn;
  final DateTime endsOn;
  final Duration localTime;

  int get byWeekday => _dateOnly(startsOn).weekday;
  int get byMonthDay => _dateOnly(startsOn).day;
}

List<DateTime> recurrenceOccurrenceDates({
  required RecurrenceRule rule,
  required DateTime from,
  required DateTime through,
}) {
  final startsOn = _dateOnly(rule.startsOn);
  final endsOn = _dateOnly(rule.endsOn);
  final rangeStart = _maxDate(startsOn, _dateOnly(from));
  final rangeEnd = _minDate(endsOn, _dateOnly(through));
  if (rangeStart.isAfter(rangeEnd)) return const [];

  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      return _dailyOccurrenceDates(rangeStart, rangeEnd);
    case RecurrenceFrequency.weekly:
      return _weeklyOccurrenceDates(startsOn, rangeStart, rangeEnd);
    case RecurrenceFrequency.monthly:
      return _monthlyOccurrenceDates(startsOn, rangeStart, rangeEnd);
  }
}

String recurrenceSummaryText(RecurrenceRule rule) {
  final endsOn = _dateOnly(rule.endsOn);
  final endsText = '${endsOn.year}.${_twoDigits(endsOn.month)}.'
      '${_twoDigits(endsOn.day)}까지';
  switch (rule.frequency) {
    case RecurrenceFrequency.daily:
      return '매일, $endsText';
    case RecurrenceFrequency.weekly:
      return '매주 ${_koreanWeekday(rule.byWeekday)}, $endsText';
    case RecurrenceFrequency.monthly:
      return '매월 ${rule.byMonthDay}일(없는 달은 말일), $endsText';
  }
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<DateTime> _dailyOccurrenceDates(DateTime start, DateTime end) {
  final dates = <DateTime>[];
  for (
    var date = start;
    !date.isAfter(end);
    date = date.add(const Duration(days: 1))
  ) {
    dates.add(date);
  }
  return List.unmodifiable(dates);
}

List<DateTime> _weeklyOccurrenceDates(
  DateTime startsOn,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final offset = (rangeStart.weekday - startsOn.weekday) % 7;
  var date = rangeStart.add(Duration(days: offset == 0 ? 0 : 7 - offset));
  final sinceStart = date.difference(startsOn).inDays;
  if (sinceStart % 7 != 0) {
    date = date.add(Duration(days: 7 - (sinceStart % 7)));
  }

  final dates = <DateTime>[];
  for (; !date.isAfter(rangeEnd); date = date.add(const Duration(days: 7))) {
    dates.add(date);
  }
  return List.unmodifiable(dates);
}

List<DateTime> _monthlyOccurrenceDates(
  DateTime startsOn,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final dates = <DateTime>[];
  for (
    var month = DateTime(rangeStart.year, rangeStart.month);
    !month.isAfter(DateTime(rangeEnd.year, rangeEnd.month));
    month = DateTime(month.year, month.month + 1)
  ) {
    final day = _clampedDay(month.year, month.month, startsOn.day);
    final date = DateTime(month.year, month.month, day);
    if (!date.isBefore(rangeStart) && !date.isAfter(rangeEnd)) {
      dates.add(date);
    }
  }
  return List.unmodifiable(dates);
}

DateTime _maxDate(DateTime left, DateTime right) {
  return left.isAfter(right) ? left : right;
}

DateTime _minDate(DateTime left, DateTime right) {
  return left.isBefore(right) ? left : right;
}

int _clampedDay(int year, int month, int desiredDay) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return desiredDay > lastDay ? lastDay : desiredDay;
}

String _koreanWeekday(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '월요일';
    case DateTime.tuesday:
      return '화요일';
    case DateTime.wednesday:
      return '수요일';
    case DateTime.thursday:
      return '목요일';
    case DateTime.friday:
      return '금요일';
    case DateTime.saturday:
      return '토요일';
    case DateTime.sunday:
      return '일요일';
    default:
      throw ArgumentError.value(weekday, 'weekday', 'Invalid weekday');
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
