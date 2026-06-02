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
        Row(
          children: [
            Text(
              '\uB313\uAE00',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (!_isLoading && _comments.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_comments.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_comments.isEmpty)
          const _CommentEmptyState()
        else
          ..._comments.map(
            (comment) => _CommentBubble(
              comment: comment,
              isOwn: widget.currentUserId == comment.authorId,
              canDelete:
                  widget.currentUserId == comment.authorId || widget.isAdmin,
              onDelete: () => _confirmDelete(comment),
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _CommentComposer(
          controller: _controller,
          isSending: _isSending,
          onSend: _sendComment,
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

class _CommentEmptyState extends StatelessWidget {
  const _CommentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mode_comment_outlined,
            size: 26,
            color: AppColors.mutedText,
          ),
          const SizedBox(height: 8),
          Text(
            '\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC5B4\uC694',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
          ),
          const SizedBox(height: 2),
          Text(
            '\uCC98\uC74C \uB313\uAE00\uC744 \uB0A8\uACA8\uBCF4\uC138\uC694',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.mutedText.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.isOwn,
    required this.canDelete,
    required this.onDelete,
  });

  final BoardComment comment;
  final bool isOwn;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubble = Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: isOwn ? AppColors.primarySoft : AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isOwn ? 16 : 5),
          topRight: Radius.circular(isOwn ? 5 : 16),
          bottomLeft: const Radius.circular(16),
          bottomRight: const Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOwn) ...[
                Flexible(
                  child: Text(
                    comment.authorName,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                friendlyRelativeTime(comment.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    constraints: const BoxConstraints.tightFor(
                      width: 24,
                      height: 24,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.mutedText,
                    ),
                    tooltip: '\uC0AD\uC81C',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isOwn) ...[
            MemberAvatar(
              displayName: comment.authorName,
              avatarColor: comment.authorAvatarColor,
              size: 34,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 1000,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '\uB313\uAE00\uC744 \uC785\uB825',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: IconButton.filled(
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              tooltip: '\uBCF4\uB0B4\uAE30',
            ),
          ),
        ],
      ),
    );
  }
}
