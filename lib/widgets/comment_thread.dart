import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/friendly_date.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

typedef CommentSubscription =
    void Function() Function(String itemId, void Function() onChanged);

class CommentThread extends StatefulWidget {
  const CommentThread({
    super.key,
    this.itemId,
    required this.loadComments,
    required this.onAddComment,
    required this.onDeleteComment,
    required this.currentUserId,
    this.subscribeComments,
    this.isAdmin = false,
  });

  final String? itemId;
  final Future<List<BoardComment>> Function() loadComments;
  final Future<void> Function(String body) onAddComment;
  final Future<void> Function(BoardComment comment) onDeleteComment;
  final String? currentUserId;
  final CommentSubscription? subscribeComments;
  final bool isAdmin;

  @override
  State<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<CommentThread> {
  final TextEditingController _controller = TextEditingController();
  List<BoardComment> _comments = const [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  VoidCallback? _disposeCommentSubscription;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _subscribeToComments();
  }

  @override
  void dispose() {
    _disposeCommentSubscription?.call();
    _controller.dispose();
    super.dispose();
  }

  void _subscribeToComments() {
    final subscribeComments = widget.subscribeComments;
    final itemId = widget.itemId;
    if (subscribeComments == null || itemId == null) return;

    try {
      _disposeCommentSubscription = subscribeComments(itemId, () {
        if (!mounted) return;
        _loadComments();
      });
    } catch (_) {
      _disposeCommentSubscription = null;
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await widget.loadComments();
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyCommentError(
          error,
          fallback:
              '\uB313\uAE00\uC744 \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC5B4\uC694.',
        );
      });
    }
  }

  Future<void> _sendComment() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await widget.onAddComment(body);
      _controller.clear();
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyCommentError(
          error,
          fallback:
              '\uB313\uAE00\uC744 \uC800\uC7A5\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694.',
        );
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _confirmDelete(BoardComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\uB313\uAE00 \uC0AD\uC81C'),
        content: const Text(
          '\uC774 \uB313\uAE00\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uC0AD\uC81C'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.onDeleteComment(comment);
      await _loadComments();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyCommentError(
          error,
          fallback:
              '\uB313\uAE00\uC744 \uC0AD\uC81C\uD558\uC9C0 \uBABB\uD588\uC5B4\uC694.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\uB313\uAE00',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_comments.isEmpty)
          const EmptyState(
            icon: Icons.mode_comment_outlined,
            message: '\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC5B4\uC694',
          )
        else
          ..._comments.map(
            (comment) => _CommentRow(
              comment: comment,
              canDelete:
                  widget.currentUserId == comment.authorId || widget.isAdmin,
              onDelete: () => _confirmDelete(comment),
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
                decoration: const InputDecoration(
                  hintText: '\uB313\uAE00\uC744 \uC785\uB825',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendComment,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              tooltip: '\uBCF4\uB0B4\uAE30',
            ),
          ],
        ),
      ],
    );
  }

  String _friendlyCommentError(Object error, {required String fallback}) {
    final message = error.toString();
    if (message.contains('comment_body_required')) {
      return '\uB313\uAE00\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('comment_body_too_long')) {
      return '\uB313\uAE00\uC740 1000\uC790\uAE4C\uC9C0 \uC785\uB825\uD560 \uC218 \uC788\uC5B4\uC694.';
    }
    if (message.contains('admin_required') ||
        message.contains('permission') ||
        message.contains('policy')) {
      return '\uC774 \uB313\uAE00\uC744 \uC0AD\uC81C\uD560 \uAD8C\uD55C\uC774 \uC5C6\uC5B4\uC694.';
    }
    return fallback;
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final BoardComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(
            displayName: comment.authorName,
            avatarColor: comment.authorAvatarColor,
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      friendlyRelativeTime(comment.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    if (canDelete)
                      IconButton(
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        tooltip: '\uC0AD\uC81C',
                      ),
                  ],
                ),
                Text(
                  comment.body,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
