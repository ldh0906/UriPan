import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/today_board_screen.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GroupSelectionScreen extends StatelessWidget {
  const GroupSelectionScreen({
    super.key,
    required this.boards,
    required this.user,
    required this.settings,
    required this.onCreateBoard,
    required this.onJoinBoard,
    required this.onSelectBoard,
    required this.onUserChanged,
    required this.onSettingsChanged,
    required this.onLogout,
    required this.onResetLocalData,
  });

  static const routeName = '/boards';

  final List<BoardData> boards;
  final UserProfile user;
  final BoardSettings settings;
  final ValueChanged<String> onCreateBoard;
  final ValueChanged<String> onJoinBoard;
  final ValueChanged<BoardData> onSelectBoard;
  final ValueChanged<UserProfile> onUserChanged;
  final ValueChanged<BoardSettings> onSettingsChanged;
  final VoidCallback onLogout;
  final Future<void> Function() onResetLocalData;

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
                      Text('내 보드',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text(
                        '오늘의 활동을 볼 그룹을 선택하세요',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
                MemberAvatar(initials: user.initials, color: user.color),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: boards.isEmpty
                  ? const EmptyState(
                      icon: Icons.dashboard_customize_outlined,
                      title: '아직 보드가 없습니다',
                      message: '보드를 만들거나 초대 코드로 참여해보세요.',
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
            Text('보드 관리', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ActionMiniCard(
                    icon: Icons.add_rounded,
                    title: '만들기',
                    subtitle: '새 공유 보드 시작',
                    onTap: () => _showCreateBoardDialog(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionMiniCard(
                    icon: Icons.group_add_rounded,
                    title: '참여',
                    subtitle: '초대 코드 입력',
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
                  MemberAvatar(
                      initials: user.initials, color: user.color, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          user.email,
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
    var boardName = '새 보드';
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('보드 만들기'),
          content: TextFormField(
            initialValue: boardName,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '보드 이름',
              hintText: '가족, 스터디, 룸메이트...',
            ),
            onChanged: (value) => boardName = value,
            onFieldSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, boardName),
              child: const Text('만들기'),
            ),
          ],
        );
      },
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
    onCreateBoard(trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$trimmed 보드를 만들었습니다.')),
    );
  }

  Future<void> _showJoinBoardDialog(BuildContext context) async {
    var code = 'URIPAN-2024';
    final inviteCode = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('보드 참여'),
          content: TextFormField(
            initialValue: code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '초대 코드',
              hintText: 'URIPAN-2024',
            ),
            onChanged: (value) => code = value,
            onFieldSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, code),
              child: const Text('참여'),
            ),
          ],
        );
      },
    );
    final trimmed = inviteCode?.trim();
    if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
    onJoinBoard(trimmed);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('보드에 참여했습니다.')),
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
              ListTile(
                leading: MemberAvatar(
                  initials: user.initials,
                  color: user.color,
                  size: 38,
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileDialog(context);
                },
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: settings.notificationsEnabled,
                onChanged: (value) => onSettingsChanged(
                  settings.copyWith(notificationsEnabled: value),
                ),
                title: const Text('보드 알림'),
                secondary: const Icon(Icons.notifications_outlined),
              ),
              SwitchListTile.adaptive(
                value: settings.autoArchiveCompletedTasks,
                onChanged: (value) => onSettingsChanged(
                  settings.copyWith(autoArchiveCompletedTasks: value),
                ),
                title: const Text('완료한 할 일 자동 보관'),
                secondary: const Icon(Icons.inventory_2_outlined),
              ),
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('로컬 데모 데이터 초기화'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmReset(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('로그아웃'),
                onTap: () {
                  Navigator.pop(context);
                  onLogout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const WelcomeScreen(),
                    ),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProfileDialog(BuildContext context) async {
    var name = user.name;
    var email = user.email;
    final updated = await showDialog<UserProfile>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('프로필 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: '이름'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                user.copyWith(
                  name: name.trim().isEmpty ? user.name : name.trim(),
                  email: email.trim().isEmpty ? user.email : email.trim(),
                  initials: _initialsFor(name),
                ),
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    if (updated == null || !context.mounted) return;
    onUserChanged(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('프로필을 수정했습니다.')),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로컬 데이터를 초기화할까요?'),
          content: const Text('기본 데모 보드로 되돌리고 로컬 수정 내용을 삭제합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await onResetLocalData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로컬 데이터를 초기화했습니다.')),
    );
  }

  String _initialsFor(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return user.initials;
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
          _BoardMeta(icon: Icons.group_rounded, text: '멤버 ${data.members}명'),
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
