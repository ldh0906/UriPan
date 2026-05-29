import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/board_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TodayBoardScreen extends StatefulWidget {
  const TodayBoardScreen({
    super.key,
    this.repository,
    this.items,
    this.board,
    this.onRefresh,
    this.onAddItem,
    this.onCreateInvite,
    this.onCompleteTask,
  }) : assert(
         items != null || repository != null,
         'Provide items for controlled rendering or repository for fallback loading.',
       );

  final BoardRepository? repository;
  final List<BoardItem>? items;
  final BoardSummary? board;
  final VoidCallback? onRefresh;
  final VoidCallback? onAddItem;
  final VoidCallback? onCreateInvite;
  final Future<void> Function(BoardItem item, bool isDone)? onCompleteTask;

  @override
  State<TodayBoardScreen> createState() => _TodayBoardScreenState();
}

class _TodayBoardScreenState extends State<TodayBoardScreen> {
  late Future<List<BoardItem>>? _itemsFuture = _loadItems();

  @override
  void didUpdateWidget(TodayBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != null) {
      _itemsFuture = null;
      return;
    }

    _itemsFuture = _loadItems();
  }

  Future<List<BoardItem>>? _loadItems() {
    if (widget.items != null) return null;
    return widget.repository!.loadTodayItems(boardId: widget.board?.id);
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items != null) return _buildBoard(context, items);

    return FutureBuilder<List<BoardItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) =>
          _buildBoard(context, snapshot.data ?? const <BoardItem>[]),
    );
  }

  Widget _buildBoard(BuildContext context, List<BoardItem> items) {
    final schedules = _itemsOfType(items, BoardItemType.schedule);
    final tasks = _itemsOfType(items, BoardItemType.task);
    final notices = _itemsOfType(items, BoardItemType.notice);
    final openTasks = tasks.where((item) => !item.isDone).length;

    return Scaffold(
      floatingActionButton: AddItemFab(onPressed: widget.onAddItem),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const AppBottomNav(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      board: widget.board,
                      onCreateInvite: widget.onCreateInvite,
                    ),
                    const SizedBox(height: 20),
                    _PulseCard(
                      schedules: schedules.length,
                      openTasks: openTasks,
                      notices: notices.length,
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: '\uC624\uB298 \uC77C\uC815',
                      count: schedules.length,
                    ),
                    const SizedBox(height: 10),
                    ...schedules.map(
                      (item) => _ItemCard(
                        item: item,
                        accentColor: AppColors.primary,
                        accentSoftColor: AppColors.primarySoft,
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionHeader(title: '\uD560 \uC77C', count: tasks.length),
                    const SizedBox(height: 10),
                    ...tasks.map(
                      (item) => _ItemCard(
                        item: item,
                        accentColor: AppColors.tertiary,
                        accentSoftColor: AppColors.warningSoft,
                        icon: Icons.check_rounded,
                        showCheckbox: true,
                        onToggle: widget.onCompleteTask,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SectionHeader(title: '\uACF5\uC9C0', count: notices.length),
                    const SizedBox(height: 10),
                    ...notices.map(
                      (item) => _ItemCard(
                        item: item,
                        accentColor: AppColors.success,
                        accentSoftColor: AppColors.successSoft,
                        icon: Icons.campaign_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BoardItem> _itemsOfType(List<BoardItem> items, BoardItemType type) {
    return items.where((item) => item.type == type).toList(growable: false);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.board, this.onCreateInvite});

  final BoardSummary? board;
  final VoidCallback? onCreateInvite;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board?.name ?? '\uC6B0\uB9AC\uC9D1',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                '\uC624\uB298 \uBCF4\uB4DC',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onCreateInvite,
          tooltip: board?.isAdmin == true
              ? '\uCD08\uB300\uCF54\uB4DC'
              : '\uAC00\uC871',
          icon: Icon(
            board?.isAdmin == true
                ? Icons.ios_share_rounded
                : Icons.group_outlined,
          ),
        ),
      ],
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({
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
                Text(
                  '\uC624\uB298\uC758 \uC0C1\uD669',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '\uC77C\uC815 $schedules\uAC1C, \uB0A8\uC740 \uD560 \uC77C $openTasks\uAC1C, \uACF5\uC9C0 $notices\uAC1C\uAC00 \uC788\uC5B4\uC694.',
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.accentColor,
    required this.accentSoftColor,
    required this.icon,
    this.showCheckbox = false,
    this.onToggle,
  });

  final BoardItem item;
  final Color accentColor;
  final Color accentSoftColor;
  final IconData icon;
  final bool showCheckbox;
  final Future<void> Function(BoardItem item, bool isDone)? onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 42,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: item.isDone
                      ? '\uC644\uB8CC \uCDE8\uC18C'
                      : '\uC644\uB8CC',
                  onPressed: onToggle == null
                      ? null
                      : () => onToggle!(item, !item.isDone),
                  icon: Icon(
                    item.isDone
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: item.isDone
                        ? AppColors.primary
                        : AppColors.mutedText,
                  ),
                ),
              ),
            ],
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accentSoftColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      if (item.isPinned)
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(label: item.timeLabel),
                      _InfoChip(label: item.owner),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: AppColors.text),
      ),
    );
  }
}
