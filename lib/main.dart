import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/seed_data.dart';
import 'models/board_item.dart';
import 'screens/today_board_screen.dart';
import 'services/auth_error_messages.dart';
import 'services/auth_input_validator.dart';
import 'services/board_repository.dart';
import 'services/board_session_controller.dart';
import 'theme/app_theme.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_hasSupabaseConfig) {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabasePublishableKey,
    );
  }

  runApp(const UriPanApp());
}

bool get _hasSupabaseConfig =>
    _supabaseUrl.isNotEmpty && _supabasePublishableKey.isNotEmpty;

class UriPanApp extends StatelessWidget {
  const UriPanApp({super.key, this.repository, this.supabaseClient});

  final BoardRepository? repository;
  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    final client =
        supabaseClient ??
        (_hasSupabaseConfig ? Supabase.instance.client : null);
    final boardRepository =
        repository ??
        (client == null
            ? MemoryBoardRepository(seedBoardItems)
            : SupabaseBoardRepository(client));

    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: client == null
          ? TodayBoardScreen(repository: boardRepository)
          : AuthGate(client: client, repository: boardRepository),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.client, required this.repository});

  final SupabaseClient client;
  final BoardRepository repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isClearingAnonymousSession = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: widget.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = widget.client.auth.currentSession;
        if (session == null) {
          return LoginScreen(client: widget.client);
        }

        if (widget.client.auth.currentUser?.isAnonymous == true) {
          if (!_isClearingAnonymousSession) {
            _isClearingAnonymousSession = true;
            widget.client.auth.signOut().whenComplete(() {
              if (mounted) setState(() => _isClearingAnonymousSession = false);
            });
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BoardHomeScreen(
          client: widget.client,
          repository: widget.repository,
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_validateUserIdPassword()) return;

    await _runAuthAction(() async {
      await widget.client.auth.signInWithPassword(
        email: AuthInputValidator.syntheticEmailForUserId(
          _userIdController.text,
        ),
        password: _passwordController.text,
      );
    }, successMessage: null);
  }

  Future<void> _signUp() async {
    if (!_validateUserIdPassword()) return;

    await _runAuthAction(
      () async {
        final userId = AuthInputValidator.normalizeUserId(
          _userIdController.text,
        );
        await widget.client.auth.signUp(
          email: AuthInputValidator.syntheticEmailForUserId(userId),
          password: _passwordController.text,
          data: {'display_name': userId},
        );
      },
      successMessage:
          '\uCC98\uC74C \uC0AC\uC6A9 \uC900\uBE44\uAC00 \uB05D\uB0AC\uC5B4\uC694. \uB85C\uADF8\uC778\uD574\uC8FC\uC138\uC694.',
    );
  }

  Future<void> _runAuthAction(
    Future<void> Function() action, {
    required String? successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) {
        setState(() => _message = successMessage);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = _friendlyAuthError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyAuthError(AuthException error) {
    return AuthErrorMessages.fromAuthMessage(error.message);
  }

  bool _validateUserIdPassword() {
    final message = AuthInputValidator.validateUserIdPassword(
      _userIdController.text,
      _passwordController.text,
    );
    if (message == null) return true;
    setState(() => _message = message);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UriPan', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                '\uAC00\uC871\uC774 \uD568\uAED8 \uBCF4\uB294 \uC624\uB298 \uBCF4\uB4DC',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _userIdController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: '\uC544\uC774\uB514',
                  helperText:
                      '\uC601\uBB38, \uC22B\uC790, -, _ 3\uC790 \uC774\uC0C1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '\uBE44\uBC00\uBC88\uD638',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: const Text('\uB85C\uADF8\uC778'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isLoading ? null : _signUp,
                child: const Text('\uCC98\uC74C \uC0AC\uC6A9\uD558\uAE30'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
  late Future<void> _initialLoad;
  String? _message;
  RealtimeChannel? _boardChannel;
  String? _subscribedBoardId;

  @override
  void initState() {
    super.initState();
    _controller = BoardSessionController(widget.repository)
      ..addListener(_handleControllerChanged);
    _initialLoad = _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _controller.dispose();
    final channel = _boardChannel;
    if (channel != null) {
      widget.client.removeChannel(channel);
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    _syncRealtimeSubscription(_controller.activeBoard);
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    await _controller.load();
  }

  void _syncRealtimeSubscription(BoardSummary? board) {
    if (board == null) {
      final previous = _boardChannel;
      if (previous != null) {
        widget.client.removeChannel(previous);
      }
      _boardChannel = null;
      _subscribedBoardId = null;
      return;
    }

    if (_subscribedBoardId == board.id) return;

    final previous = _boardChannel;
    if (previous != null) {
      widget.client.removeChannel(previous);
    }

    _subscribedBoardId = board.id;
    _boardChannel = widget.client
        .channel('board:${board.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: board.id,
          ),
          callback: (_) {
            if (mounted) unawaited(_controller.handleBoardItemsChanged());
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_confirmations',
          callback: (_) {
            if (mounted) unawaited(_controller.handleBoardItemsChanged());
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: board.id,
          ),
          callback: (_) {
            if (mounted) {
              unawaited(_controller.handleBoardMembershipChanged());
            }
          },
        )
        .subscribe();
  }

  Future<void> _createBoard() async {
    final result = await showDialog<_CreateBoardResult>(
      context: context,
      builder: (context) => const _CreateBoardDialog(),
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

  Future<void> _addItem() async {
    final board = _controller.activeBoard;
    if (board == null) return;

    final draft = await showModalBottomSheet<BoardItemDraft>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _AddItemSheet(),
    );
    if (draft == null) return;

    await _runAction(() async {
      await _controller.createItem(draft);
    });
  }

  Future<void> _completeTask(BoardItem item, bool isDone) async {
    await _runAction(() async {
      await _controller.completeTask(item.id, isDone);
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
          return _BoardLoadErrorScreen(
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
          return _NoBoardScreen(
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
              board: board,
              onRefresh: _refresh,
              onAddItem: _addItem,
              onCreateInvite: _createInvite,
              onCompleteTask: _completeTask,
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

class _NoBoardScreen extends StatelessWidget {
  const _NoBoardScreen({
    required this.message,
    required this.onCreateBoard,
    required this.onJoinBoard,
    required this.onSignOut,
  });

  final String? message;
  final VoidCallback onCreateBoard;
  final VoidCallback onJoinBoard;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\uAC00\uC871 \uBCF4\uB4DC \uC2DC\uC791',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                '\uBCF4\uB4DC\uB97C \uB9CC\uB4E4\uAC70\uB098 \uCD08\uB300\uCF54\uB4DC\uB85C \uCC38\uAC00\uD574\uC8FC\uC138\uC694.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onCreateBoard,
                child: const Text('\uBCF4\uB4DC \uB9CC\uB4E4\uAE30'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onJoinBoard,
                child: const Text(
                  '\uCD08\uB300\uCF54\uB4DC\uB85C \uCC38\uAC00',
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSignOut,
                child: const Text('\uB85C\uADF8\uC544\uC6C3'),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardLoadErrorScreen extends StatelessWidget {
  const _BoardLoadErrorScreen({
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\uBCF4\uB4DC\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(message),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                child: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSignOut,
                child: const Text('\uB85C\uADF8\uC544\uC6C3'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateBoardResult {
  const _CreateBoardResult(this.name, this.maxMembers);

  final String name;
  final int maxMembers;
}

class _CreateBoardDialog extends StatefulWidget {
  const _CreateBoardDialog();

  @override
  State<_CreateBoardDialog> createState() => _CreateBoardDialogState();
}

class _CreateBoardDialogState extends State<_CreateBoardDialog> {
  final _nameController = TextEditingController(text: '\uC6B0\uB9AC\uC9D1');
  double _maxMembers = 4;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('\uBCF4\uB4DC \uB9CC\uB4E4\uAE30'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '\uBCF4\uB4DC \uC774\uB984',
            ),
          ),
          const SizedBox(height: 16),
          Text('\uCD5C\uB300 \uC778\uC6D0 ${_maxMembers.round()}\uBA85'),
          Slider(
            value: _maxMembers,
            min: 2,
            max: 20,
            divisions: 18,
            label: _maxMembers.round().toString(),
            onChanged: (value) => setState(() => _maxMembers = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('\uCDE8\uC18C'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _CreateBoardResult(
              _nameController.text.trim(),
              _maxMembers.round(),
            ),
          ),
          child: const Text('\uB9CC\uB4E4\uAE30'),
        ),
      ],
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  BoardItemType _type = BoardItemType.task;
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uAC00\uC871 \uD56D\uBAA9 \uCD94\uAC00',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<BoardItemType>(
              segments: BoardItemType.values
                  .map(
                    (type) =>
                        ButtonSegment(value: type, label: Text(type.label)),
                  )
                  .toList(),
              selected: {_type},
              onSelectionChanged: (values) {
                setState(() => _type = values.single);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '\uC81C\uBAA9'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailController,
              decoration: const InputDecoration(labelText: '\uBA54\uBAA8'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(
                  context,
                  BoardItemDraft(
                    type: _type,
                    title: title,
                    detail: _detailController.text.trim(),
                    requiresConfirmation: _type == BoardItemType.notice,
                  ),
                );
              },
              child: const Text('\uCD94\uAC00'),
            ),
          ],
        ),
      ),
    );
  }
}
