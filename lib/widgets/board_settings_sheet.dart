import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class BoardSettingsSheet extends StatelessWidget {
  const BoardSettingsSheet({
    super.key,
    required this.boardName,
    this.userName,
    this.boards = const [],
    this.activeBoardId,
    this.onSelectBoard,
    required this.onSignOut,
  });

  final String boardName;
  final String? userName;
  final List<BoardSummary> boards;
  final String? activeBoardId;
  final ValueChanged<String>? onSelectBoard;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final userName = this.userName;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(boardName, style: Theme.of(context).textTheme.titleLarge),
            if (userName != null && userName.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                userName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
            ],
            if (boards.length > 1) ...[
              const SizedBox(height: 18),
              Text(
                '\uBCF4\uB4DC \uBC14\uAFB8\uAE30',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...boards.map((board) {
                final isActive = board.id == activeBoardId;
                return _BoardSwitcherRow(
                  board: board,
                  isActive: isActive,
                  onTap: isActive || onSelectBoard == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          onSelectBoard!(board.id);
                        },
                );
              }),
            ],
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded),
              title: const Text('\uB85C\uADF8\uC544\uC6C3'),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardSwitcherRow extends StatelessWidget {
  const _BoardSwitcherRow({
    required this.board,
    required this.isActive,
    required this.onTap,
  });

  final BoardSummary board;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? AppColors.primary
        : AppColors.text.withValues(alpha: 0.06);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primarySoft : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isActive ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            board.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        RoleChip(role: board.role),
                        CapacityChip(
                          count: board.memberCount,
                          max: board.maxMembers,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showBoardSettingsSheet(
  BuildContext context, {
  required String boardName,
  String? userName,
  List<BoardSummary> boards = const [],
  String? activeBoardId,
  ValueChanged<String>? onSelectBoard,
  required VoidCallback onSignOut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => BoardSettingsSheet(
      boardName: boardName,
      userName: userName,
      boards: boards,
      activeBoardId: activeBoardId,
      onSelectBoard: onSelectBoard,
      onSignOut: onSignOut,
    ),
  );
}
