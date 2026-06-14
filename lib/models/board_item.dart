import '../services/recurrence.dart';

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
    this.createdById,
    this.assignedToId,
    this.assigneeName,
    this.startsAt,
    this.dueAt,
    this.isDone = false,
    this.isPinned = false,
    this.requiresConfirmation = false,
    this.confirmationCount = 0,
    this.commentCount = 0,
    this.isConfirmedByMe = false,
    this.confirmedUserIds = const [],
    this.tags = const [],
    this.recurrenceId,
    this.occurrenceLocalDate,
  });

  static const Object _unset = Object();

  final String id;
  final BoardItemType type;
  final String title;
  final String detail;
  final String owner;
  final String? createdById;
  final String? assignedToId;
  final String? assigneeName;
  final String timeLabel;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final bool isDone;
  final bool isPinned;
  final bool requiresConfirmation;
  final int confirmationCount;
  final int commentCount;
  final bool isConfirmedByMe;
  final List<String> confirmedUserIds;
  final List<String> tags;
  final String? recurrenceId;
  final DateTime? occurrenceLocalDate;

  BoardItem copyWith({
    String? id,
    BoardItemType? type,
    String? title,
    String? detail,
    String? owner,
    Object? createdById = _unset,
    Object? assignedToId = _unset,
    Object? assigneeName = _unset,
    String? timeLabel,
    Object? startsAt = _unset,
    Object? dueAt = _unset,
    bool? isDone,
    bool? isPinned,
    bool? requiresConfirmation,
    int? confirmationCount,
    int? commentCount,
    bool? isConfirmedByMe,
    List<String>? confirmedUserIds,
    List<String>? tags,
    Object? recurrenceId = _unset,
    Object? occurrenceLocalDate = _unset,
  }) {
    return BoardItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      owner: owner ?? this.owner,
      createdById: createdById == _unset
          ? this.createdById
          : createdById as String?,
      assignedToId: assignedToId == _unset
          ? this.assignedToId
          : assignedToId as String?,
      assigneeName: assigneeName == _unset
          ? this.assigneeName
          : assigneeName as String?,
      timeLabel: timeLabel ?? this.timeLabel,
      startsAt: startsAt == _unset ? this.startsAt : startsAt as DateTime?,
      dueAt: dueAt == _unset ? this.dueAt : dueAt as DateTime?,
      isDone: isDone ?? this.isDone,
      isPinned: isPinned ?? this.isPinned,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      confirmationCount: confirmationCount ?? this.confirmationCount,
      commentCount: commentCount ?? this.commentCount,
      isConfirmedByMe: isConfirmedByMe ?? this.isConfirmedByMe,
      confirmedUserIds: confirmedUserIds ?? this.confirmedUserIds,
      tags: tags ?? this.tags,
      recurrenceId: recurrenceId == _unset
          ? this.recurrenceId
          : recurrenceId as String?,
      occurrenceLocalDate: occurrenceLocalDate == _unset
          ? this.occurrenceLocalDate
          : occurrenceLocalDate as DateTime?,
    );
  }

  bool isForDate(DateTime date) {
    final localDate = date.toLocal();
    final target = DateTime(localDate.year, localDate.month, localDate.day);
    if (type == BoardItemType.notice) return true;

    if (type == BoardItemType.task) {
      final value = dueAt;
      if (value == null) return false;
      final local = value.toLocal();
      return DateTime(local.year, local.month, local.day) == target;
    }

    final startValue = startsAt;
    if (startValue == null) return false;
    final localStart = startValue.toLocal();
    final start = DateTime(localStart.year, localStart.month, localStart.day);
    final endValue = dueAt ?? startsAt;
    final localEnd = endValue!.toLocal();
    final end = DateTime(localEnd.year, localEnd.month, localEnd.day);
    final effectiveEnd = end.isBefore(start) ? start : end;
    return !target.isBefore(start) && !target.isAfter(effectiveEnd);
  }
}

class BoardComment {
  const BoardComment({
    required this.id,
    required this.itemId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatarColor,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String itemId;
  final String authorId;
  final String authorName;
  final String authorAvatarColor;
  final String body;
  final DateTime createdAt;
}

bool boardItemMatchesQuery(BoardItem item, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  return item.title.toLowerCase().contains(normalizedQuery) ||
      item.detail.toLowerCase().contains(normalizedQuery) ||
      item.owner.toLowerCase().contains(normalizedQuery) ||
      (item.assigneeName?.toLowerCase().contains(normalizedQuery) ?? false) ||
      item.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
}

List<String> normalizeBoardItemTags(Iterable<String> rawTags) {
  final tags = <String>[];
  final seen = <String>{};
  for (final rawTag in rawTags) {
    final tag = rawTag.trim().replaceFirst(RegExp(r'^#+'), '');
    if (tag.isEmpty) continue;
    final normalized = tag.length > 12 ? tag.substring(0, 12) : tag;
    final key = normalized.toLowerCase();
    if (seen.add(key)) tags.add(normalized);
    if (tags.length == 5) break;
  }
  return List.unmodifiable(tags);
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

class BoardMember {
  const BoardMember({
    required this.userId,
    required this.displayName,
    required this.avatarColor,
    required this.role,
    required this.joinedAt,
    this.nickname,
  });

  final String userId;
  final String displayName;
  final String avatarColor;
  final String role;
  final DateTime joinedAt;
  final String? nickname;

  bool get isAdmin => role == 'admin';
  String get effectiveName {
    final value = nickname?.trim();
    return value == null || value.isEmpty ? displayName : value;
  }
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

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.avatarColor,
  });

  final String id;
  final String displayName;
  final String avatarColor;
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
    this.tags = const [],
    this.recurrenceFrequency,
    this.recurrenceEndsOn,
  });

  final BoardItemType type;
  final String title;
  final String detail;
  final String? assignedTo;
  final DateTime? startsAt;
  final DateTime? dueAt;
  final bool requiresConfirmation;
  final bool isPinned;
  final List<String> tags;
  final RecurrenceFrequency? recurrenceFrequency;
  final DateTime? recurrenceEndsOn;
}
