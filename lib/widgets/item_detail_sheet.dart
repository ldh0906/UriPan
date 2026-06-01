import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../theme/app_theme.dart';
import 'board_item_card.dart';

class ItemDetailSheet extends StatelessWidget {
  const ItemDetailSheet({
    super.key,
    required this.item,
    required this.isPending,
    this.onToggle,
    this.onConfirm,
    this.onDelete,
  });

  final BoardItem item;
  final bool isPending;
  final Future<void> Function(bool isDone)? onToggle;
  final Future<void> Function(bool confirmed)? onConfirm;
  final Future<void> Function()? onDelete;

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
                    tooltip: '닫기',
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
                  InfoChip(label: dateLabel ?? item.timeLabel),
                  if (item.isPinned) const InfoChip(label: '고정'),
                  if (item.type == BoardItemType.task)
                    InfoChip(label: item.isDone ? '완료됨' : '미완료'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                detail.isEmpty ? '메모가 없어요.' : detail,
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
                  label: Text(item.isDone ? '완료 취소' : '완료하기'),
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
              ],
              if (onDelete != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('삭제'),
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
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
