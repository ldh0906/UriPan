import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/item_detail_edit_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class NoticesBoardScreen extends StatefulWidget {
  const NoticesBoardScreen({
    super.key,
    required this.boardName,
    required this.notices,
    required this.members,
    required this.onNoticeConfirmed,
    required this.onNoticeDeleted,
  });

  static const routeName = '/notices';

  final String boardName;
  final List<NoticeItemData> notices;
  final List<FamilyMember> members;
  final void Function(NoticeItemData notice) onNoticeConfirmed;
  final ValueChanged<NoticeItemData> onNoticeDeleted;

  @override
  State<NoticesBoardScreen> createState() => _NoticesBoardScreenState();
}

class _NoticesBoardScreenState extends State<NoticesBoardScreen> {
  int selectedTab = 0;
  bool isSearching = false;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredNotices = switch (selectedTab) {
      1 => widget.notices.where((notice) => !notice.confirmedByMe).toList(),
      2 => widget.notices.where((notice) => notice.isImportant).toList(),
      _ => widget.notices,
    };
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final visibleNotices = normalizedQuery.isEmpty
        ? filteredNotices
        : filteredNotices
            .where(
              (notice) =>
                  notice.title.toLowerCase().contains(normalizedQuery) ||
                  notice.preview.toLowerCase().contains(normalizedQuery),
            )
            .toList();

    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 3),
      safeBottom: false,
      floatingActionButton: const AddItemFab(
        label: '새 공지',
        itemType: BoardItemType.notice,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('공지',
                            style: Theme.of(context).textTheme.headlineSmall)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isSearching = !isSearching;
                          if (!isSearching) {
                            searchQuery = '';
                          }
                        });
                      },
                      icon: Icon(isSearching
                          ? Icons.close_rounded
                          : Icons.search_rounded),
                    ),
                  ],
                ),
                Text(
                  '그룹: ${widget.boardName}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.mutedText),
                ),
                if (isSearching) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    hint: '공지 검색',
                    leadingIcon: Icons.search_rounded,
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ],
                const SizedBox(height: 18),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('전체 공지')),
                    ButtonSegment(value: 1, label: Text('미확인')),
                    ButtonSegment(value: 2, label: Text('중요')),
                  ],
                  selected: {selectedTab},
                  onSelectionChanged: (value) =>
                      setState(() => selectedTab = value.first),
                  showSelectedIcon: false,
                ),
              ],
            ),
          ),
          Expanded(
            child: visibleNotices.isEmpty
                ? const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: '공지 없음',
                    message: '다른 필터나 검색어를 사용해보세요.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 106),
                    itemCount: visibleNotices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notice = visibleNotices[index];
                      return Dismissible(
                        key: ValueKey(notice.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) {
                          widget.onNoticeDeleted(notice);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${notice.title} 공지를 삭제했습니다.')),
                          );
                        },
                        child: NoticeCard(
                          item: notice,
                          memberCount: widget.members.length,
                          onTap: () => Navigator.pushNamed(
                            context,
                            ItemDetailEditScreen.routeName,
                            arguments:
                                BoardItemEditArguments.fromNotice(notice),
                          ),
                          onConfirm: () => widget.onNoticeConfirmed(notice),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
