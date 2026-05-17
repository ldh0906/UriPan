import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'models/mock_models.dart';
import 'screens/add_item_selector_screen.dart';
import 'screens/calendar_view_screen.dart';
import 'screens/group_selection_screen.dart';
import 'screens/item_detail_edit_screen.dart';
import 'screens/login_screen.dart';
import 'screens/members_invite_screen.dart';
import 'screens/notices_board_screen.dart';
import 'screens/tasks_list_screen.dart';
import 'screens/today_board_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UriPanApp());
}

class UriPanApp extends StatefulWidget {
  const UriPanApp({super.key});

  @override
  State<UriPanApp> createState() => _UriPanAppState();
}

class _UriPanAppState extends State<UriPanApp> {
  late final List<BoardData> boards = List.of(MockData.boards);
  late BoardData? activeBoard = boards.isEmpty ? null : boards.first;
  late final List<FamilyMember> members = List.of(MockData.members);
  late final List<ScheduleItemData> schedules = List.of(MockData.schedules);
  late final List<TaskItemData> tasks = List.of(MockData.tasks);
  late final List<NoticeItemData> notices = List.of(MockData.notices);

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  void saveBoardItem(BoardItemDraft draft) {
    setState(() {
      final existingId = draft.id;
      switch (draft.type) {
        case BoardItemType.schedule:
          final index = existingId == null
              ? -1
              : schedules.indexWhere((item) => item.id == existingId);
          final item = ScheduleItemData(
            id: existingId ?? _nextId('schedule'),
            title: draft.title,
            initials: draft.initials,
            date: draft.date,
            start: draft.startTime,
            end: draft.endTime,
            color: draft.color,
          );
          if (index >= 0) {
            schedules[index] = item;
          } else {
            schedules.insert(0, item);
          }
        case BoardItemType.task:
          final index = existingId == null
              ? -1
              : tasks.indexWhere((item) => item.id == existingId);
          final item = TaskItemData(
            id: existingId ?? _nextId('task'),
            title: draft.title,
            assignee: draft.assignee,
            initials: draft.initials,
            dueDate: draft.date,
            color: draft.color,
            isDone: draft.isCompleted,
            memo: draft.notes,
          );
          if (index >= 0) {
            tasks[index] = item;
          } else {
            tasks.insert(0, item);
          }
        case BoardItemType.notice:
          final index = existingId == null
              ? -1
              : notices.indexWhere((item) => item.id == existingId);
          final previous = index >= 0 ? notices[index] : null;
          final item = NoticeItemData(
            id: existingId ?? _nextId('notice'),
            title: draft.title,
            preview: draft.notes ?? draft.title,
            date: draft.date,
            isImportant: draft.isImportant,
            confirmedByMe:
                previous?.confirmedByMe ?? !draft.requiresConfirmation,
            confirmedCount: previous?.confirmedCount ??
                (draft.requiresConfirmation ? 0 : 1),
            confirmedInitials: previous?.confirmedInitials ??
                (draft.requiresConfirmation ? const [] : const ['ME']),
          );
          if (index >= 0) {
            notices[index] = item;
          } else {
            notices.insert(0, item);
          }
      }
      _syncActiveBoardSummary();
    });
  }

  void _syncActiveBoardSummary() {
    final currentBoard = activeBoard;
    if (currentBoard == null) return;

    final index = boards.indexWhere((board) => board.name == currentBoard.name);
    if (index < 0) return;

    final remainingTasks = tasks.where((task) => !task.isDone).length;
    final unreadNotices =
        notices.where((notice) => !notice.confirmedByMe).length;
    final updated = currentBoard.copyWith(
      members: '${members.length}',
      schedules: schedules.isEmpty
          ? 'No schedules yet'
          : _plural(schedules.length, 'schedule', suffix: ' planned'),
      tasks: remainingTasks == 0
          ? 'No tasks remaining'
          : _plural(remainingTasks, 'task', suffix: ' remaining'),
      notices: unreadNotices == 0
          ? 'No new notices'
          : _plural(unreadNotices, 'New notice'),
    );
    boards[index] = updated;
    activeBoard = updated;
  }

  String _plural(int count, String word, {String suffix = ''}) {
    final plural = count == 1 ? word : '${word}s';
    return '$count $plural$suffix';
  }

  void createBoard(String name) {
    setState(() {
      final board = BoardData(
        name: name,
        role: 'Admin',
        members: '1',
        schedules: 'No schedules yet',
        tasks: 'No tasks yet',
        notices: 'No notices',
      );
      boards.insert(0, board);
      activeBoard = board;
    });
  }

