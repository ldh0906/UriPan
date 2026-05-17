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
    required this.members,
    required this.onMemberRoleChanged,
    required this.onMemberRemoved,
    required this.onLeaveBoard,
  });

  static const routeName = '/members';
  static const inviteCode = 'URIPAN-2024';

  final String boardName;
  final List<FamilyMember> members;
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
        label: const Text('Invite'),
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                      child: Text('Members',
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
                            child: Text('Invite New Members',
                                style:
                                    Theme.of(context).textTheme.titleMedium)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Share this code with your group members to let them join this board.',
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
                            'INVITE CODE',
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
                      child: Text('Group Members (${members.length})',
                          style: Theme.of(context).textTheme.titleMedium)),
                  ActionChip(
                    label: const Text('Manage Roles'),
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
                label: 'Leave Board',
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
    await Clipboard.setData(const ClipboardData(text: inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied.')),
    );
  }

  void _showRoleSummary(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Member Roles'),
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
              child: const Text('Done'),
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
                title: const Text('Copy invite code'),
                onTap: () {
                  Navigator.pop(context);
                  _copyInviteCode(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('View roles'),
                onTap: () {
                  Navigator.pop(context);
                  _showRoleSummary(context);
                },
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
          title: const Text('Leave board?'),
          content: Text(
              'Leave $boardName? You can rejoin later with an invite code.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onLeaveBoard();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  GroupSelectionScreen.routeName,
                  (route) => route.isFirst,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Left $boardName.')),
                );
              },
              child: const Text('Leave'),
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
                title: const Text('Send reminder'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Reminder queued for ${member.name}.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Change role'),
                onTap: () {
                  Navigator.pop(context);
                  _showRolePicker(context, member);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: const Text('Remove from board'),
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
              for (final role in const ['Admin', 'Member', 'Viewer'])
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
                      SnackBar(content: Text('${member.name} is now $role.')),
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
          title: Text('Remove ${member.name}?'),
          content:
              const Text('This member will no longer appear on the board.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onRemoved(member);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.name} removed.')),
                );
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
