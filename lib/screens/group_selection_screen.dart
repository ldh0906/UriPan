import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/today_board_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({
    super.key,
    required this.boards,
    required this.onCreateBoard,
    required this.onJoinBoard,
    required this.onSelectBoard,
  });

  static const routeName = '/boards';

  final List<BoardData> boards;
  final ValueChanged<String> onCreateBoard;
  final ValueChanged<String> onJoinBoard;
  final ValueChanged<BoardData> onSelectBoard;

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
                      Text('Your Boards',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        "Select a group to view today's activities",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                const MemberAvatar(initials: 'JD', color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: boards.isEmpty
                  ? const EmptyState(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'No boards yet',
                      message: 'Create or join a board to start sharing.',
                    )
                  : ListView.separated(
                      itemCount: boards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return BoardCard(
                          data: boards[index],
                          onTap: () {
                            onSelectBoard(boards[index]);
                            Navigator.pushReplacementNamed(
                              context,
                              TodayBoardScreen.routeName,
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Text('Manage Boards',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ActionMiniCard(
                    icon: Icons.add_rounded,
                    title: 'Create',
                    subtitle: 'Start a new shared board',
                    onTap: () => _showCreateBoardDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionMiniCard(
                    icon: Icons.group_add_rounded,
                    title: 'Join',
                    subtitle: 'Enter an invite code',
                    onTap: () => _showJoinBoardDialog(context),
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
                  const MemberAvatar(
                      initials: 'JD', color: AppColors.primary, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('John Doe',
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          'john.doe@example.com',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showAccountSettings(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateBoardDialog(BuildContext context) async {
    var boardName = 'New Board';
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create board'),
          content: TextFormField(
            initialValue: boardName,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Board name',
              hintText: 'Family, study, roommates...',
            ),
            onChanged: (value) => boardName = value,
            onFieldSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, boardName),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
    onCreateBoard(trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$trimmed created.')),
    );
  }

  Future<void> _showJoinBoardDialog(BuildContext context) async {
    var code = 'URIPAN-2024';
    final inviteCode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Join board'),
          content: TextFormField(
            initialValue: code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Invite code',
              hintText: 'URIPAN-2024',
            ),
            onChanged: (value) => code = value,
            onFieldSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, code),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
    final trimmed = inviteCode?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
    onJoinBoard(trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Board joined.')),
    );
  }

  void _showAccountSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: MemberAvatar(
                  initials: 'JD',
                  color: AppColors.primary,
                  size: 38,
                ),
                title: Text('John Doe'),
                subtitle: Text('john.doe@example.com'),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: true,
                onChanged: (_) {},
                title: const Text('Board notifications'),
                secondary: const Icon(Icons.notifications_outlined),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Log out'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No changes made.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class BoardCard extends StatelessWidget {
  const BoardCard({super.key, required this.data, required this.onTap});

  final BoardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(data.name,
                      style: Theme.of(context).textTheme.titleLarge)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(data.role,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BoardMeta(
              icon: Icons.group_rounded, text: '${data.members} members'),
          _BoardMeta(icon: Icons.calendar_today_rounded, text: data.schedules),
          _BoardMeta(
              icon: Icons.check_circle_outline_rounded, text: data.tasks),
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
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}
