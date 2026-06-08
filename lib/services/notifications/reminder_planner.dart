import '../../models/board_item.dart';
import '../friendly_date.dart';
import 'reminder_scheduler.dart';

class ReminderSettings {
  const ReminderSettings({this.enabled = true});

  final bool enabled;
}

List<ScheduledReminder> buildReminderPlan({
  required List<BoardItem> items,
  required String? currentUserId,
  required DateTime now,
  ReminderSettings settings = const ReminderSettings(),
  int maxCount = 60,
}) {
  if (!settings.enabled || maxCount <= 0) return const [];

  final candidates = <ScheduledReminder>[];
  for (final item in items) {
    switch (item.type) {
      case BoardItemType.schedule:
        final startsAt = item.startsAt;
        if (startsAt == null) continue;

        // One reminder per schedule: one hour before the start.
        candidates.add(
          _scheduleReminder(
            item: item,
            kind: 'pre',
            scheduledAt: startsAt.subtract(const Duration(hours: 1)),
            now: now,
          ),
        );
      case BoardItemType.task:
        final dueAt = item.dueAt;
        if (dueAt == null ||
            item.isDone ||
            !_isTaskForCurrentUser(item, currentUserId)) {
          continue;
        }

        candidates.add(
          ScheduledReminder(
            id: _stableReminderId(item, 'due'),
            title: '\uD560 \uC77C',
            body: item.title,
            scheduledAt: dueAt.subtract(const Duration(minutes: 10)),
          ),
        );
      case BoardItemType.notice:
        break;
    }
  }

  final maxScheduledAt = now.add(const Duration(days: 30));
  final futureReminders =
      candidates
          .where(
            (reminder) =>
                reminder.scheduledAt.isAfter(now) &&
                !reminder.scheduledAt.isAfter(maxScheduledAt),
          )
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return futureReminders.take(maxCount).toList();
}

ScheduledReminder _scheduleReminder({
  required BoardItem item,
  required String kind,
  required DateTime scheduledAt,
  required DateTime now,
}) {
  final timeLabel = _friendlyScheduleTime(item.startsAt, now: now);
  final body = timeLabel == null ? item.title : '${item.title} - $timeLabel';
  return ScheduledReminder(
    id: _stableReminderId(item, kind),
    title: '\uC77C\uC815',
    body: body,
    scheduledAt: scheduledAt,
  );
}

bool _isTaskForCurrentUser(BoardItem item, String? currentUserId) {
  if (currentUserId == null) return false;
  return item.assignedToId == currentUserId ||
      (item.assignedToId == null && item.createdById == currentUserId);
}

String? _friendlyScheduleTime(DateTime? when, {required DateTime now}) {
  if (when == null) return null;

  final local = when.toLocal();
  final dayLabel = friendlyDayLabel(local, now: now) ?? '';
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return dayLabel.isEmpty ? '$hour:$minute' : '$dayLabel $hour:$minute';
}

// A logical reminder keeps the same non-negative id as long as its item id and
// reminder kind are unchanged, so scheduler syncs can replace/cancel reliably.
int _stableReminderId(BoardItem item, String kind) {
  return '${item.id}:$kind'.hashCode & 0x7fffffff;
}
