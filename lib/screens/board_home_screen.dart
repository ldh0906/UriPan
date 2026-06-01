import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/board_item.dart';
import '../services/board_realtime_subscription.dart';
import '../services/board_repository.dart';
import '../services/board_session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/board_action_sheets.dart';
import '../widgets/board_state_screens.dart';
import '../widgets/common_widgets.dart';
import 'today_board_screen.dart';

class BoardHomeScreen extends StatefulWidget {
  const BoardHomeScreen({
    super.key,
    required this.client,
    required this.repository,
  });

  final SupabaseClient client;
  final BoardRepository repository;

  @override
  State<BoardHomeScreen> createState() => _BoardHomeScreenState();
}

class _BoardHomeScreenState extends State<BoardHomeScreen> {
  late final BoardSessionController _controller;
  late final BoardRealtimeSubscription _realtimeSubscription;
  late Future<void> _initialLoad;
  BoardTab _selectedTab = BoardTab.today;
  String? _message;

  @override
  void initState() {
    super.initState();
    _controller = BoardSessionController(widget.repository)
      ..addListener(_handleControllerChanged);
    _realtimeSubscription = BoardRealtimeSubscription(widget.client);
    _initialLoad = _controller.load();
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

  Future<void> _addItem([BoardItemType? initialType]) async {
    final board = _controller.activeBoard;
    if (board == null) return;

    final draft = await showAddItemSheet(
      context,
      initialType: initialType,
      members: _controller.members,
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
      return '\uBCF4\uB4DC\uB97C \uB9CC\uB4E0 \uC0AC\uB78C\uC740 \uB098\uAC08 \uC218 \uC5C6\uC5B4\uC694.';
    }
    if (message.contains('last_admin_required')) {
      return '\uB9C8\uC9C0\uB9C9 \uAD00\uB9AC\uC790\uB294 \uB098\uAC08 \uC218 \uC5C6\uC5B4\uC694.';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
              selectedTab: _selectedTab,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
              onRefresh: _refresh,
              onAddItem: _addItem,
              activeInvite: _controller.activeInvite,
              onCreateInvite: _createInvite,
              onRegenerateInvite: _regenerateInvite,
              onRevokeInvite: _revokeInvite,
              onLeaveBoard: _leaveBoard,
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
