import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/add_item_selector_screen.dart';
import '../screens/calendar_view_screen.dart';
import '../screens/item_detail_edit_screen.dart';
import '../screens/members_invite_screen.dart';
import '../screens/notices_board_screen.dart';
import '../screens/tasks_list_screen.dart';
import '../screens/today_board_screen.dart';
import '../theme/app_theme.dart';

class ScreenShell extends StatelessWidget {
  const ScreenShell({
    super.key,
    required this.child,
    this.bottomNavigation,
    this.floatingActionButton,
    this.safeBottom = true,
  });

  final Widget child;
  final Widget? bottomNavigation;
  final Widget? floatingActionButton;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: safeBottom,
        child: child,
      ),
      bottomNavigationBar: bottomNavigation,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: child,
    );
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
            color: borderColor ?? Colors.black.withValues(alpha: 0.04)),
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

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: card,
    );
  }
}

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 76});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.dashboard_customize_rounded,
        color: AppColors.primary,
        size: size * 0.46,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = true,
    this.icon,
    this.variant = ButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final IconData? icon;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final minimumSize = Size(fullWidth ? double.infinity : 0, 52);
    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    switch (variant) {
      case ButtonVariant.primary:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(minimumSize: minimumSize),
          child: child,
        );
      case ButtonVariant.outline:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(minimumSize: minimumSize),
          child: child,
        );
      case ButtonVariant.ghost:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: minimumSize,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: child,
        );
      case ButtonVariant.destructive:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.dangerSoft,
            foregroundColor: AppColors.error,
            minimumSize: minimumSize,
          ),
          child: child,
        );
    }
  }
}

enum ButtonVariant { primary, outline, ghost, destructive }

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.label,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.leadingIcon,
    this.trailingIcon,
    this.onTap,
    this.maxLines = 1,
    this.obscureText = false,
    this.readOnly = false,
  }) : assert(
          controller == null || initialValue == null,
          'Use either controller or initialValue, not both.',
        );

  final String? label;
  final String hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final int maxLines;
  final bool obscureText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      onChanged: onChanged,
      onTap: onTap,
      maxLines: maxLines,
      obscureText: obscureText,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label?.isEmpty ?? true ? null : label,
        hintText: hint,
        prefixIcon: leadingIcon == null ? null : Icon(leadingIcon),
        suffixIcon: trailingIcon == null ? null : Icon(trailingIcon),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 42,
    this.textColor = Colors.white,
  });

  final String initials;
  final Color color;
  final double size;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.routeName,
    this.icon,
  });

  final String title;
  final String? routeName;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.mutedText, size: 18),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (routeName != null)
          TextButton(
            onPressed: () => Navigator.pushNamed(context, routeName!),
            child: const Text('전체 보기'),
          ),
      ],
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _routes = [
    TodayBoardScreen.routeName,
    CalendarViewScreen.routeName,
    TasksListScreen.routeName,
    NoticesBoardScreen.routeName,
    MembersInviteScreen.routeName,
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        Navigator.pushReplacementNamed(context, _routes[index]);
      },
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '오늘'),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: '달력',
        ),
        NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: '할 일'),
        NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: '공지'),
        NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: '멤버'),
      ],
    );
  }
}

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.item,
    this.compact = false,
    this.onTap,
  });

  final ScheduleItemData item;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.all(compact ? 14 : 16),
      onTap: onTap,
      child: Row(
        children: [
          MemberAvatar(initials: item.initials, color: item.color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  compact ? item.timeRange : '${item.date} • ${item.timeRange}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          Icon(
            onTap == null ? Icons.chevron_right_rounded : Icons.edit_rounded,
            color: AppColors.mutedText.withValues(alpha: 0.8),
            size: onTap == null ? null : 18,
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.item,
    required this.onChanged,
    this.compact = false,
    this.onTap,
  });

  final TaskItemData item;
  final ValueChanged<bool?> onChanged;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.all(compact ? 14 : 16),
      onTap: onTap,
      color: item.isDone
          ? AppColors.surface.withValues(alpha: 0.72)
          : AppColors.surface,
      child: Row(
        children: [
          Checkbox(
            value: item.isDone,
            activeColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: onChanged,
          ),
          const SizedBox(width: 8),
          MemberAvatar(initials: item.initials, color: item.color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration:
                            item.isDone ? TextDecoration.lineThrough : null,
                        color:
                            item.isDone ? AppColors.mutedText : AppColors.text,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.assignee} • ${item.dueDate}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.mutedText),
                ),
                if (item.memo != null && !compact) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.memo!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.edit_rounded,
                color: AppColors.mutedText.withValues(alpha: 0.8), size: 18),
          ],
        ],
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.item,
    required this.memberCount,
    required this.onConfirm,
    this.compact = false,
    this.onTap,
  });

  final NoticeItemData item;
  final int memberCount;
  final VoidCallback onConfirm;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      borderColor:
          item.isImportant ? AppColors.warning.withValues(alpha: 0.32) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.isImportant
                      ? AppColors.warningSoft
                      : AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.isImportant
                      ? Icons.priority_high_rounded
                      : Icons.campaign_rounded,
                  color: item.isImportant ? AppColors.warning : AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      item.date,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.edit_rounded,
                    color: AppColors.mutedText.withValues(alpha: 0.8), size: 18)
              else if (item.isImportant)
                const Icon(Icons.push_pin_rounded,
                    color: AppColors.warning, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.preview,
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.text.withValues(alpha: 0.88)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.confirmedCount}/$memberCount명 확인',
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.mutedText),
                ),
              ),
              TextButton.icon(
                onPressed: onConfirm,
                icon: Icon(
                  item.confirmedByMe
                      ? Icons.verified_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                ),
                label: Text(item.confirmedByMe ? '확인됨' : '확인'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class AddItemFab extends StatelessWidget {
  const AddItemFab({super.key, required this.label, this.itemType});

  final String label;
  final BoardItemType? itemType;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        if (itemType == null) {
          Navigator.pushNamed(context, AddItemSelectorScreen.routeName);
          return;
        }

        Navigator.pushNamed(
          context,
          ItemDetailEditScreen.routeName,
          arguments: itemType,
        );
      },
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(label),
    );
  }
}
