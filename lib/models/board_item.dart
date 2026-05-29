enum BoardItemType { schedule, task, notice }

extension BoardItemTypeWire on BoardItemType {
  String get wireName {
    switch (this) {
      case BoardItemType.schedule:
        return 'schedule';
      case BoardItemType.task:
        return 'task';
      case BoardItemType.notice:
        return 'notice';
    }
  }

  String get label {
    switch (this) {
      case BoardItemType.schedule:
        return '\uC77C\uC815';
      case BoardItemType.task:
        return '\uD560 \uC77C';
      case BoardItemType.notice:
        return '\uACF5\uC9C0';
    }
  }

  static BoardItemType fromWireName(String value) {
    switch (value) {
      case 'schedule':
        return BoardItemType.schedule;
      case 'task':
        return BoardItemType.task;
      case 'notice':
        return BoardItemType.notice;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown board item type');
    }
  }
}

class BoardItem {
  const BoardItem({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.owner,
    required this.timeLabel,
    this.startsAt,
    this.dueAt,
    this.isDone = false,
    this.isPinned = false,
  });

  final String id;
  final BoardItemType type;
  final String title;
  final String detail;
  final String owner;
  final String timeLabel;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final bool isDone;
  final bool isPinned;

  bool isForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    final value = type == BoardItemType.schedule ? startsAt : dueAt;
    if (value == null) return type == BoardItemType.notice;
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day) == target;
  }
}

class BoardSummary {
  const BoardSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.maxMembers,
    required this.memberCount,
  });

  final String id;
  final String name;
  final String role;
  final int maxMembers;
  final int memberCount;

  bool get isAdmin => role == 'admin';
}

class BoardInvite {
  const BoardInvite({
    required this.id,
    required this.code,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final DateTime expiresAt;
}

class BoardItemDraft {
  const BoardItemDraft({
    required this.type,
    required this.title,
    required this.detail,
    this.assignedTo,
    this.startsAt,
    this.dueAt,
    this.requiresConfirmation = false,
    this.isPinned = false,
  });

  final BoardItemType type;
  final String title;
  final String detail;
  final String? assignedTo;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final bool requiresConfirmation;
  final bool isPinned;
}
