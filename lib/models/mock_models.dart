import 'package:flutter/material.dart';

enum BoardItemType { schedule, task, notice }

class BoardItemDraft {
  const BoardItemDraft({
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

  TaskItemData copyWith({bool? isDone}) {
    return TaskItemData(
      id: id,
      title: title,
      assignee: assignee,
      initials: initials,
      dueDate: dueDate,
      color: color,
      isDone: isDone ?? this.isDone,
      memo: memo,
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
    bool? confirmedByMe,
    int? confirmedCount,
  }) {
    return NoticeItemData(
      id: id,
      title: title,
      preview: preview,
      date: date,
      isImportant: isImportant,
      confirmedByMe: confirmedByMe ?? this.confirmedByMe,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      confirmedInitials: confirmedInitials,
    );
  }
}
