import 'package:flutter/material.dart';

enum BoardItemType { schedule, task, notice }

const Object _unset = Object();

Color _colorFromJson(Object? value, Color fallback) {
  if (value is int) {
    return Color(value);
  }
  return fallback;
}

int _colorToJson(Color color) => color.toARGB32();

List<T> _typedList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) parser,
) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => parser(Map<String, dynamic>.from(item)))
      .toList();
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.initials,
    required this.color,
    this.keepLoggedIn = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '김지훈',
      email: json['email'] as String? ?? 'john.doe@example.com',
      initials: json['initials'] as String? ?? 'JD',
      color: _colorFromJson(json['color'], const Color(0xFF647D31)),
      keepLoggedIn: json['keepLoggedIn'] as bool? ?? true,
    );
  }

  final String name;
  final String email;
  final String initials;
  final Color color;
  final bool keepLoggedIn;

  UserProfile copyWith({
    String? name,
    String? email,
    String? initials,
    Color? color,
    bool? keepLoggedIn,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      initials: initials ?? this.initials,
      color: color ?? this.color,
      keepLoggedIn: keepLoggedIn ?? this.keepLoggedIn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'initials': initials,
      'color': _colorToJson(color),
      'keepLoggedIn': keepLoggedIn,
    };
  }
}

class BoardSettings {
  const BoardSettings({
    this.notificationsEnabled = true,
    this.autoArchiveCompletedTasks = false,
    this.requireNoticeConfirmation = true,
  });

  factory BoardSettings.fromJson(Map<String, dynamic> json) {
    return BoardSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      autoArchiveCompletedTasks:
          json['autoArchiveCompletedTasks'] as bool? ?? false,
      requireNoticeConfirmation:
          json['requireNoticeConfirmation'] as bool? ?? true,
    );
  }

  final bool notificationsEnabled;
  final bool autoArchiveCompletedTasks;
  final bool requireNoticeConfirmation;

  BoardSettings copyWith({
    bool? notificationsEnabled,
    bool? autoArchiveCompletedTasks,
    bool? requireNoticeConfirmation,
  }) {
    return BoardSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoArchiveCompletedTasks:
          autoArchiveCompletedTasks ?? this.autoArchiveCompletedTasks,
      requireNoticeConfirmation:
          requireNoticeConfirmation ?? this.requireNoticeConfirmation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'autoArchiveCompletedTasks': autoArchiveCompletedTasks,
      'requireNoticeConfirmation': requireNoticeConfirmation,
    };
  }
}

class AppSnapshot {
  const AppSnapshot({
    required this.user,
    required this.boards,
    this.activeInviteCode,
    this.isAuthenticated = false,
  });

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    return AppSnapshot(
      user: UserProfile.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
      boards: _typedList(json['boards'], BoardWorkspace.fromJson),
      activeInviteCode: json['activeInviteCode'] as String?,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
    );
  }

  final UserProfile user;
  final List<BoardWorkspace> boards;
  final String? activeInviteCode;
  final bool isAuthenticated;

  AppSnapshot copyWith({
    UserProfile? user,
    List<BoardWorkspace>? boards,
    Object? activeInviteCode = _unset,
    bool? isAuthenticated,
  }) {
    return AppSnapshot(
      user: user ?? this.user,
      boards: boards ?? this.boards,
      activeInviteCode: activeInviteCode == _unset
          ? this.activeInviteCode
          : activeInviteCode as String?,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'boards': boards.map((board) => board.toJson()).toList(),
      'activeInviteCode': activeInviteCode,
      'isAuthenticated': isAuthenticated,
    };
  }
}

class BoardItemDraft {
  const BoardItemDraft({
    this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.assignee,
    required this.initials,
    required this.color,
    required this.isImportant,
    required this.requiresConfirmation,
    required this.isCompleted,
    this.notes,
  });

  final String? id;
  final BoardItemType type;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String assignee;
  final String initials;
  final Color color;
  final bool isImportant;
  final bool requiresConfirmation;
  final bool isCompleted;
  final String? notes;
}

class BoardItemEditArguments {
  const BoardItemEditArguments({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.assignee,
    required this.initials,
    required this.color,
    required this.isImportant,
    required this.requiresConfirmation,
    required this.isCompleted,
    this.notes,
  });

  factory BoardItemEditArguments.fromSchedule(ScheduleItemData item) {
    return BoardItemEditArguments(
      id: item.id,
      type: BoardItemType.schedule,
      title: item.title,
      date: item.date,
      startTime: item.start,
      endTime: item.end,
      assignee: item.initials,
      initials: item.initials,
      color: item.color,
      isImportant: false,
      requiresConfirmation: false,
      isCompleted: false,
    );
  }

