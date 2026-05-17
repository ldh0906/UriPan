import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class MembersInviteScreen extends StatelessWidget {
  const MembersInviteScreen({super.key, required this.members});

  static const routeName = '/members';

  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 4),
      floatingActionButton: const AddItemFab(label: 'Add Member'),
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
                  Expanded(child: Text('Members', style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded)),
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
                          child: const Icon(Icons.group_add_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Invite New Members', style: Theme.of(context).textTheme.titleMedium)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Share this code with your group members to let them join this board.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVITE CODE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.mutedText),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: Text('URIPAN-2024', style: Theme.of(context).textTheme.titleLarge)),
                              IconButton(onPressed: () {}, icon: const Icon(Icons.copy_rounded)),
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
                  Expanded(child: Text('Group Members (${members.length})', style: Theme.of(context).textTheme.titleMedium)),
                  const Chip(
                    label: Text('Manage Roles'),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.surfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...members.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MemberTile(member: member),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Leave Board',
                icon: Icons.logout_rounded,
                variant: ButtonVariant.ghost,
                fullWidth: false,
                onPressed: () {},
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberTile extends StatelessWidget {
  const MemberTile({super.key, required this.member});

  final FamilyMember member;

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
                Text(member.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  member.role,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded)),
        ],
      ),
    );
  }
}
