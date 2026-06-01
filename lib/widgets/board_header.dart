import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class BoardHeader extends StatelessWidget {
  const BoardHeader({
    super.key,
    required this.board,
    required this.isRefreshing,
    this.onCreateInvite,
    this.onRefresh,
    this.onAddItem,
  });

  final BoardSummary? board;
  final bool isRefreshing;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board?.name ?? '우리집',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '오늘 보드',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: isRefreshing ? null : onRefresh,
          tooltip: '새로고침',
          icon: isRefreshing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: onCreateInvite,
          tooltip: board?.isAdmin == true ? '초대코드' : '가족',
          icon: Icon(
            board?.isAdmin == true
                ? Icons.ios_share_rounded
                : Icons.group_outlined,
          ),
        ),
        const SizedBox(width: 8),
        AddItemFab(onPressed: onAddItem),
      ],
    );
  }
}

class PulseCard extends StatelessWidget {
  const PulseCard({
    super.key,
    required this.schedules,
    required this.openTasks,
    required this.notices,
  });

  final int schedules;
  final int openTasks;
  final int notices;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: AppColors.primarySoft,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.monitor_heart_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 상황', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '일정 $schedules개, 남은 할 일 $openTasks개, 공지 $notices개가 있어요.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MembersPanel extends StatelessWidget {
  const MembersPanel({
    super.key,
    required this.board,
    this.members = const [],
    this.onCreateInvite,
  });

  final BoardSummary? board;
  final List<BoardMember> members;
  final VoidCallback? onCreateInvite;

  @override
  Widget build(BuildContext context) {
    final memberCount = members.isEmpty
        ? board?.memberCount ?? 1
        : members.length;
    final maxMembers = board?.maxMembers ?? 4;
    final isAdmin = board?.isAdmin == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SectionHeader(title: '\uAC00\uC871', count: memberCount),
            ),
            CapacityChip(count: memberCount, max: maxMembers),
          ],
        ),
        const SizedBox(height: 10),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board?.name ?? '\uC6B0\uB9AC\uC9D1',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              if (members.isEmpty)
                Text(
                  '\uC544\uC9C1 \uD45C\uC2DC\uD560 \uAC00\uC871\uC774 \uC5C6\uC5B4\uC694.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                )
              else
                ...members.map((member) => _MemberRow(member: member)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: isAdmin ? onCreateInvite : null,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(
                  isAdmin
                      ? '\uCD08\uB300\uCF54\uB4DC \uB9CC\uB4E4\uAE30'
                      : '\uAD00\uB9AC\uC790\uB9CC \uCD08\uB300\uD560 \uC218 \uC788\uC5B4\uC694',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final BoardMember member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          MemberAvatar(
            displayName: member.displayName,
            avatarColor: member.avatarColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: 8),
          RoleChip(role: member.role),
        ],
      ),
    );
  }
}
