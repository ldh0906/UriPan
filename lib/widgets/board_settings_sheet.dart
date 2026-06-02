import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BoardSettingsSheet extends StatelessWidget {
  const BoardSettingsSheet({
    super.key,
    required this.boardName,
    this.userName,
    required this.onSignOut,
  });

  final String boardName;
  final String? userName;
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

Future<void> showBoardSettingsSheet(
  BuildContext context, {
  required String boardName,
  String? userName,
  required VoidCallback onSignOut,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => BoardSettingsSheet(
      boardName: boardName,
      userName: userName,
      onSignOut: onSignOut,
    ),
  );
}
