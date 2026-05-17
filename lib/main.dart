import 'dart:async';

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
import 'services/app_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UriPanApp());
}

class UriPanApp extends StatefulWidget {
  const UriPanApp({super.key, this.repository});

  final AppRepository? repository;

  @override
  State<UriPanApp> createState() => _UriPanAppState();
}

class _UriPanAppState extends State<UriPanApp> {
  late final AppRepository _repository =
      widget.repository ?? LocalAppRepository();
  AppSnapshot _snapshot = MockData.initialSnapshot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final loaded = await _repository.load();
    if (!mounted) return;
    setState(() {
      _snapshot = _normalized(loaded);
      _isLoading = false;
    });
  }

  AppSnapshot _normalized(AppSnapshot snapshot) {
    final boards = snapshot.boards
        .map((workspace) => workspace.withSyncedSummary())
        .toList(growable: false);
    final activeCode = boards.any(
      (workspace) => workspace.inviteCode == snapshot.activeInviteCode,
    )
        ? snapshot.activeInviteCode
        : boards.isEmpty
            ? null
            : boards.first.inviteCode;
    return snapshot.copyWith(boards: boards, activeInviteCode: activeCode);
  }

  BoardWorkspace? get _activeWorkspace {
    if (_snapshot.boards.isEmpty) return null;
    return _snapshot.boards[_activeWorkspaceIndex];
  }

  int get _activeWorkspaceIndex {
    final activeCode = _snapshot.activeInviteCode;
    final index = _snapshot.boards.indexWhere(
      (workspace) => workspace.inviteCode == activeCode,
    );
    return index >= 0 ? index : 0;
  }

  List<BoardData> get _boardCards =>
      _snapshot.boards.map((workspace) => workspace.board).toList();

  List<FamilyMember> get _activeMembers =>
      _activeWorkspace?.members ?? const [];

  List<ScheduleItemData> get _activeSchedules =>
      _activeWorkspace?.schedules ?? const [];

  List<TaskItemData> get _activeTasks => _activeWorkspace?.tasks ?? const [];

  List<NoticeItemData> get _activeNotices =>
      _activeWorkspace?.notices ?? const [];

  BoardSettings get _activeSettings =>
      _activeWorkspace?.settings ?? const BoardSettings();

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String _inviteCodeFor(String seed) {
    final letters = seed
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '')
        .padRight(4, 'X')
        .substring(0, 4);
    final suffix = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .toUpperCase()
        .substring(4, 8);
    return '$letters-$suffix';
  }

  void _commit(AppSnapshot snapshot) {
    final normalized = _normalized(snapshot);
    setState(() => _snapshot = normalized);
    unawaited(_repository.save(normalized));
  }

  void _updateActiveWorkspace(BoardWorkspace Function(BoardWorkspace) update) {
    final current = _activeWorkspace;
    if (current == null) return;
    final boards = List<BoardWorkspace>.of(_snapshot.boards);
    final updated = update(current).withSyncedSummary();
    boards[_activeWorkspaceIndex] = updated;
    _commit(
      _snapshot.copyWith(
        boards: boards,
        activeInviteCode: updated.inviteCode,
      ),
    );
  }

  void login(String email, bool keepLoggedIn) {
    final trimmed = email.trim();
    final name = trimmed.isEmpty ? _snapshot.user.name : trimmed.split('@').first;
    _commit(
      _snapshot.copyWith(
        isAuthenticated: true,
        user: _snapshot.user.copyWith(
          name: _titleCase(name.replaceAll('.', ' ')),
          email: trimmed.isEmpty ? _snapshot.user.email : trimmed,
          keepLoggedIn: keepLoggedIn,
        ),
      ),
    );
  }

  void signUp(String name, String email, bool keepLoggedIn) {
    final displayName = name.trim().isEmpty ? 'New Member' : name.trim();
    _commit(
      _snapshot.copyWith(
        isAuthenticated: true,
        user: _snapshot.user.copyWith(
          name: displayName,
          email: email.trim().isEmpty ? _snapshot.user.email : email.trim(),
          initials: _initialsFor(displayName),
          keepLoggedIn: keepLoggedIn,
        ),
      ),
    );
  }

  void logout() {
    _commit(_snapshot.copyWith(isAuthenticated: false));
  }

  void updateUserProfile(UserProfile user) {
    _commit(_snapshot.copyWith(user: user));
  }

  Future<void> resetLocalData() async {
    await _repository.clear();
    _commit(MockData.initialSnapshot);
  }

  void saveBoardItem(BoardItemDraft draft) {
    _updateActiveWorkspace((workspace) {
      final schedules = List<ScheduleItemData>.of(workspace.schedules);
      final tasks = List<TaskItemData>.of(workspace.tasks);
      final notices = List<NoticeItemData>.of(workspace.notices);
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
          index >= 0 ? schedules[index] = item : schedules.insert(0, item);
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
          index >= 0 ? tasks[index] = item : tasks.insert(0, item);
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
                (draft.requiresConfirmation
                    ? const []
                    : [_snapshot.user.initials]),
          );
          index >= 0 ? notices[index] = item : notices.insert(0, item);
      }

      return workspace.copyWith(
        schedules: schedules,
        tasks: tasks,
        notices: notices,
      );
    });
  }

  void createBoard(String name) {
    final user = _snapshot.user;
    final board = BoardWorkspace(
      board: BoardData(
        name: name,
        role: 'Admin',
        members: '1',
        schedules: 'No schedules yet',
        tasks: 'No tasks yet',
        notices: 'No notices',
      ),
      inviteCode: _inviteCodeFor(name),
      members: [
        FamilyMember(
          name: user.name,
          initials: user.initials,
          role: 'Admin',
          color: user.color,
        ),
      ],
      schedules: const [],
      tasks: const [],
      notices: const [],
    );
    _commit(
      _snapshot.copyWith(
        boards: [board, ..._snapshot.boards],
        activeInviteCode: board.inviteCode,
      ),
    );
  }

  void joinBoard(String inviteCode) {
    final code = inviteCode.trim().toUpperCase();
    final existingIndex = _snapshot.boards.indexWhere(
      (workspace) => workspace.inviteCode == code,
    );
    if (existingIndex >= 0) {
      _commit(_snapshot.copyWith(activeInviteCode: code));
      return;
    }

    BoardWorkspace? template;
    for (final workspace in MockData.boardWorkspaces) {
      if (workspace.inviteCode == code) {
        template = workspace;
        break;
      }
    }
    final joined = (template ??
            BoardWorkspace(
              board: const BoardData(
                name: 'Joined Board',
                role: 'Member',
                members: '2',
                schedules: 'No schedules yet',
                tasks: 'No tasks yet',
                notices: 'No notices',
              ),
              inviteCode: code,
              members: [
                FamilyMember(
                  name: _snapshot.user.name,
                  initials: _snapshot.user.initials,
                  role: 'Member',
                  color: _snapshot.user.color,
                ),
              ],
              schedules: const [],
              tasks: const [],
              notices: const [],
            ))
        .copyWith(board: (template?.board ?? const BoardData(
              name: 'Joined Board',
              role: 'Member',
              members: '2',
              schedules: 'No schedules yet',
              tasks: 'No tasks yet',
              notices: 'No notices',
            )).copyWith(role: 'Member'))
        .withSyncedSummary();

    _commit(
      _snapshot.copyWith(
        boards: [joined, ..._snapshot.boards],
        activeInviteCode: joined.inviteCode,
      ),
    );
  }

  void selectBoard(BoardData board) {
    final workspace = _snapshot.boards.firstWhere(
      (workspace) => workspace.board.name == board.name,
      orElse: () => _snapshot.boards.first,
    );
    _commit(_snapshot.copyWith(activeInviteCode: workspace.inviteCode));
  }

  void updateActiveBoardSettings(BoardSettings settings) {
    _updateActiveWorkspace((workspace) => workspace.copyWith(settings: settings));
  }

  void toggleTask(TaskItemData task, bool? value) {
    _updateActiveWorkspace((workspace) {
      final tasks = List<TaskItemData>.of(workspace.tasks);
      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        final isDone = value ?? false;
        if (isDone && workspace.settings.autoArchiveCompletedTasks) {
          tasks.removeAt(index);
        } else {
          tasks[index] = tasks[index].copyWith(isDone: isDone);
        }
      }
      return workspace.copyWith(tasks: tasks);
    });
  }

  void deleteTask(TaskItemData task) {
    _updateActiveWorkspace(
      (workspace) => workspace.copyWith(
        tasks: workspace.tasks.where((item) => item.id != task.id).toList(),
      ),
    );
  }

  void deleteSchedule(ScheduleItemData schedule) {
    _updateActiveWorkspace(
      (workspace) => workspace.copyWith(
        schedules: workspace.schedules
            .where((item) => item.id != schedule.id)
            .toList(),
      ),
    );
  }

  void toggleNoticeConfirmation(NoticeItemData notice) {
    _updateActiveWorkspace((workspace) {
      final notices = List<NoticeItemData>.of(workspace.notices);
      final index = notices.indexWhere((item) => item.id == notice.id);
      if (index >= 0) {
        final current = notices[index];
        final nextConfirmed = !current.confirmedByMe;
        final nextCount = nextConfirmed
            ? current.confirmedCount + 1
            : (current.confirmedCount - 1).clamp(0, workspace.members.length);
        final initials = List<String>.of(current.confirmedInitials);
        if (nextConfirmed && !initials.contains(_snapshot.user.initials)) {
          initials.add(_snapshot.user.initials);
        } else if (!nextConfirmed) {
          initials.remove(_snapshot.user.initials);
        }
        notices[index] = current.copyWith(
          confirmedByMe: nextConfirmed,
          confirmedCount: nextCount,
          confirmedInitials: initials,
        );
      }
      return workspace.copyWith(notices: notices);
    });
  }

  void deleteNotice(NoticeItemData notice) {
    _updateActiveWorkspace(
      (workspace) => workspace.copyWith(
        notices:
            workspace.notices.where((item) => item.id != notice.id).toList(),
      ),
    );
  }

  void updateMemberRole(FamilyMember member, String role) {
    _updateActiveWorkspace((workspace) {
      final members = List<FamilyMember>.of(workspace.members);
      final index = members.indexWhere((item) => item.name == member.name);
      if (index >= 0) {
        members[index] = members[index].copyWith(role: role);
      }
      return workspace.copyWith(members: members);
    });
  }

  void removeMember(FamilyMember member) {
    _updateActiveWorkspace(
      (workspace) => workspace.copyWith(
        members:
            workspace.members.where((item) => item.name != member.name).toList(),
      ),
    );
  }

  void leaveActiveBoard() {
    final current = _activeWorkspace;
    if (current == null) return;
    final boards = _snapshot.boards
        .where((workspace) => workspace.inviteCode != current.inviteCode)
        .toList();
    _commit(
      _snapshot.copyWith(
        boards: boards,
        activeInviteCode: boards.isEmpty ? null : boards.first.inviteCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _snapshot.isAuthenticated
          ? _buildGroupSelectionScreen()
          : const WelcomeScreen(),
      routes: {
        LoginScreen.routeName: (_) => LoginScreen(
              user: _snapshot.user,
              onLogin: login,
              onSignUp: signUp,
            ),
        GroupSelectionScreen.routeName: (_) => _buildGroupSelectionScreen(),
        TodayBoardScreen.routeName: (_) => TodayBoardScreen(
              boardName: _activeWorkspace?.board.name ?? 'No Board',
              members: _activeMembers,
              schedules: _activeSchedules,
              tasks: _activeTasks,
              notices: _activeNotices,
              onTaskChanged: toggleTask,
              onNoticeConfirmed: toggleNoticeConfirmation,
            ),
        CalendarViewScreen.routeName: (_) => CalendarViewScreen(
              boardName: _activeWorkspace?.board.name ?? 'No Board',
              members: _activeMembers,
              schedules: _activeSchedules,
              onScheduleDeleted: deleteSchedule,
            ),
        TasksListScreen.routeName: (_) => TasksListScreen(
              boardName: _activeWorkspace?.board.name ?? 'No Board',
              tasks: _activeTasks,
              onTaskChanged: toggleTask,
              onTaskDeleted: deleteTask,
            ),
        NoticesBoardScreen.routeName: (_) => NoticesBoardScreen(
              boardName: _activeWorkspace?.board.name ?? 'No Board',
              notices: _activeNotices,
              members: _activeMembers,
              onNoticeConfirmed: toggleNoticeConfirmation,
              onNoticeDeleted: deleteNotice,
            ),
        MembersInviteScreen.routeName: (_) => MembersInviteScreen(
              boardName: _activeWorkspace?.board.name ?? 'No Board',
              inviteCode: _activeWorkspace?.inviteCode ?? 'NO-BOARD',
              members: _activeMembers,
              settings: _activeSettings,
              onSettingsChanged: updateActiveBoardSettings,
              onMemberRoleChanged: updateMemberRole,
              onMemberRemoved: removeMember,
              onLeaveBoard: leaveActiveBoard,
            ),
        AddItemSelectorScreen.routeName: (_) => const AddItemSelectorScreen(),
        ItemDetailEditScreen.routeName: (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          return ItemDetailEditScreen(
            members: _activeMembers,
            initialType: arguments is BoardItemEditArguments
                ? arguments.type
                : arguments is BoardItemType
                    ? arguments
                    : BoardItemType.schedule,
            editingItem: arguments is BoardItemEditArguments ? arguments : null,
            defaultRequireConfirmation:
                _activeSettings.requireNoticeConfirmation,
            onSave: saveBoardItem,
          );
        },
      },
    );
  }

  GroupSelectionScreen _buildGroupSelectionScreen() {
    return GroupSelectionScreen(
      boards: _boardCards,
      user: _snapshot.user,
      settings: _activeSettings,
      onCreateBoard: createBoard,
      onJoinBoard: joinBoard,
      onSelectBoard: selectBoard,
      onUserChanged: updateUserProfile,
      onSettingsChanged: updateActiveBoardSettings,
      onLogout: logout,
      onResetLocalData: resetLocalData,
    );
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ME';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
