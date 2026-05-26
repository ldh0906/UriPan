import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/board_repository.dart';
import '../widgets/section_panel.dart';

class TodayBoardScreen extends StatelessWidget {
  const TodayBoardScreen({super.key, required this.repository});

  final BoardRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BoardItem>>(
      future: repository.loadTodayItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <BoardItem>[];
        final schedules = _itemsOfType(items, BoardItemType.schedule);
        final tasks = _itemsOfType(items, BoardItemType.task);
        final notices = _itemsOfType(items, BoardItemType.notice);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    openTasks: tasks.where((item) => !item.isDone).length,
                    notices: notices.length,
                  ),
                  const SizedBox(height: 12),
                  SectionPanel(
                    title: '일정',
                    count: schedules.length,
                    icon: Icons.event_available,
                    children: schedules.map(_BoardTile.new).toList(),
                  ),
                  const SizedBox(height: 12),
                  SectionPanel(
                    title: '할 일',
                    count: tasks.length,
                    icon: Icons.check_circle_outline,
                    children: tasks.map(_BoardTile.new).toList(),
                  ),
                  const SizedBox(height: 12),
                  SectionPanel(
                    title: '공지',
                    count: notices.length,
                    icon: Icons.campaign_outlined,
                    children: notices.map(_BoardTile.new).toList(),
                  ),
                  const SizedBox(height: 16),
                  const _ActionRow(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<BoardItem> _itemsOfType(
    List<BoardItem> items,
    BoardItemType type,
  ) {
    return items.where((item) => item.type == type).toList(growable: false);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.openTasks, required this.notices});

  final int openTasks;
  final int notices;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UriPan', style: textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          '오늘 보드',
          style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '열린 할 일 $openTasks개, 확인할 공지 $notices개가 있습니다.',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile(this.item);

  final BoardItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              item.timeLabel,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (item.isPinned)
                      Icon(
                        Icons.push_pin,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(item.detail),
                const SizedBox(height: 3),
                Text(
                  item.owner,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('추가'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: '멤버',
          icon: const Icon(Icons.group_outlined),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () {},
          tooltip: '설정',
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}
