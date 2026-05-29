import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/board_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/board_action_sheets.dart';
import '../widgets/common_widgets.dart';

class TodayBoardScreen extends StatefulWidget {
  const TodayBoardScreen({
    super.key,
    this.repository,
    this.items,
    this.board,
    this.selectedTab = BoardTab.today,
    this.onTabSelected,
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
  final BoardTab selectedTab;
  final ValueChanged<BoardTab>? onTabSelected;
  final VoidCallback? onRefresh;
  final ValueChanged<BoardItemType?>? onAddItem;
  final VoidCallback? onCreateInvite;
  final Future<void> Function(BoardItem item, bool isDone)? onCompleteTask;

  @override
  State<TodayBoardScreen> createState() => _TodayBoardScreenState();
}

class _TodayBoardScreenState extends State<TodayBoardScreen> {
  late Future<List<BoardItem>>? _itemsFuture = _loadItems();
  List<BoardItem>? _fallbackItems;
  final Set<String> _pendingTaskIds = {};

  @override
  void didUpdateWidget(TodayBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != null) {
      _itemsFuture = null;
      _fallbackItems = null;
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
    final displayedItems = _fallbackItems ?? items;
    final todayItems = displayedItems
        .where((item) => item.isForDate(DateTime.now()))
        .toList(growable: false);
    final todaySchedules = _itemsOfType(todayItems, BoardItemType.schedule);
    final todayTasks = _itemsOfType(todayItems, BoardItemType.task);
    final todayNotices = _itemsOfType(todayItems, BoardItemType.notice);
    final schedules = _itemsOfType(displayedItems, BoardItemType.schedule);
    final tasks = _itemsOfType(displayedItems, BoardItemType.task);
    final notices = _itemsOfType(displayedItems, BoardItemType.notice);
    final openTasks = todayTasks.where((item) => !item.isDone).length;
    final selectedTab = _effectiveSelectedTab;

    return Scaffold(
      bottomNavigationBar: AppBottomNav(
        selectedTab: selectedTab,
        onSelected: _selectTab,
      ),
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
                      onAddItem: selectedTab == BoardTab.members
                          ? null
                          : () => _addItem(selectedTab.defaultItemType),
                    ),
                    const SizedBox(height: 20),
                    if (selectedTab == BoardTab.today) ...[
                      _PulseCard(
                        schedules: todaySchedules.length,
                        openTasks: openTasks,
                        notices: todayNotices.length,
                      ),
                      const SizedBox(height: 24),
                      _ItemSection(
                        title: '\uC624\uB298 \uC77C\uC815',
                        items: todaySchedules,
                        accentColor: AppColors.primary,
                        accentSoftColor: AppColors.primarySoft,
                        icon: Icons.calendar_month_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                      ),
                      const SizedBox(height: 12),
                      _ItemSection(
                        title: '\uD560 \uC77C',
                        items: todayTasks,
                        accentColor: AppColors.tertiary,
                        accentSoftColor: AppColors.warningSoft,
                        icon: Icons.check_rounded,
                        showCheckbox: true,
                        onToggle: _toggleTask,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                      ),
                      const SizedBox(height: 12),
                      _ItemSection(
                        title: '\uACF5\uC9C0',
                        items: todayNotices,
                        accentColor: AppColors.success,
                        accentSoftColor: AppColors.successSoft,
                        icon: Icons.campaign_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                      ),
                    ] else if (selectedTab == BoardTab.calendar)
                      _ItemSection(
                        title: '\uC77C\uC815',
                        items: schedules,
                        accentColor: AppColors.primary,
                        accentSoftColor: AppColors.primarySoft,
                        icon: Icons.calendar_month_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                        emptyText:
                            '\uB4F1\uB85D\uB41C \uC77C\uC815\uC774 \uC5C6\uC5B4\uC694.',
                      )
                    else if (selectedTab == BoardTab.tasks)
                      _ItemSection(
                        title: '\uD560 \uC77C',
                        items: tasks,
                        accentColor: AppColors.tertiary,
                        accentSoftColor: AppColors.warningSoft,
                        icon: Icons.check_rounded,
                        showCheckbox: true,
                        onToggle: _toggleTask,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                        emptyText:
                            '\uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.',
                      )
                    else if (selectedTab == BoardTab.notices)
                      _ItemSection(
                        title: '\uACF5\uC9C0',
                        items: notices,
                        accentColor: AppColors.success,
                        accentSoftColor: AppColors.successSoft,
                        icon: Icons.campaign_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                        emptyText:
                            '\uC77D\uC744 \uACF5\uC9C0\uAC00 \uC5C6\uC5B4\uC694.',
                      )
                    else
                      _MembersPanel(
                        board: widget.board,
                        onCreateInvite: widget.onCreateInvite,
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

  Future<void> _addFallbackItem([BoardItemType? initialType]) async {
    final repository = widget.repository;
    if (repository == null) return;

    final draft = await showAddItemSheet(context, initialType: initialType);
    if (draft == null) return;

    final boardId = widget.board?.id ?? 'memory-board';
    await repository.createItem(boardId, draft);
    final items = await repository.loadTodayItems(boardId: boardId);
    if (!mounted) return;
    setState(() => _fallbackItems = items);
  }

  void _selectTab(BoardTab tab) {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(tab);
    } else {
      setState(() => _localSelectedTab = tab);
    }
  }

  BoardTab _localSelectedTab = BoardTab.today;

  BoardTab get _effectiveSelectedTab =>
      widget.onTabSelected == null ? _localSelectedTab : widget.selectedTab;

  Future<void> _addItem(BoardItemType? initialType) async {
    final onAddItem = widget.onAddItem;
    if (onAddItem != null) {
      onAddItem(initialType);
      return;
    }
    await _addFallbackItem(initialType);
  }

  Future<void> _toggleTask(BoardItem item, bool isDone) async {
    if (_pendingTaskIds.contains(item.id)) return;

    setState(() => _pendingTaskIds.add(item.id));
    try {
      final onCompleteTask = widget.onCompleteTask;
      if (onCompleteTask != null) {
        await onCompleteTask(item, isDone);
      } else {
        final repository = widget.repository;
        if (repository != null) {
          await repository.completeTask(item.id, isDone);
          final items = await repository.loadTodayItems(
            boardId: widget.board?.id,
          );
          if (mounted) setState(() => _fallbackItems = items);
        }
      }
    } finally {
      if (mounted) setState(() => _pendingTaskIds.remove(item.id));
    }
  }

  Future<void> _showItemDetail(BoardItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ItemDetailSheet(
        item: item,
        isPending: _pendingTaskIds.contains(item.id),
        onToggle: item.type == BoardItemType.task
            ? (isDone) async {
                Navigator.pop(context);
                await _toggleTask(item, isDone);
              }
            : null,
      ),
    );
  }
}

class _ItemDetailSheet extends StatelessWidget {
  const _ItemDetailSheet({
    required this.item,
    required this.isPending,
    this.onToggle,
  });

  final BoardItem item;
  final bool isPending;
  final Future<void> Function(bool isDone)? onToggle;

  @override
  Widget build(BuildContext context) {
    final detail = item.detail.trim();
    final typeLabel = item.type.label;
    final dateLabel = _dateLabel(item);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '\uB2EB\uAE30',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: typeLabel),
                _InfoChip(label: item.owner),
                _InfoChip(label: dateLabel ?? item.timeLabel),
                if (item.isPinned) const _InfoChip(label: '\uACE0\uC815'),
                if (item.type == BoardItemType.task)
                  _InfoChip(
                    label: item.isDone
                        ? '\uC644\uB8CC\uB428'
                        : '\uBBF8\uC644\uB8CC',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              detail.isEmpty
                  ? '\uBA54\uBAA8\uAC00 \uC5C6\uC5B4\uC694.'
                  : detail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: detail.isEmpty ? AppColors.mutedText : null,
              ),
            ),
            if (item.type == BoardItemType.task && onToggle != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isPending ? null : () => onToggle!(!item.isDone),
                icon: Icon(
                  item.isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
                ),
                label: Text(
                  item.isDone
                      ? '\uC644\uB8CC \uCDE8\uC18C'
                      : '\uC644\uB8CC\uD558\uAE30',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _dateLabel(BoardItem item) {
    final value = item.type == BoardItemType.schedule
        ? item.startsAt
        : item.dueAt;
    if (value == null) return null;
    final local = value.toLocal();
    return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.board, this.onCreateInvite, this.onAddItem});

  final BoardSummary? board;
  final VoidCallback? onCreateInvite;
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
        const SizedBox(width: 8),
        AddItemFab(onPressed: onAddItem),
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

class _ItemSection extends StatelessWidget {
  const _ItemSection({
    required this.title,
    required this.items,
    required this.accentColor,
    required this.accentSoftColor,
    required this.icon,
    this.showCheckbox = false,
    this.onToggle,
    this.emptyText,
    this.pendingTaskIds = const {},
    this.onItemTap,
  });

  final String title;
  final List<BoardItem> items;
  final Color accentColor;
  final Color accentSoftColor;
  final IconData icon;
  final bool showCheckbox;
  final Future<void> Function(BoardItem item, bool isDone)? onToggle;
  final String? emptyText;
  final Set<String> pendingTaskIds;
  final ValueChanged<BoardItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, count: items.length),
        const SizedBox(height: 10),
        if (items.isEmpty)
          SoftCard(
            child: Text(
              emptyText ??
                  '\uC544\uC9C1 \uD56D\uBAA9\uC774 \uC5C6\uC5B4\uC694.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
            ),
          )
        else
          ...items.map(
            (item) => _ItemCard(
              item: item,
              accentColor: accentColor,
              accentSoftColor: accentSoftColor,
              icon: icon,
              showCheckbox: showCheckbox,
              onToggle: onToggle,
              isPending: pendingTaskIds.contains(item.id),
              onTap: onItemTap == null ? null : () => onItemTap!(item),
            ),
          ),
      ],
    );
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({required this.board, this.onCreateInvite});

