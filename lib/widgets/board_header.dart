import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.onOpenSettings,
    this.onSearchToggle,
  });

  final BoardSummary? board;
  final bool isRefreshing;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddItem;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onSearchToggle;

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
        if (onOpenSettings != null) ...[
          Semantics(
            button: true,
            label: '\uC124\uC815',
            onTap: onOpenSettings,
            child: IconButton.filledTonal(
              onPressed: onOpenSettings,
              tooltip: '\uC124\uC815',
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Semantics(
          button: true,
          label: '\uAC80\uC0C9',
          onTap: onSearchToggle,
          child: IconButton.filledTonal(
            onPressed: onSearchToggle,
            tooltip: '\uAC80\uC0C9',
            icon: const Icon(Icons.search_rounded),
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
    this.currentUserId,
    this.activeInvite,
    this.onCreateInvite,
    this.onRegenerateInvite,
    this.onRevokeInvite,
    this.onLeaveBoard,
    this.onUpdateMemberRole,
    this.onRemoveMember,
  });

  final BoardSummary? board;
  final List<BoardMember> members;
  final String? currentUserId;
  final BoardInvite? activeInvite;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onRegenerateInvite;
  final VoidCallback? onRevokeInvite;
  final Future<void> Function()? onLeaveBoard;
  final Future<void> Function(String userId, String role)? onUpdateMemberRole;
  final Future<void> Function(String userId)? onRemoveMember;

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
                ...members.map(
                  (member) => _MemberRow(
                    member: member,
                    canManage:
                        isAdmin &&
                        member.userId != currentUserId &&
                        (onUpdateMemberRole != null || onRemoveMember != null),
                    onUpdateRole: onUpdateMemberRole == null
                        ? null
                        : (role) => onUpdateMemberRole!(member.userId, role),
                    onRemove: onRemoveMember == null
                        ? null
                        : () => onRemoveMember!(member.userId),
                  ),
                ),
              if (isAdmin) ...[
                const SizedBox(height: 14),
                InviteCodePanel(
                  invite: activeInvite,
                  isFull: memberCount >= maxMembers,
                  onRegenerate: onRegenerateInvite ?? onCreateInvite,
                  onRevoke: onRevokeInvite,
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onLeaveBoard == null
                    ? null
                    : () => _confirmLeaveBoard(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('\uBCF4\uB4DC \uB098\uAC00\uAE30'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLeaveBoard(BuildContext context) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\uBCF4\uB4DC \uB098\uAC00\uAE30'),
        content: const Text(
          '\uC774 \uBCF4\uB4DC\uC5D0\uC11C \uB098\uAC08\uAE4C\uC694?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uB098\uAC00\uAE30'),
          ),
        ],
      ),
    );
    if (shouldLeave == true) {
      await onLeaveBoard?.call();
    }
  }
}

class InviteCodePanel extends StatelessWidget {
  const InviteCodePanel({
    super.key,
    required this.invite,
    required this.isFull,
    this.onRegenerate,
    this.onRevoke,
  });

  final BoardInvite? invite;
  final bool isFull;
  final VoidCallback? onRegenerate;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final invite = this.invite;
    final canRegenerate = !isFull && onRegenerate != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.ios_share_rounded, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '\uCD08\uB300\uCF54\uB4DC',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (invite == null)
            Text(
              '\uCD08\uB300\uCF54\uB4DC \uC5C6\uC74C',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            SelectableText(
              invite.code,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                letterSpacing: 0,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\uB9CC\uB8CC: ${_formatExpiry(invite.expiresAt)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
          if (isFull) ...[
            const SizedBox(height: 8),
            Text(
              '\uC815\uC6D0\uC774 \uCC28\uC11C \uC0C8 \uCD08\uB300\uCF54\uB4DC\uB97C \uB9CC\uB4E4 \uC218 \uC5C6\uC5B4\uC694.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (invite != null)
                FilledButton.tonalIcon(
                  onPressed: () => _copyInvite(context, invite.code),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('\uBCF5\uC0AC'),
                ),
              FilledButton.icon(
                onPressed: canRegenerate ? onRegenerate : null,
                icon: Icon(
                  invite == null ? Icons.add_rounded : Icons.autorenew_rounded,
                ),
                label: Text(
                  invite == null
                      ? '\uB9CC\uB4E4\uAE30'
                      : '\uB2E4\uC2DC \uB9CC\uB4E4\uAE30',
                ),
              ),
              if (invite != null)
                TextButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('\uCDE8\uC18C'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyInvite(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('\uBCF5\uC0AC\uB410\uC5B4\uC694.')),
    );
  }

  String _formatExpiry(DateTime value) {
    final local = value.toLocal();
    return '${local.year}.${_two(local.month)}.${_two(local.day)} '
        '${_two(local.hour)}:${_two(local.minute)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

enum _MemberAction { promote, demote, remove }

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.canManage,
    this.onUpdateRole,
    this.onRemove,
  });

  final BoardMember member;
  final bool canManage;
  final Future<void> Function(String role)? onUpdateRole;
  final Future<void> Function()? onRemove;

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
          if (canManage) ...[
            const SizedBox(width: 2),
            Semantics(
              button: true,
              label: '\uBA64\uBC84 \uAD00\uB9AC',
              child: PopupMenuButton<_MemberAction>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: '\uBA64\uBC84 \uAD00\uB9AC',
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) => [
                  if (!member.isAdmin && onUpdateRole != null)
                    const PopupMenuItem(
                      value: _MemberAction.promote,
                      child: Text('\uAD00\uB9AC\uC790\uB85C'),
                    ),
                  if (member.isAdmin && onUpdateRole != null)
                    const PopupMenuItem(
                      value: _MemberAction.demote,
                      child: Text('\uBA64\uBC84\uB85C'),
                    ),
                  if (onRemove != null)
                    const PopupMenuItem(
                      value: _MemberAction.remove,
                      child: Text('\uB0B4\uBCF4\uB0B4\uAE30'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, _MemberAction action) async {
    switch (action) {
      case _MemberAction.promote:
        await onUpdateRole?.call('admin');
        return;
      case _MemberAction.demote:
        final confirmed = await _confirmMemberAction(
          context,
          title: '\uBA64\uBC84\uB85C \uBCC0\uACBD',
          content:
              '${member.displayName}\uB2D8\uC744 \uBA64\uBC84\uB85C \uBCC0\uACBD\uD560\uAE4C\uC694?',
          actionLabel: '\uBCC0\uACBD',
        );
        if (confirmed) await onUpdateRole?.call('member');
        return;
      case _MemberAction.remove:
        final confirmed = await _confirmMemberAction(
          context,
          title: '\uB0B4\uBCF4\uB0B4\uAE30',
          content:
              '${member.displayName}\uB2D8\uC744 \uBCF4\uB4DC\uC5D0\uC11C \uB0B4\uBCF4\uB0BC\uAE4C\uC694?',
          actionLabel: '\uB0B4\uBCF4\uB0B4\uAE30',
        );
        if (confirmed) await onRemove?.call();
        return;
    }
  }

  Future<bool> _confirmMemberAction(
    BuildContext context, {
    required String title,
    required String content,
    required String actionLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
