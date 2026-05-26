import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/seed_data.dart';
import 'models/board_item.dart';
import 'screens/today_board_screen.dart';
import 'services/board_repository.dart';
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: widget.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = widget.client.auth.currentSession;
        if (session == null) {
          return LoginScreen(client: widget.client);
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await _runAuthAction(() async {
      await widget.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }, successMessage: null);
  }

  Future<void> _signUp() async {
    await _runAuthAction(
      () async {
        await widget.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      },
      successMessage:
          '\uD68C\uC6D0\uAC00\uC785\uC744 \uD655\uC778\uD574\uC8FC\uC138\uC694. \uBA54\uC77C \uD655\uC778\uC774 \uD544\uC694\uD560 \uC218 \uC788\uC5B4\uC694.',
    );
  }

  Future<void> _sendMagicLink() async {
    await _runAuthAction(
      () async {
        await widget.client.auth.signInWithOtp(
          email: _emailController.text.trim(),
        );
      },
      successMessage:
          '\uB85C\uADF8\uC778 \uB9C1\uD06C\uB97C \uBA54\uC77C\uB85C \uBCF4\uB0C8\uC5B4\uC694.',
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
      setState(() => _message = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '\uC774\uBA54\uC77C',
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: const Text('\uD68C\uC6D0\uAC00\uC785'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _sendMagicLink,
                      child: const Text('\uB9E4\uC9C1\uB9C1\uD06C'),
                    ),
                  ),
                ],
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
  late Future<void> _loadFuture = _loadBoards();
  BoardSummary? _activeBoard;
  String? _message;

  Future<void> _loadBoards() async {
    final boards = await widget.repository.loadBoards();
    _activeBoard = boards.isEmpty ? null : boards.first;
  }

  Future<void> _refresh() async {
    setState(() {
      _loadFuture = _loadBoards();
    });
    await _loadFuture;
  }

  Future<void> _createBoard() async {
    final result = await showDialog<_CreateBoardResult>(
      context: context,
      builder: (context) => const _CreateBoardDialog(),
    );
    if (result == null) return;

    await _runAction(() async {
      _activeBoard = await widget.repository.createBoard(
        result.name,
        result.maxMembers,
      );
      await _refresh();
    });
  }

  Future<void> _joinBoard() async {
    final code = await _textDialog(
      title: '\uCD08\uB300\uCF54\uB4DC \uC785\uB825',
      label: 'URIP-1234',
    );
    if (code == null || code.trim().isEmpty) return;

    await _runAction(() async {
      _activeBoard = await widget.repository.joinBoardWithInvite(code.trim());
      await _refresh();
    });
  }

  Future<void> _createInvite() async {
    final board = _activeBoard;
    if (board == null || !board.isAdmin) return;

    await _runAction(() async {
      final invite = await widget.repository.createInvite(board.id);
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
    final board = _activeBoard;
    if (board == null) return;

    final draft = await showModalBottomSheet<BoardItemDraft>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _AddItemSheet(),
    );
    if (draft == null) return;

    await _runAction(() async {
      await widget.repository.createItem(board.id, draft);
      setState(() {});
    });
  }

  Future<void> _completeTask(BoardItem item, bool isDone) async {
    await _runAction(() async {
      await widget.repository.completeTask(item.id, isDone);
      setState(() {});
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
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final board = _activeBoard;
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
              repository: widget.repository,
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
