import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/board_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/board_action_sheets.dart';
import '../widgets/board_header.dart';
import '../widgets/board_item_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/item_detail_sheet.dart';

enum _TaskFilter {
  open('\uBBF8\uC644\uB8CC'),
  mine('\uB0B4 \uD560 \uC77C'),
  done('\uC644\uB8CC');

  const _TaskFilter(this.label);

  final String label;
}

class TodayBoardScreen extends StatefulWidget {
  const TodayBoardScreen({
    super.key,
    this.repository,
    this.items,
    this.members = const [],
    this.board,
    this.currentUserId,
    this.selectedTab = BoardTab.today,
    this.onTabSelected,
    this.onRefresh,
    this.onAddItem,
    this.activeInvite,
    this.onCreateInvite,
    this.onRegenerateInvite,
    this.onRevokeInvite,
    this.onLeaveBoard,
    this.onCompleteTask,
    this.onConfirmNotice,
    this.onEditItem,
    this.onDeleteItem,
  }) : assert(
         items != null || repository != null,
         'Provide items for controlled rendering or repository for fallback loading.',
       );

  final BoardRepository? repository;
  final List<BoardItem>? items;
  final List<BoardMember> members;
  final BoardSummary? board;
  final String? currentUserId;
  final BoardTab selectedTab;
  final ValueChanged<BoardTab>? onTabSelected;
  final Future<void> Function()? onRefresh;
  final ValueChanged<BoardItemType?>? onAddItem;
  final BoardInvite? activeInvite;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onRegenerateInvite;
  final VoidCallback? onRevokeInvite;
  final Future<void> Function()? onLeaveBoard;
  final Future<void> Function(BoardItem item, bool isDone)? onCompleteTask;
  final Future<void> Function(BoardItem item, bool confirmed)? onConfirmNotice;
  final void Function(BoardItem item)? onEditItem;
  final Future<void> Function(BoardItem item)? onDeleteItem;

  @override
  State<TodayBoardScreen> createState() => _TodayBoardScreenState();
}

