import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/friendly_date.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class BoardItemSection extends StatelessWidget {
  const BoardItemSection({
    super.key,
    required this.title,
    required this.items,
    required this.accentColor,
    required this.accentSoftColor,
    required this.icon,
    this.showCheckbox = false,
    this.onToggle,
    this.emptyText,
    this.pendingTaskIds = const {},
    this.onItemTap,
    this.onTagTap,
  });

  final String title;
  final List<BoardItem> items;
  final Color accentColor;
  final Color accentSoftColor;
  final IconData icon;
  final bool showCheckbox;
  final Future<void> Function(BoardItem item, bool isDone)? onToggle;
  final String? emptyText;
  final Set<String> pendingTaskIds;
  final ValueChanged<BoardItem>? onItemTap;
  final ValueChanged<String>? onTagTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, count: items.length),
        const SizedBox(height: 10),
        if (items.isEmpty)
          SoftCard(
            child: Text(
              emptyText ?? '아직 항목이 없어요.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          )
        else
          ...items.map(
            (item) => BoardItemCard(
              item: item,
              accentColor: accentColor,
              accentSoftColor: accentSoftColor,
              icon: icon,
              showCheckbox: showCheckbox,
              onToggle: onToggle,
              isPending: pendingTaskIds.contains(item.id),
              onTap: onItemTap == null ? null : () => onItemTap!(item),
              onTagTap: onTagTap,
            ),
          ),
      ],
    );
  }
}

class BoardItemCard extends StatelessWidget {
  const BoardItemCard({
    super.key,
    required this.item,
    required this.accentColor,
    required this.accentSoftColor,
    required this.icon,
    this.showCheckbox = false,
    this.onToggle,
    this.isPending = false,
    this.onTap,
    this.onTagTap,
  });

  final BoardItem item;
  final Color accentColor;
  final Color accentSoftColor;
  final IconData icon;
  final bool showCheckbox;
  final Future<void> Function(BoardItem item, bool isDone)? onToggle;
  final bool isPending;
  final VoidCallback? onTap;
  final ValueChanged<String>? onTagTap;

  @override
  Widget build(BuildContext context) {
    final friendlyDateLabel = item.type == BoardItemType.notice
        ? null
        : friendlyDayLabel(item.startsAt ?? item.dueAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: item.isDone ? '완료 취소' : '완료',
                  onPressed: onToggle == null || isPending
                      ? null
                      : () => onToggle!(item, !item.isDone),
                  icon: isPending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          item.isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: item.isDone
                              ? AppColors.primary
                              : AppColors.mutedText,
                        ),
                ),
              ),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentSoftColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isDone ? AppColors.mutedText : null,
                              ),
                        ),
                      ),
                      if (item.isPinned)
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (friendlyDateLabel != null)
                        InfoChip(label: friendlyDateLabel),
                      InfoChip(label: item.timeLabel),
                      InfoChip(label: item.owner),
                      if (item.type == BoardItemType.notice &&
                          item.requiresConfirmation)
                        InfoChip(
                          label:
                              '\uD655\uC778 ${item.confirmationCount}\uBA85 / ${item.isConfirmedByMe ? '\uD655\uC778\uD568' : '\uBBF8\uD655\uC778'}',
                        ),
                      ...item.tags
                          .take(3)
                          .map(
                            (tag) => TagChip(
                              label: tag,
                              compact: true,
                              onTap: onTagTap == null
                                  ? null
                                  : () => onTagTap!(tag),
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        '#$label',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.text),
      ),
    );
  }
}
