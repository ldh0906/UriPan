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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ?? AppColors.text.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AppColors.mutedText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.mutedText),
            ),
          ),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('\uCD94\uAC00'),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.displayName,
    required this.avatarColor,
    this.size = 42,
  });

  final String displayName;
  final String avatarColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _avatarColorFromHex(avatarColor);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
      ),
      child: Text(
        _initials(displayName),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length == 1) {
      return String.fromCharCodes(words.first.runes.take(2));
    }
    return words
        .take(2)
        .map((word) => String.fromCharCode(word.runes.first))
        .join();
  }

  Color _avatarColorFromHex(String value) {
    final hex = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return AppColors.primary;
    }
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    return _SmallPill(
      label: isAdmin ? '\uAD00\uB9AC\uC790' : '\uBA64\uBC84',
      color: isAdmin ? AppColors.primarySoft : AppColors.infoSoft,
      textColor: isAdmin ? AppColors.primary : AppColors.info,
    );
  }
}

class CapacityChip extends StatelessWidget {
  const CapacityChip({super.key, required this.count, required this.max});

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return _SmallPill(
      label: '$count/$max\uBA85',
      color: AppColors.surfaceVariant,
      textColor: AppColors.text,
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedTab,
    required this.onSelected,
    this.badges = const {},
  });

  final BoardTab selectedTab;
  final ValueChanged<BoardTab> onSelected;
  final Map<BoardTab, int> badges;

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
            final badgeCount = badges[tab] ?? 0;
            return Semantics(
              button: true,
              selected: isSelected,
              label: tab.label,
              onTap: () => onSelected(tab),
              child: SizedBox(
                width: 58,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelected(tab),
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 28,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primarySoft
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      tab.icon,
                                      size: 20,
                                      color: color,
                                    ),
                                  ),
                                ),
                                if (badgeCount > 0)
                                  Positioned(
                                    top: -4,
                                    right: -6,
                                    child: _BottomNavBadge(
                                      key: Key(
                                        'app-bottom-nav-badge-${tab.name}',
                                      ),
                                      count: badgeCount,
                                    ),
                                  ),
                              ],
                            ),
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
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _BottomNavBadge extends StatelessWidget {
  const _BottomNavBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
