class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ScheduledReminder &&
            other.id == id &&
            other.title == title &&
            other.body == body &&
            other.scheduledAt == scheduledAt;
  }

  @override
  int get hashCode => Object.hash(id, title, body, scheduledAt);
}

abstract class ReminderScheduler {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> sync(List<ScheduledReminder> reminders);
}

class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(List<ScheduledReminder> reminders) async {}
}
