import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/item_detail_edit_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AddItemSelectorScreen extends StatelessWidget {
  const AddItemSelectorScreen({super.key});

  static const routeName = '/add';

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: PagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('새 항목 추가', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '그룹과 무엇을 공유할까요?',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.mutedText),
            ),
            const SizedBox(height: 24),
            ActionItemCard(
              icon: Icons.calendar_today_rounded,
              title: '일정',
              subtitle: '약속, 모임, 알림',
              color: AppColors.info,
              background: AppColors.infoSoft,
              onTap: () => _openEditor(context, BoardItemType.schedule),
            ),
            const SizedBox(height: 12),
            ActionItemCard(
              icon: Icons.check_circle_outline_rounded,
              title: '할 일',
              subtitle: '해야 할 일과 담당 업무',
              color: AppColors.success,
              background: AppColors.successSoft,
              onTap: () => _openEditor(context, BoardItemType.task),
            ),
            const SizedBox(height: 12),
            ActionItemCard(
              icon: Icons.campaign_rounded,
              title: '공지',
              subtitle: '중요한 안내와 공지사항',
              color: AppColors.warning,
              background: AppColors.warningSoft,
              onTap: () => _openEditor(context, BoardItemType.notice),
            ),
            const Spacer(),
            PrimaryButton(
              label: '취소',
              variant: ButtonVariant.ghost,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, BoardItemType type) {
    Navigator.pushNamed(
      context,
      ItemDetailEditScreen.routeName,
      arguments: type,
    );
  }
}

class ActionItemCard extends StatelessWidget {
  const ActionItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
        ],
      ),
    );
  }
}
