import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/friendly_date.dart';
import '../theme/app_theme.dart';
import 'board_item_card.dart';
import 'comment_thread.dart';
import 'common_widgets.dart';

class ItemDetailSheet extends StatelessWidget {
  const ItemDetailSheet({
    super.key,
    required this.item,
    required this.isPending,
    this.onToggle,
    this.onConfirm,
    this.onEdit,
    this.onDelete,
    this.loadComments,
    this.onAddComment,
    this.onDeleteComment,
    this.currentUserId,
    this.subscribeComments,
    this.isAdmin = false,
    this.members = const [],
  });

  final BoardItem item;
  final bool isPending;
  final Future<void> Function(bool isDone)? onToggle;
  final Future<void> Function(bool confirmed)? onConfirm;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;
  final Future<List<BoardComment>> Function()? loadComments;
  final Future<void> Function(String body)? onAddComment;
  final Future<void> Function(BoardComment comment)? onDeleteComment;
  final String? currentUserId;
  final CommentSubscription? subscribeComments;
  final bool isAdmin;
  final List<BoardMember> members;

  @override
  Widget build(BuildContext context) {
    final detail = item.detail.trim();
    final typeLabel = item.type.label;
    final dateLabel = _dateLabel(item);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '\uB2EB\uAE30',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  InfoChip(label: typeLabel),
                  InfoChip(label: item.owner),
                  if (item.assigneeName != null)
                    InfoChip(label: '\uB2F4\uB2F9: ${item.assigneeName}'),
                  InfoChip(label: dateLabel ?? item.timeLabel),
                  if (item.isPinned) const InfoChip(label: '\uACE0\uC815'),
                  if (item.type == BoardItemType.task)
                    InfoChip(
                      label: item.isDone
                          ? '\uC644\uB8CC\uB428'
                          : '\uBBF8\uC644\uB8CC',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                detail.isEmpty
                    ? '\uBA54\uBAA8\uAC00 \uC5C6\uC5B4\uC694.'
                    : detail,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: detail.isEmpty ? AppColors.mutedText : null,
                ),
              ),
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags
                      .map((tag) => TagChip(label: tag))
                      .toList(growable: false),
                ),
              ],
              if (item.type == BoardItemType.task && onToggle != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: isPending ? null : () => onToggle!(!item.isDone),
                  icon: Icon(
                    item.isDone
                        ? Icons.undo_rounded
                        : Icons.check_circle_rounded,
                  ),
                  label: Text(
                    item.isDone
                        ? '\uC644\uB8CC \uCDE8\uC18C'
                        : '\uC644\uB8CC\uD558\uAE30',
                  ),
                ),
              ],
              if (item.type == BoardItemType.notice &&
                  item.requiresConfirmation) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      label: '\uD655\uC778 ${item.confirmationCount}\uBA85',
                    ),
                    InfoChip(
                      label: item.isConfirmedByMe
                          ? '\uB0B4\uAC00 \uD655\uC778\uD568'
                          : '\uC544\uC9C1 \uD655\uC778 \uC804',
                    ),
                  ],
                ),
                if (onConfirm != null) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => onConfirm!(!item.isConfirmedByMe),
                    icon: Icon(
                      item.isConfirmedByMe
                          ? Icons.undo_rounded
                          : Icons.visibility_rounded,
                    ),
                    label: Text(
                      item.isConfirmedByMe
                          ? '\uD655\uC778 \uCDE8\uC18C'
                          : '\uD655\uC778\uD588\uC5B4\uC694',
                    ),
                  ),
                ],
                if (members.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ConfirmationRoster(item: item, members: members),
                ],
              ],
              if (onEdit != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('\uC218\uC815'),
                ),
              ],
              if (onDelete != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('\uC0AD\uC81C'),
                ),
              ],
              if (loadComments != null &&
                  onAddComment != null &&
                  onDeleteComment != null) ...[
                const SizedBox(height: 24),
                CommentThread(
                  itemId: item.id,
                  loadComments: loadComments!,
                  onAddComment: onAddComment!,
                  onDeleteComment: onDeleteComment!,
                  currentUserId: currentUserId,
                  subscribeComments: subscribeComments,
                  isAdmin: isAdmin,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _dateLabel(BoardItem item) {
    final value = item.type == BoardItemType.schedule
        ? item.startsAt
        : item.dueAt;
    if (value == null) return null;
    final local = value.toLocal();
    final dateLabel =
        '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
    final isMidnight = local.hour == 0 && local.minute == 0;
    final absoluteLabel = isMidnight
        ? dateLabel
        : '$dateLabel ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final friendlyLabel = friendlyDayLabel(value);
    if (friendlyLabel == null) return absoluteLabel;
    return '$friendlyLabel \u00B7 $absoluteLabel';
  }
}

class _ConfirmationRoster extends StatelessWidget {
  const _ConfirmationRoster({required this.item, required this.members});

  final BoardItem item;
  final List<BoardMember> members;

  @override
  Widget build(BuildContext context) {
    final confirmedIds = item.confirmedUserIds.toSet();
    final confirmedMembers = members
        .where((member) => confirmedIds.contains(member.userId))
        .toList(growable: false);
    final unconfirmedMembers = members
        .where((member) => !confirmedIds.contains(member.userId))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RosterGroup(title: '\uD655\uC778\uD568', members: confirmedMembers),
        const SizedBox(height: 12),
        _RosterGroup(title: '\uBBF8\uD655\uC778', members: unconfirmedMembers),
      ],
    );
  }
}

class _RosterGroup extends StatelessWidget {
  const _RosterGroup({required this.title, required this.members});

  final String title;
  final List<BoardMember> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                MemberAvatar(
                  displayName: member.effectiveName,
                  avatarColor: member.avatarColor,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    member.effectiveName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
