import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/board_item.dart';
import '../services/board_realtime_subscription.dart';
import '../services/board_repository.dart';
import '../services/board_session_controller.dart';
import '../services/notifications/reminder_planner.dart';
import '../services/notifications/reminder_preferences.dart';
import '../services/notifications/reminder_scheduler.dart';
import '../theme/app_theme.dart';
import '../widgets/board_action_sheets.dart';
import '../widgets/board_settings_sheet.dart';
import '../widgets/board_state_screens.dart';
import '../widgets/common_widgets.dart';
import 'today_board_screen.dart';

class BoardHomeScreen extends StatefulWidget {
  BoardHomeScreen({
    super.key,
    required this.client,
    required this.repository,
    this.scheduler = const NoopReminderScheduler(),
    ReminderPreferences? reminderPreferences,
  }) : reminderPreferences = reminderPreferences ?? ReminderPreferences();

  final SupabaseClient client;
  final BoardRepository repository;
  final ReminderScheduler scheduler;
  final ReminderPreferences reminderPreferences;

  @override
  State<BoardHomeScreen> createState() => _BoardHomeScreenState();
}

class _BoardHomeScreenState extends State<BoardHomeScreen> {
  late final BoardSessionController _controller;
  late final BoardRealtimeSubscription _realtimeSubscription;
  late Future<void> _initialLoad;
  BoardTab _selectedTab = BoardTab.today;
  String? _message;
  bool _remindersEnabled = true;
  bool _reminderPreferencesLoaded = false;
  bool _schedulerInitialized = false;
  bool _permissionRequested = false;
  bool _isSyncingReminders = false;
  bool _syncRemindersAgain = false;
  String? _lastReminderPlanSignature;

  @override
  void initState() {
    super.initState();
    _controller = BoardSessionController(widget.repository)
      ..addListener(_handleControllerChanged);
    _realtimeSubscription = BoardRealtimeSubscription(widget.client);
    _initialLoad = _loadInitialBoard();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    _realtimeSubscription.clear();
    super.dispose();
  }

  void _handleControllerChanged() {
    _realtimeSubscription.sync(
      board: _controller.activeBoard,
      onItemsChanged: () {
        if (mounted) unawaited(_controller.handleBoardItemsChanged());
      },
      onMembershipChanged: () {
        if (mounted) unawaited(_controller.handleBoardMembershipChanged());
      },
    );
    unawaited(_syncRemindersIfNeeded());
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await _controller.load();
  }

  Future<void> _createBoard() async {
    final result = await showDialog<CreateBoardResult>(
      context: context,
      builder: (context) => const CreateBoardDialog(),
    );
    if (result == null) return;

    await _runAction(() async {
      await _controller.createBoard(result.name, result.maxMembers);
    });
  }

  Future<void> _joinBoard() async {
    final code = await _textDialog(
      title: '\uCD08\uB300\uCF54\uB4DC \uC785\uB825',
      label: 'URIP-1234',
    );
    if (code == null || code.trim().isEmpty) return;

    await _runAction(() async {
      await _controller.joinBoardWithInvite(code.trim());
    });
  }