  factory BoardItemEditArguments.fromTask(TaskItemData item) {
    return BoardItemEditArguments(
      id: item.id,
      type: BoardItemType.task,
      title: item.title,
      date: item.dueDate,
      startTime: '',
      endTime: '',
      assignee: item.assignee,
      initials: item.initials,
      color: item.color,
      isImportant: false,
      requiresConfirmation: false,
      isCompleted: item.isDone,
      notes: item.memo,
    );
  }

  factory BoardItemEditArguments.fromNotice(NoticeItemData item) {
    return BoardItemEditArguments(
      id: item.id,
      type: BoardItemType.notice,
      title: item.title,
      date: item.date,
      startTime: '',
      endTime: '',
      assignee: '모두',
      initials: '전체',
      color: Colors.transparent,
      isImportant: item.isImportant,
      requiresConfirmation: !item.confirmedByMe,
      isCompleted: false,
      notes: item.preview,
    );
  }

  final String id;
  final BoardItemType type;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String assignee;
  final String initials;
  final Color color;
  final bool isImportant;
  final bool requiresConfirmation;
  final bool isCompleted;
  final String? notes;
}

class FamilyMember {
  const FamilyMember({
    required this.name,
    required this.initials,
    required this.role,
    required this.color,
  });

  final String name;
  final String initials;
  final String role;
  final Color color;

  FamilyMember copyWith({String? role}) {
    return FamilyMember(
      name: name,
      initials: initials,
      role: role ?? this.role,
      color: color,
    );
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      name: json['name'] as String? ?? '멤버',
      initials: json['initials'] as String? ?? 'ME',
      role: json['role'] as String? ?? '멤버',
      color: _colorFromJson(json['color'], Colors.blue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'initials': initials,
      'role': role,
      'color': _colorToJson(color),
    };
  }
}

class BoardData {
  const BoardData({
    required this.name,
    required this.role,
    required this.members,
    required this.schedules,
    required this.tasks,
    required this.notices,
  });

  final String name;
  final String role;
  final String members;
  final String schedules;
  final String tasks;
  final String notices;

  BoardData copyWith({
    String? name,
    String? role,
    String? members,
    String? schedules,
    String? tasks,
    String? notices,
  }) {
    return BoardData(
      name: name ?? this.name,
      role: role ?? this.role,
      members: members ?? this.members,
      schedules: schedules ?? this.schedules,
      tasks: tasks ?? this.tasks,
      notices: notices ?? this.notices,
    );
  }

  factory BoardData.fromJson(Map<String, dynamic> json) {
    return BoardData(
      name: json['name'] as String? ?? '이름 없는 보드',
      role: json['role'] as String? ?? '멤버',
      members: json['members'] as String? ?? '0',
      schedules: json['schedules'] as String? ?? '아직 일정 없음',
      tasks: json['tasks'] as String? ?? '아직 할 일 없음',
      notices: json['notices'] as String? ?? '공지 없음',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'role': role,
      'members': members,
      'schedules': schedules,
      'tasks': tasks,
      'notices': notices,
    };
  }
}

class BoardWorkspace {
  const BoardWorkspace({
    required this.board,
    required this.inviteCode,
    required this.members,
    required this.schedules,
    required this.tasks,
    required this.notices,
    this.settings = const BoardSettings(),
  });