  final BoardSummary? board;
  final VoidCallback? onCreateInvite;

  @override
  Widget build(BuildContext context) {
    final memberCount = board?.memberCount ?? 1;
    final maxMembers = board?.maxMembers ?? 4;
    final isAdmin = board?.isAdmin == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '\uAC00\uC871', count: memberCount),
        const SizedBox(height: 10),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                board?.name ?? '\uC6B0\uB9AC\uC9D1',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '\uC815\uC6D0 $memberCount / $maxMembers\uBA85',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
              ),
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

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.accentColor,
    required this.accentSoftColor,
    required this.icon,
    this.showCheckbox = false,
    this.onToggle,
    this.isPending = false,
    this.onTap,
  });

  final BoardItem item;
  final Color accentColor;
  final Color accentSoftColor;
  final IconData icon;
  final bool showCheckbox;
  final Future<void> Function(BoardItem item, bool isDone)? onToggle;
  final bool isPending;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  padding: EdgeInsets.zero,
                  tooltip: item.isDone
                      ? '\uC644\uB8CC \uCDE8\uC18C'
                      : '\uC644\uB8CC',
                  onPressed: onToggle == null || isPending
                      ? null
                      : () => onToggle!(item, !item.isDone),
                  icon: isPending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                decoration: item.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.isDone ? AppColors.mutedText : null,
                              ),
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