  Future<void> _createInvite() async {
    final board = _controller.activeBoard;
    if (board == null || !board.isAdmin) return;

    await _runAction(() async {
      final invite = await _controller.createInvite();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('\uCD08\uB300\uCF54\uB4DC'),
          content: SelectableText(
            '${invite.code}\n\n\uB9CC\uB8CC: ${invite.expiresAt.toLocal()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('\uD655\uC778'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _regenerateInvite() async {
    final board = _controller.activeBoard;
    if (board == null || !board.isAdmin) return;

    await _runAction(() async {
      await _controller.regenerateInvite();
    });
  }

  Future<void> _revokeInvite() async {
    final board = _controller.activeBoard;
    if (board == null || !board.isAdmin) return;

    await _runAction(() async {
      await _controller.revokeInvite();
    });
  }

  Future<void> _leaveBoard() async {
    final board = _controller.activeBoard;
    if (board == null) return;

    await _runAction(() async {
      await _controller.leaveBoard();
    });
  }

  void _openSettings() {
    final board = _controller.activeBoard;
    if (board == null) return;

    showBoardSettingsSheet(
      context,
      boardName: board.name,
      userName: _currentUserDisplayName(),
      boards: _controller.boards,
      activeBoardId: board.id,
      onSelectBoard: (id) => _runAction(() => _controller.switchBoard(id)),
      myProfile: _controller.myProfile,
      remindersEnabled: _remindersEnabled,
      onRemindersEnabledChanged: _setRemindersEnabled,
      onEditProfile: () {
        Navigator.pop(context);
        unawaited(_editProfile());
      },
      onEditBoard: board.isAdmin
          ? () {
              Navigator.pop(context);
              unawaited(_editBoard());
            }
          : null,
      onSignOut: () {
        Navigator.pop(context);
        unawaited(widget.client.auth.signOut());
      },
    );
  }

  Future<void> _loadInitialBoard() async {
    await _loadReminderPreferences();
    await _controller.load();
    await _ensureSchedulerReady();
    await _syncRemindersIfNeeded(force: true);
  }

  Future<void> _loadReminderPreferences() async {
    try {
      _remindersEnabled = await widget.reminderPreferences.loadEnabled();
    } catch (_) {
      _remindersEnabled = true;
    } finally {
      _reminderPreferencesLoaded = true;
    }
  }

  Future<void> _setRemindersEnabled(bool enabled) async {
    if (_remindersEnabled == enabled) return;
    setState(() => _remindersEnabled = enabled);

    try {
      await widget.reminderPreferences.saveEnabled(enabled);
    } catch (_) {}

    if (!enabled) {
      _lastReminderPlanSignature = null;
      await _guardSchedulerCall(() => widget.scheduler.sync(const []));
      return;
    }

    await _ensureSchedulerReady();
    await _syncRemindersIfNeeded(force: true);
  }

  Future<void> _ensureSchedulerReady() async {
    if (!_reminderPreferencesLoaded || _schedulerInitialized) {
      return;
    }

    final initialized = await _guardSchedulerCall(
      () => widget.scheduler.init(),
    );
    if (!initialized) return;
    _schedulerInitialized = true;

    if (_remindersEnabled && !_permissionRequested) {
      _permissionRequested = true;
      await _guardSchedulerCall(() async {
        await widget.scheduler.requestPermission();
      });
    }
  }

  Future<void> _syncRemindersIfNeeded({bool force = false}) async {
    if (!_reminderPreferencesLoaded ||
        _controller.isLoading ||
        _controller.activeBoard == null) {
      return;
    }

    if (_isSyncingReminders) {
      _syncRemindersAgain = true;
      return;
    }

    _isSyncingReminders = true;
    try {
      do {
        _syncRemindersAgain = false;
        await _ensureSchedulerReady();

        final plan = buildReminderPlan(
          items: _controller.items,
          currentUserId: widget.client.auth.currentUser?.id,
          now: DateTime.now(),
          settings: ReminderSettings(enabled: _remindersEnabled),
        );
        final signature = _reminderPlanSignature(plan);
        if (force || signature != _lastReminderPlanSignature) {
          final synced = await _guardSchedulerCall(
            () => widget.scheduler.sync(plan),
          );
          if (synced) _lastReminderPlanSignature = signature;
        }
        force = false;
      } while (_syncRemindersAgain);
    } finally {
      _isSyncingReminders = false;
    }
  }

  String _reminderPlanSignature(List<ScheduledReminder> plan) {
    return plan
        .map(
          (reminder) => [
            reminder.id,
            reminder.title,
            reminder.body,
            reminder.scheduledAt.microsecondsSinceEpoch,
          ].join('|'),
        )
        .join('\n');
  }

  Future<bool> _guardSchedulerCall(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _editProfile() async {
    final profile = _controller.myProfile;
    if (profile == null) return;

    final result = await showEditProfileSheet(context, profile: profile);
    if (result == null) return;

    await _runAction(() async {
      await _controller.updateMyProfile(
        displayName: result.displayName,
        avatarColor: result.avatarColor,
      );
    });
  }

  Future<void> _editBoard() async {
    final board = _controller.activeBoard;
    if (board == null || !board.isAdmin) return;

    final result = await showEditBoardSettingsSheet(context, board: board);
    if (result == null) return;

    await _runAction(() async {
      await _controller.updateBoard(
        name: result.name,
        maxMembers: result.maxMembers,
      );
    });
  }

  String? _currentUserDisplayName() {
    final profileName = _controller.myProfile?.displayName;
    if (profileName != null && profileName.trim().isNotEmpty) {
      return profileName;
    }

    final metadataName =
        widget.client.auth.currentUser?.userMetadata?['display_name'];
    if (metadataName is String && metadataName.trim().isNotEmpty) {
      return metadataName;
    }

    final currentUserId = widget.client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    for (final member in _controller.members) {
      if (member.userId == currentUserId) return member.displayName;
    }

    return null;
  }

  Future<void> _addItem([
    BoardItemType? initialType,
    DateTime? initialDateTime,
  ]) async {
    final board = _controller.activeBoard;
    if (board == null) return;

    final draft = await showAddItemSheet(
      context,
      initialType: initialType,
      members: _controller.members,
      initialDateTime: initialDateTime,
    );
    if (draft == null) return;

    await _runAction(() async {
      await _controller.createItem(draft);
    });
  }

  Future<void> _editItem(BoardItem item) async {
    final draft = await showEditItemSheet(
      context,
      item,
      members: _controller.members,
    );
    if (draft == null) return;

    await _runAction(() async {
      await _controller.updateItem(item.id, draft);
    });
  }

  Future<void> _completeTask(BoardItem item, bool isDone) async {
    await _runAction(() async {
      await _controller.completeTask(item.id, isDone);
    });
  }

  Future<void> _confirmNotice(BoardItem item, bool confirmed) async {
    await _runAction(() async {
      await _controller.confirmNotice(item.id, confirmed);
    });
  }

  Future<void> _deleteItem(BoardItem item) async {
    await _runAction(() async {
      await _controller.deleteItem(item.id);
    });
  }

  Future<void> _updateMemberRole(String userId, String role) async {
    await _runAction(() async {
      await _controller.updateMemberRole(userId, role);
    });
  }

  Future<void> _removeMember(String userId) async {
    await _runAction(() async {
      await _controller.removeMember(userId);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      setState(() => _message = null);
      await action();
    } on PostgrestException catch (error) {
      if (!mounted) return;
      setState(() => _message = _friendlyDatabaseError(error.message));
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    }
  }

  String _friendlyDatabaseError(String message) {
    if (message.contains('board_full')) {
      return '\uC774 \uBCF4\uB4DC\uB294 \uC815\uC6D0\uC774 \uCC3C\uC5B4\uC694.';
    }
    if (message.contains('invalid_invite')) {
      return '\uCD08\uB300\uCF54\uB4DC\uB97C \uD655\uC778\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('expired_invite')) {
      return '\uCD08\uB300\uCF54\uB4DC\uAC00 \uB9CC\uB8CC\uB410\uC5B4\uC694.';
    }
    if (message.contains('revoked_invite')) {
      return '\uCD08\uB300\uCF54\uB4DC\uAC00 \uCDE8\uC18C\uB410\uC5B4\uC694.';
    }
    if (message.contains('already_joined')) {
      return '\uC774\uBBF8 \uCC38\uAC00\uD55C \uBCF4\uB4DC\uC608\uC694.';
    }
    if (message.contains('admin_required')) {
      return '\uAD00\uB9AC\uC790\uB9CC \uD560 \uC218 \uC788\uC5B4\uC694.';
    }
    if (message.contains('creator_admin_required')) {
      return '\uBCF4\uB4DC\uB97C \uB9CC\uB4E0 \uC0AC\uB78C\uC740 \uBC14\uAFC0 \uC218 \uC5C6\uC5B4\uC694.';
    }
    if (message.contains('last_admin_required')) {
      return '\uB9C8\uC9C0\uB9C9 \uAD00\uB9AC\uC790\uB294 \uBC14\uAFC0 \uC218 \uC5C6\uC5B4\uC694.';
    }
    if (message.contains('max_members_below_current_count')) {
      return '\uC815\uC6D0\uC740 \uD604\uC7AC \uC778\uC6D0\uBCF4\uB2E4 \uC801\uAC8C \uC124\uC815\uD560 \uC218 \uC5C6\uC5B4\uC694.';
    }
    return message;
  }

  Future<String?> _textDialog({required String title, required String label}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('\uD655\uC778'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BoardInitialSkeleton();
        }
        if (snapshot.hasError) {
          return BoardLoadErrorScreen(
            message: _friendlyDatabaseError(snapshot.error.toString()),
            onRetry: () {
              setState(() {
                _initialLoad = _controller.load();
              });
            },
            onSignOut: () => widget.client.auth.signOut(),
          );
        }

        final board = _controller.activeBoard;
        if (board == null) {
          return NoBoardScreen(
            message: _message,
            onCreateBoard: _createBoard,
            onJoinBoard: _joinBoard,
            onSignOut: () => widget.client.auth.signOut(),
          );
        }

        return Stack(
          children: [
            TodayBoardScreen(
              items: _controller.items,
              members: _controller.members,
              board: board,
              currentUserId: widget.client.auth.currentUser?.id,
              selectedTab: _selectedTab,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
              onRefresh: _refresh,
              onAddItem: _addItem,
              activeInvite: _controller.activeInvite,
              onCreateInvite: _createInvite,
              onOpenSettings: _openSettings,
              onRegenerateInvite: _regenerateInvite,
              onRevokeInvite: _revokeInvite,
              onLeaveBoard: _leaveBoard,
              onUpdateMemberRole: _updateMemberRole,
              onRemoveMember: _removeMember,
              onCompleteTask: _completeTask,
              onConfirmNotice: _confirmNotice,
              onEditItem: _editItem,
              onDeleteItem: _deleteItem,
            ),
            if (_message != null)
              Positioned(
                left: 16,
                right: 16,
                top: 48,
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.light().colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_message!),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BoardInitialSkeleton extends StatelessWidget {
  const _BoardInitialSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBar(width: 92, height: 16),
              SizedBox(height: 8),
              _SkeletonBar(width: 168, height: 28),
              SizedBox(height: 22),
              _SkeletonCard(lines: [0.42, 0.72, 0.54]),
              SizedBox(height: 14),
              _SkeletonCard(lines: [0.34, 0.88, 0.62]),
              SizedBox(height: 14),
              _SkeletonCard(lines: [0.3, 0.8, 0.48]),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.lines});

  final List<double> lines;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final widthFactor in lines) ...[
            FractionallySizedBox(
              widthFactor: widthFactor,
              child: const _SkeletonBar(height: 14),
            ),
            if (widthFactor != lines.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
