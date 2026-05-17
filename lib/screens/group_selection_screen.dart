import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';
import '../screens/add_item_selector_screen.dart';
import '../screens/today_board_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({super.key});

  static const routeName = '/boards';

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: PagePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Boards', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        "Select a group to view today's activities",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                const MemberAvatar(initials: 'JD', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: MockData.boards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return BoardCard(data: MockData.boards[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('Manage Boards', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ActionMiniCard(
                    icon: Icons.add_rounded,
                    title: 'Create',
                    subtitle: 'Start a new shared board',
                    onTap: () => Navigator.pushNamed(context, AddItemSelectorScreen.routeName),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionMiniCard(
                    icon: Icons.group_add_rounded,
                    title: 'Join',
                    subtitle: 'Enter an invite code',
                    onTap: () => Navigator.pushNamed(context, AddItemSelectorScreen.routeName),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SoftCard(
              padding: const EdgeInsets.all(14),
              color: AppColors.primarySoft,
              child: Row(
                children: [
                  const MemberAvatar(initials: 'JD', color: AppColors.primary, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('John Doe', style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          'john.doe@example.com',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardCard extends StatelessWidget {
  const BoardCard({super.key, required this.data});

  final BoardData data;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.pushReplacementNamed(context, TodayBoardScreen.routeName),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(data.name, style: Theme.of(context).textTheme.titleLarge)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(data.role, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BoardMeta(icon: Icons.group_rounded, text: '${data.members} members'),
          _BoardMeta(icon: Icons.calendar_today_rounded, text: data.schedules),
          _BoardMeta(icon: Icons.check_circle_outline_rounded, text: data.tasks),
          _BoardMeta(icon: Icons.campaign_rounded, text: data.notices),
        ],
      ),
    );
  }
}

class _BoardMeta extends StatelessWidget {
  const _BoardMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.mutedText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class ActionMiniCard extends StatelessWidget {
  const ActionMiniCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
