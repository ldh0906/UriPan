import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../theme/app_theme.dart';

enum BoardTab {
  today,
  calendar,
  tasks,
  notices,
  members;

  String get label {
    switch (this) {
      case BoardTab.today:
        return '\uC624\uB298';
      case BoardTab.calendar:
        return '\uC77C\uC815';
      case BoardTab.tasks:
        return '\uD560 \uC77C';
      case BoardTab.notices:
        return '\uACF5\uC9C0';
      case BoardTab.members:
        return '\uAC00\uC871';
    }
  }

  IconData get icon {
    switch (this) {
      case BoardTab.today:
        return Icons.dashboard_customize_outlined;
      case BoardTab.calendar:
        return Icons.calendar_month_outlined;
      case BoardTab.tasks:
        return Icons.check_box_outlined;
      case BoardTab.notices:
        return Icons.campaign_outlined;
      case BoardTab.members:
        return Icons.group_outlined;
    }
  }

  BoardItemType? get defaultItemType {
    switch (this) {
      case BoardTab.today:
        return null;
      case BoardTab.calendar:
        return BoardItemType.schedule;
      case BoardTab.tasks:
        return BoardItemType.task;
      case BoardTab.notices:
        return BoardItemType.notice;
      case BoardTab.members:
        return null;
    }
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.surface,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? AppColors.text.withValues(alpha: 0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: card,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.actionLabel = '\uC804\uCCB4 \uBCF4\uAE30',
  });

  final String title;
  final int count;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(
          '$count\uAC1C',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          actionLabel,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class AddItemFab extends StatelessWidget {
  const AddItemFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.text, width: 2),
        ),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('\uCD94\uAC00'),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedTab,
    required this.onSelected,
  });

  final BoardTab selectedTab;
  final ValueChanged<BoardTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(color: AppColors.text.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: BoardTab.values.map((tab) {
            final isSelected = tab == selectedTab;
            final color = isSelected ? AppColors.primary : AppColors.mutedText;
            return SizedBox(
              width: 58,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(tab),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primarySoft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(tab.icon, size: 20, color: color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: color,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