  factory BoardWorkspace.fromJson(Map<String, dynamic> json) {
    return BoardWorkspace(
      board: BoardData.fromJson(
        Map<String, dynamic>.from(json['board'] as Map? ?? const {}),
      ),
      inviteCode: json['inviteCode'] as String? ?? 'URIPAN-2024',
      members: _typedList(json['members'], FamilyMember.fromJson),
      schedules: _typedList(json['schedules'], ScheduleItemData.fromJson),
      tasks: _typedList(json['tasks'], TaskItemData.fromJson),
      notices: _typedList(json['notices'], NoticeItemData.fromJson),
      settings: BoardSettings.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
      ),
    );
  }

  final BoardData board;
  final String inviteCode;
  final List<FamilyMember> members;
  final List<ScheduleItemData> schedules;
  final List<TaskItemData> tasks;
  final List<NoticeItemData> notices;
  final BoardSettings settings;

  BoardWorkspace copyWith({
    BoardData? board,
    String? inviteCode,
    List<FamilyMember>? members,
    List<ScheduleItemData>? schedules,
    List<TaskItemData>? tasks,
    List<NoticeItemData>? notices,
    BoardSettings? settings,
  }) {
    return BoardWorkspace(
      board: board ?? this.board,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      schedules: schedules ?? this.schedules,
      tasks: tasks ?? this.tasks,
      notices: notices ?? this.notices,
      settings: settings ?? this.settings,
    );
  }

  BoardWorkspace withSyncedSummary() {
    final remainingTasks = tasks.where((task) => !task.isDone).length;
    final unreadNotices =
        notices.where((notice) => !notice.confirmedByMe).length;

    return copyWith(
      board: board.copyWith(
        members: '${members.length}',
        schedules:
            schedules.isEmpty ? '아직 일정 없음' : '일정 ${schedules.length}개 예정',
        tasks: remainingTasks == 0 ? '남은 할 일 없음' : '남은 할 일 $remainingTasks개',
        notices: unreadNotices == 0 ? '새 공지 없음' : '새 공지 $unreadNotices개',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'board': board.toJson(),
      'inviteCode': inviteCode,
      'members': members.map((member) => member.toJson()).toList(),
      'schedules': schedules.map((item) => item.toJson()).toList(),
      'tasks': tasks.map((item) => item.toJson()).toList(),
      'notices': notices.map((item) => item.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }
}

class ScheduleItemData {
  const ScheduleItemData({
    required this.id,
    required this.title,
    required this.initials,
    required this.date,
    required this.start,
    required this.end,
    required this.color,
  });

  final String id;
  final String title;
  final String initials;
  final String date;
  final String start;
  final String end;
  final Color color;

  String get timeRange => '$start - $end';

  ScheduleItemData copyWith({
    String? title,
    String? initials,
    String? date,
    String? start,
    String? end,
    Color? color,
  }) {
    return ScheduleItemData(
      id: id,
      title: title ?? this.title,
      initials: initials ?? this.initials,
      date: date ?? this.date,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
    );
  }

  factory ScheduleItemData.fromJson(Map<String, dynamic> json) {
    return ScheduleItemData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      initials: json['initials'] as String? ?? 'ME',
      date: json['date'] as String? ?? '',
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      color: _colorFromJson(json['color'], Colors.blue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'initials': initials,
      'date': date,
      'start': start,
      'end': end,
      'color': _colorToJson(color),
    };
  }
}

class TaskItemData {
  const TaskItemData({
    required this.id,
    required this.title,
    required this.assignee,
    required this.initials,
    required this.dueDate,
    required this.color,
    required this.isDone,
    this.memo,
  });

  final String id;
  final String title;
  final String assignee;
  final String initials;
  final String dueDate;
  final Color color;
  final bool isDone;
  final String? memo;

  TaskItemData copyWith({
    String? title,
    String? assignee,
    String? initials,
    String? dueDate,
    Color? color,
    bool? isDone,
    String? memo,
  }) {
    return TaskItemData(
      id: id,
      title: title ?? this.title,
      assignee: assignee ?? this.assignee,
      initials: initials ?? this.initials,
      dueDate: dueDate ?? this.dueDate,
      color: color ?? this.color,
      isDone: isDone ?? this.isDone,
      memo: memo ?? this.memo,
    );
  }

  factory TaskItemData.fromJson(Map<String, dynamic> json) {
    return TaskItemData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      assignee: json['assignee'] as String? ?? '나',
      initials: json['initials'] as String? ?? 'ME',
      dueDate: json['dueDate'] as String? ?? '',
      color: _colorFromJson(json['color'], Colors.blue),
      isDone: json['isDone'] as bool? ?? false,
      memo: json['memo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'assignee': assignee,
      'initials': initials,
      'dueDate': dueDate,
      'color': _colorToJson(color),
      'isDone': isDone,
      'memo': memo,
    };
  }
}

class NoticeItemData {
  const NoticeItemData({
    required this.id,
    required this.title,
    required this.preview,
    required this.date,
    required this.isImportant,
    required this.confirmedByMe,
    required this.confirmedCount,
    required this.confirmedInitials,
  });

  final String id;
  final String title;
  final String preview;
  final String date;
  final bool isImportant;
  final bool confirmedByMe;
  final int confirmedCount;
  final List<String> confirmedInitials;

  NoticeItemData copyWith({
    String? title,
    String? preview,
    String? date,
    bool? isImportant,
    bool? confirmedByMe,
    int? confirmedCount,
    List<String>? confirmedInitials,
  }) {
    return NoticeItemData(
      id: id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      date: date ?? this.date,
      isImportant: isImportant ?? this.isImportant,
      confirmedByMe: confirmedByMe ?? this.confirmedByMe,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      confirmedInitials: confirmedInitials ?? this.confirmedInitials,
    );
  }

  factory NoticeItemData.fromJson(Map<String, dynamic> json) {
    return NoticeItemData(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      preview: json['preview'] as String? ?? '',
      date: json['date'] as String? ?? '',
      isImportant: json['isImportant'] as bool? ?? false,
      confirmedByMe: json['confirmedByMe'] as bool? ?? false,
      confirmedCount: json['confirmedCount'] as int? ?? 0,
      confirmedInitials:
          (json['confirmedInitials'] as List?)?.whereType<String>().toList() ??
              const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'preview': preview,
      'date': date,
      'isImportant': isImportant,
      'confirmedByMe': confirmedByMe,
      'confirmedCount': confirmedCount,
      'confirmedInitials': confirmedInitials,
    };
  }
}