  void joinBoard(String inviteCode) {
    final code = inviteCode.trim().toUpperCase();
    setState(() {
      final board = BoardData(
        name: code == 'URIPAN-2024' ? 'Sweet Home' : 'Joined Board',
        role: 'Member',
        members: code == 'URIPAN-2024' ? '4' : '2',
        schedules: 'Synced after invite',
        tasks: 'Waiting for tasks',
        notices: 'No new notices',
      );
      boards.insert(0, board);
      activeBoard = board;
    });
  }

  void selectBoard(BoardData board) {
    setState(() {
      activeBoard = board;
    });
  }

  void toggleTask(TaskItemData task, bool? value) {
    setState(() {
      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        tasks[index] = tasks[index].copyWith(isDone: value ?? false);
        _syncActiveBoardSummary();
      }
    });
  }

  void deleteTask(TaskItemData task) {
    setState(() {
      tasks.removeWhere((item) => item.id == task.id);
      _syncActiveBoardSummary();
    });
  }

  void deleteSchedule(ScheduleItemData schedule) {
    setState(() {
      schedules.removeWhere((item) => item.id == schedule.id);
      _syncActiveBoardSummary();
    });
  }

  void toggleNoticeConfirmation(NoticeItemData notice) {
    setState(() {
      final index = notices.indexWhere((item) => item.id == notice.id);
      if (index >= 0) {
        final current = notices[index];
        final nextConfirmed = !current.confirmedByMe;
        final nextCount = nextConfirmed
            ? current.confirmedCount + 1
            : (current.confirmedCount - 1).clamp(0, members.length);
        notices[index] = current.copyWith(
          confirmedByMe: nextConfirmed,
          confirmedCount: nextCount,
        );
        _syncActiveBoardSummary();
      }
    });
  }

  void deleteNotice(NoticeItemData notice) {
    setState(() {
      notices.removeWhere((item) => item.id == notice.id);
      _syncActiveBoardSummary();
    });
  }

  void updateMemberRole(FamilyMember member, String role) {
    setState(() {
      final index = members.indexWhere((item) => item.name == member.name);
      if (index >= 0) {
        members[index] = members[index].copyWith(role: role);
      }
    });
  }

  void removeMember(FamilyMember member) {
    setState(() {
      members.removeWhere((item) => item.name == member.name);
      _syncActiveBoardSummary();
    });
  }

  void leaveActiveBoard() {
    setState(() {
      final currentBoard = activeBoard;
      if (currentBoard == null) return;
      boards.removeWhere((board) => board.name == currentBoard.name);
      activeBoard = boards.isEmpty ? null : boards.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: WelcomeScreen.routeName,
      routes: {
        WelcomeScreen.routeName: (_) => const WelcomeScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        GroupSelectionScreen.routeName: (_) => GroupSelectionScreen(
              boards: boards,
              onCreateBoard: createBoard,
              onJoinBoard: joinBoard,
              onSelectBoard: selectBoard,
            ),
        TodayBoardScreen.routeName: (_) => TodayBoardScreen(
              boardName: activeBoard?.name ?? 'No Board',
              members: members,
              schedules: schedules,
              tasks: tasks,
              notices: notices,
              onTaskChanged: toggleTask,
              onNoticeConfirmed: toggleNoticeConfirmation,
            ),
        CalendarViewScreen.routeName: (_) => CalendarViewScreen(
              boardName: activeBoard?.name ?? 'No Board',
              members: members,
              schedules: schedules,
              onScheduleDeleted: deleteSchedule,
            ),
        TasksListScreen.routeName: (_) => TasksListScreen(
              boardName: activeBoard?.name ?? 'No Board',
              tasks: tasks,
              onTaskChanged: toggleTask,
              onTaskDeleted: deleteTask,
            ),
        NoticesBoardScreen.routeName: (_) => NoticesBoardScreen(
              boardName: activeBoard?.name ?? 'No Board',
              notices: notices,
              members: members,
              onNoticeConfirmed: toggleNoticeConfirmation,
              onNoticeDeleted: deleteNotice,
            ),
        MembersInviteScreen.routeName: (_) => MembersInviteScreen(
              boardName: activeBoard?.name ?? 'No Board',
              members: members,
              onMemberRoleChanged: updateMemberRole,
              onMemberRemoved: removeMember,
              onLeaveBoard: leaveActiveBoard,
            ),
        AddItemSelectorScreen.routeName: (_) => const AddItemSelectorScreen(),
        ItemDetailEditScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          return ItemDetailEditScreen(
            members: members,
            initialType: arguments is BoardItemEditArguments
                ? arguments.type
                : arguments is BoardItemType
                    ? arguments
                    : BoardItemType.schedule,
            editingItem: arguments is BoardItemEditArguments ? arguments : null,
            onSave: saveBoardItem,
          );
        },
      },
    );
  }
}
