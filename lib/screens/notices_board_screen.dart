import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class NoticesBoardScreen extends StatefulWidget {
  const NoticesBoardScreen({
    super.key,
    required this.notices,
    required this.members,
    required this.onNoticeConfirmed,
  });

  static const routeName = '/notices';

  final List<NoticeItemData> notices;
  final List<FamilyMember> members;
  final void Function(NoticeItemData notice) onNoticeConfirmed;

  @override
  State<NoticesBoardScreen> createState() => _NoticesBoardScreenState();
}

class _NoticesBoardScreenState extends State<NoticesBoardScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final visibleNotices = switch (selectedTab) {
      1 => widget.notices.where((notice) => !notice.confirmedByMe).toList(),
      2 => widget.notices.where((notice) => notice.isImportant).toList(),
      _ => widget.notices,
    };

    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 3),
      safeBottom: false,
      floatingActionButton: const AddItemFab(label: 'New Notice'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Notices', style: Theme.of(context).textTheme.headlineSmall)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
                  ],
                ),
                Text(
                  'Group: Sweet Home',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                ),
                const SizedBox(height: 18),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All Notices')),
                    ButtonSegment(value: 1, label: Text('Unread')),
                    ButtonSegment(value: 2, label: Text('Pinned')),
                  ],
                  selected: {selectedTab},
                  onSelectionChanged: (value) => setState(() => selectedTab = value.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 106),
              itemCount: visibleNotices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notice = visibleNotices[index];
                return NoticeCard(
                  item: notice,
                  memberCount: widget.members.length,
                  onConfirm: () => widget.onNoticeConfirmed(notice),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
