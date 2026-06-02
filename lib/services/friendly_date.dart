String? friendlyDayLabel(DateTime? when, {DateTime? now}) {
  if (when == null) return null;

  final localWhen = when.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();
  final targetDay = DateTime(localWhen.year, localWhen.month, localWhen.day);
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final dayOffset = targetDay.difference(today).inDays;

  if (dayOffset == 0) return '\uC624\uB298';
  if (dayOffset == 1) return '\uB0B4\uC77C';
  if (dayOffset == -1) return '\uC5B4\uC81C';
  if (dayOffset > 1 && dayOffset <= 6) {
    return '${_weekdayLabels[targetDay.weekday]}\uC694\uC77C';
  }
  if (dayOffset < -1) return '${-dayOffset}\uC77C \uC9C0\uB0A8';

  return '${targetDay.month}\uC6D4 ${targetDay.day}\uC77C';
}

String friendlyRelativeTime(DateTime when, {DateTime? now}) {
  final localWhen = when.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();
  final elapsed = localNow.difference(localWhen);
  final seconds = elapsed.inSeconds;

  if (seconds < 60) return '\uBC29\uAE08';
  if (seconds < 60 * 60) return '${elapsed.inMinutes}\uBD84 \uC804';
  if (seconds < 24 * 60 * 60) return '${elapsed.inHours}\uC2DC\uAC04 \uC804';

  final targetDay = DateTime(localWhen.year, localWhen.month, localWhen.day);
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  if (targetDay == today.subtract(const Duration(days: 1))) {
    return '\uC5B4\uC81C';
  }

  return '${targetDay.month}.${targetDay.day}';
}

const _weekdayLabels = <int, String>{
  DateTime.monday: '\uC6D4',
  DateTime.tuesday: '\uD654',
  DateTime.wednesday: '\uC218',
  DateTime.thursday: '\uBAA9',
  DateTime.friday: '\uAE08',
  DateTime.saturday: '\uD1A0',
  DateTime.sunday: '\uC77C',
};
