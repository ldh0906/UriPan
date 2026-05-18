import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/mock_models.dart';
import '../screens/group_selection_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MembersInviteScreen extends StatelessWidget {
  const MembersInviteScreen({
    super.key,
    required this.boardName,
    required this.inviteCode,
    required this.members,
    required this.settings,
    required this.onSettingsChanged,
    required this.onMemberRoleChanged,
    required this.onMemberRemoved,
    required this.onLeaveBoard,
  });

  static const routeName = '/members';

  final String boardName;
  final String inviteCode;
  final List<FamilyMember> members;
  final BoardSettings settings;
  final ValueChanged<BoardSettings> onSettingsChanged;
  final void Function(FamilyMember member, String role) onMemberRoleChanged;
  final ValueChanged<FamilyMember> onMemberRemoved;
  final VoidCallback onLeaveBoard;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _copyInviteCode(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text('초대'),
      ),
      safeBottom: false,
      child: SingleChildScrollView(
        child: PagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      final boardNavigation =
                          BoardNavigationScope.maybeOf(context);
                      if (boardNavigation != null) {
                        boardNavigation.selectTab(0);
                        return;
                      }

                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                      child: Text('멤버',
                          style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                    onPressed: () => _showBoardActions(context),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SoftCard(
                color: AppColors.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.group_add_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('새 멤버 초대',
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '이 코드를 공유하면 멤버가 $boardName 보드에 참여할 수 있습니다.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '초대 코드',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.mutedText),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                  child: Text(inviteCode,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge)),
                              IconButton(
                                onPressed: () => _copyInviteCode(context),
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: Text('그룹 멤버 (${members.length})',
                          style: Theme.of(context).textTheme.titleMedium)),
                  ActionChip(
                    label: const Text('역할 관리'),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.surfaceVariant),
                    onPressed: () => _showRoleSummary(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MemberTile(
                    member: member,
                    onRoleChanged: onMemberRoleChanged,
                    onRemoved: onMemberRemoved,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: '보드 나가기',
                icon: Icons.logout_rounded,
                variant: ButtonVariant.ghost,
                fullWidth: false,
                onPressed: () => _confirmLeaveBoard(context),
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyInviteCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('초대 코드를 복사했습니다.')),
    );
  }

  void _showRoleSummary(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('멤버 역할'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final member in members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MemberAvatar(
                    initials: member.initials,
                    color: member.color,
                    size: 34,
                  ),
                  title: Text(member.name),
                  subtitle: Text(member.role),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showBoardActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('초대 코드 복사'),
                onTap: () {
                  Navigator.pop(context);
                  _copyInviteCode(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('역할 보기'),
                onTap: () {
                  Navigator.pop(context);
                  _showRoleSummary(context);
                },
              ),
              SwitchListTile.adaptive(
                value: settings.requireNoticeConfirmation,
                onChanged: (value) => onSettingsChanged(
                  settings.copyWith(requireNoticeConfirmation: value),
                ),
                title: const Text('공지 확인 기본값'),
                secondary: const Icon(Icons.fact_check_outlined),
              ),
              SwitchListTile.adaptive(
                value: settings.notificationsEnabled,
                onChanged: (value) => onSettingsChanged(
                  settings.copyWith(notificationsEnabled: value),
                ),
                title: const Text('알림'),
                secondary: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLeaveBoard(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('보드를 나갈까요?'),
          content: Text('$boardName 보드를 나갈까요? 나중에 초대 코드로 다시 참여할 수 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onLeaveBoard();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  GroupSelectionScreen.routeName,
                  (_) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$boardName 보드에서 나갔습니다.')),
                );
              },
              child: const Text('나가기'),
            ),
          ],
        );
      },
    );
  }
}

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.onRoleChanged,
    required this.onRemoved,
  });

  final FamilyMember member;
  final void Function(FamilyMember member, String role) onRoleChanged;
  final ValueChanged<FamilyMember> onRemoved;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          MemberAvatar(initials: member.initials, color: member.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  member.role,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showMemberActions(context, member),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }

  void _showMemberActions(BuildContext context, FamilyMember member) {
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
                  initials: member.initials,
                  color: member.color,
                  size: 34,
                ),
                title: Text(member.name),
                subtitle: Text(member.role),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: const Text('알림 보내기'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${member.name}에게 보낼 알림을 준비했습니다.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('역할 변경'),
                onTap: () {
                  Navigator.pop(context);
                  _showRolePicker(context, member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('보드에서 제거'),
                textColor: AppColors.error,
                iconColor: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveMember(context, member);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRolePicker(BuildContext context, FamilyMember member) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final role in const ['관리자', '멤버', '읽기 전용'])
                ListTile(
                  leading: Icon(
                    role == member.role
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  title: Text(role),
                  onTap: () {
                    Navigator.pop(context);
                    onRoleChanged(member, role);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${member.name}님의 역할을 $role(으)로 변경했습니다.')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveMember(BuildContext context, FamilyMember member) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${member.name}님을 제거할까요?'),
          content: const Text('이 멤버는 더 이상 보드에 표시되지 않습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onRemoved(member);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name}님을 제거했습니다.')),
                );
              },
              child: const Text('제거'),
            ),
          ],
        );
      },
    );
  }
}
