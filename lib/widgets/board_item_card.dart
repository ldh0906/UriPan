import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/board_item.dart';
import '../services/board_item_time_label.dart';
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
    this.isOverdue,
    this.onItemTap,
    this.onTagTap,
    this.maxVisible,
    this.onShowMore,
    this.emptyActionLabel,
    this.onEmptyAction,
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
  final bool Function(BoardItem item)? isOverdue;
  final ValueChanged<BoardItem>? onItemTap;
  final ValueChanged<String>? onTagTap;
  final int? maxVisible;
  final VoidCallback? onShowMore;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleItems();
    final hiddenCount = items.length - visibleItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          count: items.length,
          accentColor: accentColor,
          accentSoftColor: accentSoftColor,
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          EmptyState(
            icon: icon,
            message:
                emptyText ??
                '\uC544\uC9C1 \uD56D\uBAA9\uC774 \uC5C6\uC5B4\uC694.',
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          )
        else
          ...visibleItems.map(
            (item) => BoardItemCard(
              item: item,
              accentColor: accentColor,
              accentSoftColor: accentSoftColor,
              icon: icon,
              showCheckbox: showCheckbox,
              onToggle: onToggle,
              isPending: pendingTaskIds.contains(item.id),
              isOverdue: isOverdue?.call(item) ?? false,
              onTap: onItemTap == null ? null : () => onItemTap!(item),
              onTagTap: onTagTap,
            ),
          ),
        if (hiddenCount > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onShowMore,
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text('\uB354\uBCF4\uAE30 +$hiddenCount'),
            ),
          ),
      ],
    );
  }

  List<BoardItem> _visibleItems() {
    final limit = maxVisible;
    if (limit == null || items.length <= limit) return items;
    return items.take(limit < 0 ? 0 : limit).toList(growable: false);
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
    this.isOverdue = false,
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
  final bool isOverdue;
  final VoidCallback? onTap;
  final ValueChanged<String>? onTagTap;

  @override
  Widget build(BuildContext context) {
    final metaBits = <Widget>[];
    if (item.type != BoardItemType.notice) {
      final label = formatBoardItemTimeLabel(
        item.type,
        startsAt: item.startsAt,
        dueAt: item.dueAt,
      );
      if (label != null && label.isNotEmpty) {
        metaBits.add(
          _MetaBit(
            icon: item.type == BoardItemType.task
                ? Icons.schedule_rounded
                : Icons.event_rounded,
            label: label,
          ),
        );
      }
    }
    if (isOverdue) metaBits.add(const _OverdueChip());

    final personLabel = item.assigneeName ?? item.owner;
    if (personLabel.isNotEmpty) {
      metaBits.add(
        _MetaBit(icon: Icons.person_outline_rounded, label: personLabel),
      );
    }

    if (item.type == BoardItemType.notice && item.requiresConfirmation) {
      metaBits.add(
        _MetaBit(
          icon: Icons.how_to_reg_rounded,
          label: '\uD655\uC778 ${item.confirmationCount}\uBA85',
        ),
      );
    }

    if (item.commentCount > 0) {
      metaBits.add(
        _MetaBit(
          icon: Icons.mode_comment_outlined,
          label: '${item.commentCount}',
        ),
      );
    }

    final tagChips = item.tags
        .take(3)
        .map(
          (tag) => TagChip(
            label: tag,
            compact: true,
            onTap: onTagTap == null ? null : () => onTagTap!(tag),
          ),
        )
        .toList();

    final hasDetail = item.detail.trim().isNotEmpty;
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      decoration: item.isDone ? TextDecoration.lineThrough : null,
      color: item.isDone ? AppColors.mutedText : null,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCheckbox && item.type == BoardItemType.task) ...[
                SizedBox(
                  width: 18,
                  child: OverflowBox(
                    minWidth: 28,
                    maxWidth: 28,
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 28,
                        height: 28,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: item.isDone
                          ? '\uC644\uB8CC \uCDE8\uC18C'
                          : '\uC644\uB8CC',
                      onPressed: onToggle == null || isPending
                          ? null
                          : () {
                              if (!item.isDone) HapticFeedback.lightImpact();
                              onToggle!(item, !item.isDone);
                            },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOutBack,
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: isPending
                            ? const SizedBox(
                                key: ValueKey('pending'),
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                item.isDone
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                key: ValueKey(item.isDone),
                                size: 18,
                                color: item.isDone
                                    ? AppColors.primary
                                    : AppColors.mutedText,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ] else ...[
                SizedBox(
                  width: 18,
                  child: Container(
                    constraints: const BoxConstraints.tightFor(width: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            style: titleStyle ?? const TextStyle(),
                            child: Text(item.title),
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
                    if (hasDetail) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.detail,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (metaBits.isNotEmpty)
                      Wrap(spacing: 12, runSpacing: 4, children: metaBits),
                    if (metaBits.isNotEmpty && tagChips.isNotEmpty)
                      const SizedBox(height: 6),
                    if (tagChips.isNotEmpty)
                      Wrap(spacing: 8, runSpacing: 6, children: tagChips),
                  ],
                ),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        '#$label',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: '\uD0DC\uADF8 $label',
        child: ExcludeSemantics(child: chip),
      );
    }

    return Semantics(
      label: '\uD0DC\uADF8 $label',
      button: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ExcludeSemantics(child: chip),
      ),
    );
  }
}

class _MetaBit extends StatelessWidget {
  const _MetaBit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }
}

class _OverdueChip extends StatelessWidget {
  const _OverdueChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: 0.22)),
      ),
      child: Text(
        '\uC9C0\uB0A8',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.tertiary,
          fontWeight: FontWeight.w800,
        ),
      ),
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
        borderRadius: BorderRadius.circular(AppRadius.pill),
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