class _TodayBoardScreenState extends State<TodayBoardScreen> {
  late Future<List<BoardItem>>? _itemsFuture = _loadItems();
  List<BoardItem>? _fallbackItems;
  final Set<String> _pendingTaskIds = {};
  bool _isRefreshing = false;
  _TaskFilter _taskFilter = _TaskFilter.open;
  DateTime _selectedCalendarDate = DateTime.now();

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
    return widget.repository!.loadBoardItems(boardId: widget.board?.id);
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
    final todayNotices = _sortedNotices(
      _itemsOfType(todayItems, BoardItemType.notice),
    );
    final schedules = _itemsOfType(displayedItems, BoardItemType.schedule);
    final tasks = _itemsOfType(displayedItems, BoardItemType.task);
    final notices = _sortedNotices(
      _itemsOfType(displayedItems, BoardItemType.notice),
    );
    final openTasks = todayTasks.where((item) => !item.isDone).length;
    final attentionItems = _attentionItems(displayedItems);
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
                    BoardHeader(
                      board: widget.board,
                      onCreateInvite: widget.onCreateInvite,
                      onRefresh: widget.onRefresh == null ? null : _refresh,
                      isRefreshing: _isRefreshing,
                      onAddItem: selectedTab == BoardTab.members
                          ? null
                          : () => _addItem(selectedTab.defaultItemType),
                    ),
                    const SizedBox(height: 20),
                    if (selectedTab == BoardTab.today) ...[
                      PulseCard(
                        schedules: todaySchedules.length,
                        openTasks: openTasks,
                        notices: todayNotices.length,
                      ),
                      if (attentionItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        BoardItemSection(
                          title: '\uB193\uCE58\uBA74 \uC548 \uB3FC\uC694',
                          items: attentionItems,
                          accentColor: AppColors.tertiary,
                          accentSoftColor: AppColors.warningSoft,
                          icon: Icons.priority_high_rounded,
                          pendingTaskIds: _pendingTaskIds,
                          onItemTap: _showItemDetail,
                        ),
                      ],
                      const SizedBox(height: 24),
                      BoardItemSection(
                        title: '\uC624\uB298 \uC77C\uC815',
                        items: todaySchedules,
                        accentColor: AppColors.primary,
                        accentSoftColor: AppColors.primarySoft,
                        icon: Icons.calendar_month_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                      ),
                      const SizedBox(height: 12),
                      BoardItemSection(
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
                      BoardItemSection(
                        title: '\uACF5\uC9C0',
                        items: todayNotices,
                        accentColor: AppColors.success,
                        accentSoftColor: AppColors.successSoft,
                        icon: Icons.campaign_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                      ),
                    ] else if (selectedTab == BoardTab.calendar) ...[
                      _CalendarWeekStrip(
                        selectedDate: _selectedCalendarDate,
                        onDateSelected: (date) =>
                            setState(() => _selectedCalendarDate = date),
                        onPreviousWeek: () => setState(
                          () => _selectedCalendarDate = _selectedCalendarDate
                              .subtract(const Duration(days: 7)),
                        ),
                        onNextWeek: () => setState(
                          () => _selectedCalendarDate = _selectedCalendarDate
                              .add(const Duration(days: 7)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      BoardItemSection(
                        title: '\uC77C\uC815',
                        items: schedules
                            .where(
                              (item) => item.isForDate(_selectedCalendarDate),
                            )
                            .toList(growable: false),
                        accentColor: AppColors.primary,
                        accentSoftColor: AppColors.primarySoft,
                        icon: Icons.calendar_month_rounded,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                        emptyText:
                            '\uC774\uB0A0 \uC77C\uC815\uC774 \uC5C6\uC5B4\uC694.',
                      ),
                    ] else if (selectedTab == BoardTab.tasks) ...[
                      SegmentedButton<_TaskFilter>(
                        segments: _TaskFilter.values
                            .map(
                              (filter) => ButtonSegment(
                                value: filter,
                                label: Text(filter.label),
                              ),
                            )
                            .toList(),
                        selected: {_taskFilter},
                        onSelectionChanged: (values) =>
                            setState(() => _taskFilter = values.single),
                      ),
                      const SizedBox(height: 12),
                      BoardItemSection(
                        title: '\uD560 \uC77C',
                        items: _filteredTasks(tasks),
                        accentColor: AppColors.tertiary,
                        accentSoftColor: AppColors.warningSoft,
                        icon: Icons.check_rounded,
                        showCheckbox: true,
                        onToggle: _toggleTask,
                        pendingTaskIds: _pendingTaskIds,
                        onItemTap: _showItemDetail,
                        emptyText:
                            '\uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.',
                      ),
                    ] else if (selectedTab == BoardTab.notices)
                      BoardItemSection(
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
                      MembersPanel(
                        board: widget.board,
                        members: widget.members,
                        activeInvite: widget.activeInvite,
                        onCreateInvite: widget.onCreateInvite,
                        onRegenerateInvite: widget.onRegenerateInvite,
                        onRevokeInvite: widget.onRevokeInvite,
                        onLeaveBoard: widget.onLeaveBoard,
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

  List<BoardItem> _attentionItems(List<BoardItem> items) {
    final now = DateTime.now();
    return items
        .where((item) {
          if (item.type == BoardItemType.task) {
            final dueAt = item.dueAt;
            return !item.isDone && dueAt != null && dueAt.isBefore(now);
          }
          if (item.type == BoardItemType.notice) {
            return item.requiresConfirmation && !item.isConfirmedByMe;
          }
          return false;
        })
        .toList(growable: false);
  }

  List<BoardItem> _sortedNotices(List<BoardItem> notices) {
    final indexed = notices.indexed.toList(growable: false)
      ..sort((left, right) {
        final priority = _noticePriority(
          left.$2,
        ).compareTo(_noticePriority(right.$2));
        if (priority != 0) return priority;
        return left.$1.compareTo(right.$1);
      });
    return indexed.map((entry) => entry.$2).toList(growable: false);
  }

  int _noticePriority(BoardItem item) {
    if (item.requiresConfirmation && !item.isConfirmedByMe) return 0;
    if (item.isPinned) return 1;
    return 2;
  }

  List<BoardItem> _filteredTasks(List<BoardItem> tasks) {
    switch (_taskFilter) {
      case _TaskFilter.open:
        return tasks.where((item) => !item.isDone).toList(growable: false);
      case _TaskFilter.mine:
        final currentUserId = widget.currentUserId;
        if (currentUserId == null) return const [];
        return tasks
            .where((item) => item.assignedToId == currentUserId)
            .toList(growable: false);
      case _TaskFilter.done:
        return tasks.where((item) => item.isDone).toList(growable: false);
    }
  }

  Future<void> _addFallbackItem([BoardItemType? initialType]) async {
    final repository = widget.repository;
    if (repository == null) return;

    final draft = await showAddItemSheet(
      context,
      initialType: initialType,
      members: widget.members,
    );
    if (draft == null) return;

    final boardId = widget.board?.id ?? 'memory-board';
    await repository.createItem(boardId, draft);
    final items = await repository.loadBoardItems(boardId: boardId);
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

  Future<void> _refresh() async {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null || _isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      await onRefresh();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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
          final items = await repository.loadBoardItems(
            boardId: widget.board?.id,
          );
          if (mounted) setState(() => _fallbackItems = items);
        }
      }
    } finally {
      if (mounted) setState(() => _pendingTaskIds.remove(item.id));
    }
  }

  Future<void> _confirmNotice(BoardItem item, bool confirmed) async {
    final onConfirmNotice = widget.onConfirmNotice;
    if (onConfirmNotice != null) {
      await onConfirmNotice(item, confirmed);
      return;
    }

    final repository = widget.repository;
    if (repository == null) return;
    await repository.confirmNotice(item.id, confirmed);
    final items = await repository.loadBoardItems(boardId: widget.board?.id);
    if (mounted) setState(() => _fallbackItems = items);
  }

  Future<void> _deleteItem(BoardItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\uD56D\uBAA9 \uC0AD\uC81C'),
        content: Text(
          '\'${item.title}\'\uC744(\uB97C) \uC0AD\uC81C\uD560\uAE4C\uC694?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\uC0AD\uC81C'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final onDeleteItem = widget.onDeleteItem;
    if (onDeleteItem != null) {
      await onDeleteItem(item);
      return;
    }

    final repository = widget.repository;
    if (repository == null) return;
    await repository.deleteItem(item.id);
    final items = await repository.loadBoardItems(boardId: widget.board?.id);
    if (mounted) setState(() => _fallbackItems = items);
  }

  Future<void> _editItem(BoardItem item) async {
    final onEditItem = widget.onEditItem;
    if (onEditItem != null) {
      onEditItem(item);
      return;
    }

    final repository = widget.repository;
    if (repository == null) return;
    final draft = await showEditItemSheet(
      context,
      item,
      members: widget.members,
    );
    if (draft == null) return;

    await repository.updateItem(item.id, draft);
    final items = await repository.loadBoardItems(boardId: widget.board?.id);
    if (mounted) setState(() => _fallbackItems = items);
  }

  Future<void> _showItemDetail(BoardItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ItemDetailSheet(
        item: item,
        isPending: _pendingTaskIds.contains(item.id),
        onToggle: item.type == BoardItemType.task
            ? (isDone) async {
                Navigator.pop(context);
                await _toggleTask(item, isDone);
              }
            : null,
        onConfirm: item.type == BoardItemType.notice
            ? (confirmed) async {
                Navigator.pop(context);
                await _confirmNotice(item, confirmed);
              }
            : null,
        onEdit: () async {
          Navigator.pop(context);
          await _editItem(item);
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteItem(item);
        },
      ),
    );
  }
}

class _CalendarWeekStrip extends StatelessWidget {
  const _CalendarWeekStrip({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  static const _weekdayLabels = [
    '\uC6D4',
    '\uD654',
    '\uC218',
    '\uBAA9',
    '\uAE08',
    '\uD1A0',
    '\uC77C',
  ];

  @override
  Widget build(BuildContext context) {
    final weekStart = _startOfWeek(selectedDate);
    final days = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPreviousWeek,
              tooltip: '\uC774\uC804 \uC8FC',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${weekStart.month}.${weekStart.day} - '
                  '${days.last.month}.${days.last.day}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onNextWeek,
              tooltip: '\uB2E4\uC74C \uC8FC',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final day in days) ...[
              Expanded(
                child: _CalendarDayCell(
                  date: day,
                  weekdayLabel: _weekdayLabels[day.weekday - 1],
                  isSelected: _isSameDay(day, selectedDate),
                  onTap: () => onDateSelected(day),
                ),
              ),
              if (day != days.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return local.subtract(Duration(days: local.weekday - 1));
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.weekdayLabel,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final String weekdayLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? colors.onPrimary : AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? colors.onPrimary : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
