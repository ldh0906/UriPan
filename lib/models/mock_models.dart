import 'package:flutter/material.dart';

enum BoardItemType { schedule, task, notice }

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
      assignee: 'Everyone',
      initials: 'ALL',
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
}
