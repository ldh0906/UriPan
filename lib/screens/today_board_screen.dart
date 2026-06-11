import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/board_repository.dart';
import '../services/friendly_date.dart';
import '../theme/app_theme.dart';
import '../widgets/board_action_sheets.dart';
import '../widgets/board_header.dart';
import '../widgets/board_item_card.dart';
import '../widgets/comment_thread.dart';
import '../widgets/common_widgets.dart';
import '../widgets/item_detail_sheet.dart';

enum TaskBoardFilter {
  open('\uBBF8\uC644\uB8CC'),
  mine('\uB0B4 \uD560 \uC77C'),
  done('\uC644\uB8CC');

  const TaskBoardFilter(this.label);

  final String label;
}

List<BoardItem> filterTaskBoardItems(
  List<BoardItem> tasks, {
  required TaskBoardFilter filter,
  DateTime? dateFilter,
  String? currentUserId,
}) {
  final datedTasks = dateFilter == null
      ? tasks
      : tasks.where((item) => item.isForDate(dateFilter)).toList();
  final filtered = switch (filter) {
    TaskBoardFilter.open => datedTasks.where((item) => !item.isDone),
    TaskBoardFilter.mine =>
      currentUserId == null
          ? const Iterable<BoardItem>.empty()
          : datedTasks.where((item) => item.assignedToId == currentUserId),
    TaskBoardFilter.done => datedTasks.where((item) => item.isDone),
  };
  final result = filtered.toList(growable: false);
  if (dateFilter != null) return result;

  final indexed = result.indexed.toList(growable: false)
    ..sort((left, right) {
      final leftDueAt = left.$2.dueAt;
      final rightDueAt = right.$2.dueAt;
      if (leftDueAt == null && rightDueAt == null) {
        return left.$1.compareTo(right.$1);
      }
      if (leftDueAt == null) return 1;
      if (rightDueAt == null) return -1;
      final dueAtCompare = filter == TaskBoardFilter.done
          ? rightDueAt.compareTo(leftDueAt)
          : leftDueAt.compareTo(rightDueAt);
      if (dueAtCompare != 0) return dueAtCompare;
      return left.$1.compareTo(right.$1);
    });
  return indexed.map((entry) => entry.$2).toList(growable: false);
}

DateTime moveCalendarMonth(DateTime selectedDate, int monthDelta) {
  final targetMonthStart = DateTime(
    selectedDate.year,
    selectedDate.month + monthDelta,
  );
  final targetLastDay = DateTime(
    targetMonthStart.year,
    targetMonthStart.month + 1,
    0,
  ).day;
  final day = selectedDate.day > targetLastDay
      ? targetLastDay
      : selectedDate.day;
  return DateTime(targetMonthStart.year, targetMonthStart.month, day);
}

enum _CalendarDayCategory { schedule, task }

class CalendarBarSegment {
  const CalendarBarSegment({
    required this.itemId,
    required this.lane,
    required this.startColumn,
    required this.endColumn,
    required this.roundedLeft,
    required this.roundedRight,
  });

  final String itemId;
  final int lane;
  final int startColumn;
  final int endColumn;
  final bool roundedLeft;
  final bool roundedRight;
}

List<CalendarBarSegment> calendarWeekBars({
  required List<BoardItem> schedules,
  required DateTime weekStart,
}) {
  final week = _calendarDateOnly(weekStart);
  final weekEnd = week.add(const Duration(days: 6));
  final candidates = <_CalendarBarCandidate>[];

  for (final schedule in schedules) {
    if (schedule.type != BoardItemType.schedule) continue;
    final startsAt = schedule.startsAt;
    if (startsAt == null) continue;

    final start = _calendarDateOnly(startsAt);
    final rawEnd = _calendarDateOnly(schedule.dueAt ?? startsAt);
    final end = rawEnd.isBefore(start) ? start : rawEnd;
    if (end.isBefore(week) || start.isAfter(weekEnd)) continue;

    final segmentStart = start.isBefore(week) ? week : start;
    final segmentEnd = end.isAfter(weekEnd) ? weekEnd : end;
    candidates.add(
      _CalendarBarCandidate(
        itemId: schedule.id,
        start: start,
        end: end,
        startColumn: segmentStart.difference(week).inDays,
        endColumn: segmentEnd.difference(week).inDays,
      ),
    );
  }

  candidates.sort((left, right) {
    final startCompare = left.start.compareTo(right.start);
    if (startCompare != 0) return startCompare;
    final endCompare = left.end.compareTo(right.end);
    if (endCompare != 0) return endCompare;
    return left.itemId.compareTo(right.itemId);
  });

  final laneEndColumns = <int>[];
  final segments = <CalendarBarSegment>[];
  for (final candidate in candidates) {
    var lane = 0;
    while (lane < laneEndColumns.length &&
        candidate.startColumn <= laneEndColumns[lane]) {
      lane += 1;
    }
    if (lane >= 3) continue;
    if (lane == laneEndColumns.length) {
      laneEndColumns.add(candidate.endColumn);
    } else {
      laneEndColumns[lane] = candidate.endColumn;
    }
    segments.add(
      CalendarBarSegment(
        itemId: candidate.itemId,
        lane: lane,
        startColumn: candidate.startColumn,
        endColumn: candidate.endColumn,
        roundedLeft: !candidate.start.isBefore(week),
        roundedRight: !candidate.end.isAfter(weekEnd),
      ),
    );
  }

  return List.unmodifiable(segments);
}

DateTime _calendarDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _taskDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Korean calendar weekday headers, Sunday-first (Sun..Sat).
const calendarWeekdayLabels = <String>['일', '월', '화', '수', '목', '금', '토'];

/// Start of the calendar week (Sunday) containing [date], date-only.
DateTime startOfCalendarWeek(DateTime date) {
  final localDate = date.toLocal();
  final local = DateTime(localDate.year, localDate.month, localDate.day);
  // DateTime.weekday: Mon=1..Sun=7; `% 7` maps Sunday to 0 so weeks start Sunday.
  return local.subtract(Duration(days: local.weekday % 7));
}

class _CalendarBarCandidate {
  const _CalendarBarCandidate({
    required this.itemId,
    required this.start,
    required this.end,
    required this.startColumn,
    required this.endColumn,
  });

  final String itemId;
  final DateTime start;
  final DateTime end;
  final int startColumn;
  final int endColumn;
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
    this.onOpenMembers,
    this.onOpenSettings,
    this.onRegenerateInvite,
    this.onRevokeInvite,
    this.onLeaveBoard,
    this.onUpdateMemberRole,
    this.onRemoveMember,
    this.onCompleteTask,
    this.onConfirmNotice,
    this.loadComments,
    this.onAddComment,
    this.onDeleteComment,
    this.subscribeComments,
    this.onEditItem,
    this.onDeleteItem,
    this.now = DateTime.now,
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
  final void Function(BoardItemType? type, [DateTime? initialDateTime])?
  onAddItem;
  final BoardInvite? activeInvite;
  final VoidCallback? onCreateInvite;
  final VoidCallback? onOpenMembers;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onRegenerateInvite;
  final VoidCallback? onRevokeInvite;
  final Future<void> Function()? onLeaveBoard;
  final Future<void> Function(String userId, String role)? onUpdateMemberRole;
  final Future<void> Function(String userId)? onRemoveMember;
  final Future<void> Function(BoardItem item, bool isDone)? onCompleteTask;
  final Future<void> Function(BoardItem item, bool confirmed)? onConfirmNotice;
  final Future<List<BoardComment>> Function(BoardItem item)? loadComments;
  final Future<void> Function(BoardItem item, String body)? onAddComment;
  final Future<void> Function(BoardComment comment)? onDeleteComment;
  final CommentSubscription? subscribeComments;
  final void Function(BoardItem item)? onEditItem;
  final Future<void> Function(BoardItem item)? onDeleteItem;
  final DateTime Function() now;

  @override
  State<TodayBoardScreen> createState() => _TodayBoardScreenState();
}

class _TodayBoardScreenState extends State<TodayBoardScreen> {
  late Future<List<BoardItem>>? _itemsFuture = _loadItems();
  List<BoardItem>? _fallbackItems;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _pendingTaskIds = {};
  bool _isRefreshing = false;
  bool _isSearchVisible = false;
  String _searchQuery = '';
  String? _activeTag;
  TaskBoardFilter _taskFilter = TaskBoardFilter.open;
  DateTime? _taskDateFilter;
  late DateTime _selectedCalendarDate;
  bool _isCalendarExpanded = false;
  List<BoardItem> _latestDisplayedItems = const [];

  @override
  void initState() {
    super.initState();
    _selectedCalendarDate = widget.now();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    _latestDisplayedItems = displayedItems;
    final todayItems = displayedItems
        .where((item) => item.isForDate(widget.now()))
        .toList(growable: false);
    final todaySchedules = _itemsWithActiveTag(
      _itemsOfType(todayItems, BoardItemType.schedule),
    );
    final todayTasks = _itemsWithActiveTag(
      _itemsOfType(todayItems, BoardItemType.task),
    );
    final todayNotices = _sortedNotices(
      _itemsWithActiveTag(_itemsOfType(todayItems, BoardItemType.notice)),
    );
    final schedules = _itemsWithActiveTag(
      _itemsOfType(displayedItems, BoardItemType.schedule),
    );
    final tasks = _itemsWithActiveTag(
      _itemsOfType(displayedItems, BoardItemType.task),
    );
    final selectedDaySchedules = schedules
        .where((item) => item.isForDate(_selectedCalendarDate))
        .toList(growable: false);
    final selectedDayTasks = tasks
        .where((item) => item.isForDate(_selectedCalendarDate))
        .toList(growable: false);
    final notices = _sortedNotices(
      _itemsWithActiveTag(_itemsOfType(displayedItems, BoardItemType.notice)),
    );
    final openTasks = todayTasks.where((item) => !item.isDone).length;
    final attentionItems = _itemsWithActiveTag(_attentionItems(displayedItems));
    final badges = <BoardTab, int>{
      BoardTab.today: attentionItems.length,
      BoardTab.tasks: _taskBadgeCount(displayedItems),
      BoardTab.notices: _noticeBadgeCount(displayedItems),
    };
    final selectedTab = _effectiveSelectedTab;
    final trimmedSearchQuery = _searchQuery.trim();
    final isSearching = trimmedSearchQuery.isNotEmpty;
    final searchResults = isSearching
        ? _itemsWithActiveTag(displayedItems)
              .where((item) => boardItemMatchesQuery(item, trimmedSearchQuery))
              .toList(growable: false)
        : const <BoardItem>[];

    return Scaffold(
      bottomNavigationBar: AppBottomNav(
        selectedTab: selectedTab,
        onSelected: _selectTab,
        badges: badges,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: widget.onRefresh == null ? Future<void>.value : _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BoardHeader(
                        board: widget.board,
                        onOpenSettings: widget.onOpenSettings,
                        onRefresh: widget.onRefresh == null ? null : _refresh,
                        isRefreshing: _isRefreshing,
                        onSearchToggle: _toggleSearch,
                        onAddItem: selectedTab == BoardTab.members
                            ? null
                            : () => _addItem(
                                selectedTab.defaultItemType,
                                _initialDateTimeForAdd(),
                              ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: _isSearchVisible
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SearchField(
                                    controller: _searchController,
                                    onChanged: (value) =>
                                        setState(() => _searchQuery = value),
                                    onClear: _clearSearch,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: _activeTag != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ActiveTagFilterChip(
                                    tag: _activeTag!,
                                    onDeleted: _clearActiveTag,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        reverseDuration: const Duration(milliseconds: 160),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final offset = Tween<Offset>(
                            begin: const Offset(0, 0.015),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(
                            isSearching ? 'search' : selectedTab.name,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isSearching)
                                BoardItemSection(
                                  title: '\uAC80\uC0C9 \uACB0\uACFC',
                                  items: searchResults,
                                  accentColor: AppColors.primary,
                                  accentSoftColor: AppColors.primarySoft,
                                  icon: Icons.search_rounded,
                                  pendingTaskIds: _pendingTaskIds,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                  emptyText:
                                      '\uAC80\uC0C9 \uACB0\uACFC\uAC00 \uC5C6\uC5B4\uC694.',
                                  emptyActionLabel:
                                      '\uAC80\uC0C9\uC5B4 \uC9C0\uC6B0\uAE30',
                                  onEmptyAction: _clearSearch,
                                )
                              else if (selectedTab == BoardTab.today) ...[
                                PulseCard(
                                  schedules: todaySchedules.length,
                                  openTasks: openTasks,
                                  notices: todayNotices.length,
                                ),
                                if (attentionItems.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  BoardItemSection(
                                    title: '\uB193\uCE58\uBA74 \uC548 \uB3FC\uC694',
                                    items: attentionItems,
                                    accentColor: AppColors.tertiary,
                                    accentSoftColor: AppColors.warningSoft,
                                    icon: Icons.priority_high_rounded,
                                    showCheckbox: true,
                                    onToggle: _toggleTask,
                                    pendingTaskIds: _pendingTaskIds,
                                    isOverdue: _isOverdueTask,
                                    onItemTap: _showItemDetail,
                                    onTagTap: _setActiveTag,
                                  ),
                                  const SizedBox(height: 28),
                                ] else
                                  const SizedBox(height: 20),
                                BoardItemSection(
                                  title: '\uC624\uB298 \uC77C\uC815',
                                  items: todaySchedules,
                                  accentColor: AppColors.primary,
                                  accentSoftColor: AppColors.primarySoft,
                                  icon: Icons.calendar_month_rounded,
                                  pendingTaskIds: _pendingTaskIds,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                  emptyActionLabel: _emptyActionLabelFor(
                                    BoardItemType.schedule,
                                  ),
                                  onEmptyAction: _emptyActionFor(
                                    BoardItemType.schedule,
                                  ),
                                ),
                                const SizedBox(height: 28),
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
                                  onTagTap: _setActiveTag,
                                ),
                                const SizedBox(height: 28),
                                BoardItemSection(
                                  title: '\uACF5\uC9C0',
                                  items: todayNotices,
                                  accentColor: AppColors.secondary,
                                  accentSoftColor: AppColors.secondarySoft,
                                  icon: Icons.campaign_rounded,
                                  pendingTaskIds: _pendingTaskIds,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                ),
                              ] else if (selectedTab == BoardTab.calendar) ...[
                                _CalendarPanel(
                                  selectedDate: _selectedCalendarDate,
                                  today: widget.now(),
                                  items: [...schedules, ...tasks],
                                  isExpanded: _isCalendarExpanded,
                                  onDateSelected: (date) => setState(() {
                                    _selectedCalendarDate = date;
                                    _isCalendarExpanded = false;
                                  }),
                                  onPrevious: () => setState(() {
                                    _selectedCalendarDate = _isCalendarExpanded
                                        ? moveCalendarMonth(
                                            _selectedCalendarDate,
                                            -1,
                                          )
                                        : _selectedCalendarDate.subtract(
                                            const Duration(days: 7),
                                          );
                                  }),
                                  onNext: () => setState(() {
                                    _selectedCalendarDate = _isCalendarExpanded
                                        ? moveCalendarMonth(
                                            _selectedCalendarDate,
                                            1,
                                          )
                                        : _selectedCalendarDate.add(
                                            const Duration(days: 7),
                                          );
                                  }),
                                  onToggleExpanded: () => setState(
                                    () => _isCalendarExpanded =
                                        !_isCalendarExpanded,
                                  ),
                                  onToday: () => setState(() {
                                    _selectedCalendarDate = widget.now();
                                    _isCalendarExpanded = false;
                                  }),
                                ),
                                const SizedBox(height: 20),
                                BoardItemSection(
                                  title: '\uC77C\uC815',
                                  items: selectedDaySchedules,
                                  accentColor: AppColors.primary,
                                  accentSoftColor: AppColors.primarySoft,
                                  icon: Icons.calendar_month_rounded,
                                  pendingTaskIds: _pendingTaskIds,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                  emptyText:
                                      '\uC774\uB0A0 \uC77C\uC815\uC774 \uC5C6\uC5B4\uC694.',
                                  emptyActionLabel: _emptyActionLabelFor(
                                    BoardItemType.schedule,
                                  ),
                                  onEmptyAction: _emptyActionFor(
                                    BoardItemType.schedule,
                                    initialDateTime: _initialDateTimeForAdd(),
                                  ),
                                  maxVisible: 3,
                                  onShowMore: () => _showCalendarDaySheet(
                                    context,
                                    _CalendarDayCategory.schedule,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                BoardItemSection(
                                  title: '\uD560 \uC77C',
                                  items: selectedDayTasks,
                                  accentColor: AppColors.tertiary,
                                  accentSoftColor: AppColors.warningSoft,
                                  icon: Icons.check_rounded,
                                  showCheckbox: true,
                                  onToggle: _toggleTask,
                                  pendingTaskIds: _pendingTaskIds,
                                  isOverdue: _isOverdueTask,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                  emptyText:
                                      '\uC774\uB0A0 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.',
                                  maxVisible: 3,
                                  onShowMore: () => _showCalendarDaySheet(
                                    context,
                                    _CalendarDayCategory.task,
                                  ),
                                ),
                              ] else if (selectedTab == BoardTab.tasks) ...[
                                _TaskDateNavigator(
                                  selectedDate: _taskDateFilter,
                                  today: widget.now(),
                                  onPrevious: _moveTaskDateBack,
                                  onNext: _moveTaskDateForward,
                                  onToday: _selectTaskToday,
                                  onAll: _clearTaskDateFilter,
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<TaskBoardFilter>(
                                  segments: TaskBoardFilter.values
                                      .map(
                                        (filter) => ButtonSegment(
                                          value: filter,
                                          label: Text(filter.label),
                                        ),
                                      )
                                      .toList(),
                                  selected: {_taskFilter},
                                  onSelectionChanged: (values) => setState(
                                    () => _taskFilter = values.single,
                                  ),
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
                                  isOverdue: _isOverdueTask,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                  emptyText: _taskEmptyText,
                                  emptyActionLabel: _taskEmptyActionLabel,
                                  onEmptyAction: _taskEmptyAction,
                                ),
                              ] else if (selectedTab == BoardTab.notices)
                                BoardItemSection(
                                  title: '\uACF5\uC9C0',
                                  items: notices,
                                  accentColor: AppColors.secondary,
                                  accentSoftColor: AppColors.secondarySoft,
                                  icon: Icons.campaign_rounded,
                                  pendingTaskIds: _pendingTaskIds,
                                  onItemTap: _showItemDetail,
                                  onTagTap: _setActiveTag,
                                  emptyText:
                                      '\uC77D\uC744 \uACF5\uC9C0\uAC00 \uC5C6\uC5B4\uC694.',
                                  emptyActionLabel: _emptyActionLabelFor(
                                    BoardItemType.notice,
                                  ),
                                  onEmptyAction: _emptyActionFor(
                                    BoardItemType.notice,
                                  ),
                                )
                              else
                                MembersPanel(
                                  board: widget.board,
                                  members: widget.members,
                                  currentUserId: widget.currentUserId,
                                  activeInvite: widget.activeInvite,
                                  onCreateInvite: widget.onCreateInvite,
                                  onRegenerateInvite:
                                      widget.onRegenerateInvite,
                                  onRevokeInvite: widget.onRevokeInvite,
                                  onLeaveBoard: widget.onLeaveBoard,
                                  onUpdateMemberRole: widget.onUpdateMemberRole,
                                  onRemoveMember: widget.onRemoveMember,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BoardItem> _itemsOfType(List<BoardItem> items, BoardItemType type) {
    return items.where((item) => item.type == type).toList(growable: false);
  }

  List<BoardItem> _itemsWithActiveTag(List<BoardItem> items) {
    final activeTag = _activeTag;
    if (activeTag == null) return items;
    return items
        .where((item) => item.tags.contains(activeTag))
        .toList(growable: false);
  }

  List<BoardItem> _calendarDayItems(_CalendarDayCategory category) {
    final type = switch (category) {
      _CalendarDayCategory.schedule => BoardItemType.schedule,
      _CalendarDayCategory.task => BoardItemType.task,
    };
    return _itemsWithActiveTag(_itemsOfType(_latestDisplayedItems, type))
        .where((item) => item.isForDate(_selectedCalendarDate))
        .toList(growable: false);
  }

  String _calendarDayTitle(_CalendarDayCategory category) {
    final categoryLabel = switch (category) {
      _CalendarDayCategory.schedule => '\uC77C\uC815',
      _CalendarDayCategory.task => '\uD560 \uC77C',
    };
    return '${_selectedCalendarDate.month}\uC6D4 '
        '${_selectedCalendarDate.day}\uC77C $categoryLabel';
  }

  Future<void> _showCalendarDaySheet(
    BuildContext context,
    _CalendarDayCategory category,
  ) async {
    final items = _calendarDayItems(category);
    final isTask = category == _CalendarDayCategory.task;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _calendarDayTitle(category),
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                BoardItemSection(
                  title: isTask ? '\uD560 \uC77C' : '\uC77C\uC815',
                  items: items,
                  accentColor: isTask ? AppColors.tertiary : AppColors.primary,
                  accentSoftColor: isTask
                      ? AppColors.warningSoft
                      : AppColors.primarySoft,
                  icon: isTask
                      ? Icons.check_rounded
                      : Icons.calendar_month_rounded,
                  showCheckbox: isTask,
                  onToggle: isTask ? _toggleTask : null,
                  pendingTaskIds: _pendingTaskIds,
                  isOverdue: isTask ? _isOverdueTask : null,
                  onItemTap: (item) {
                    Navigator.pop(sheetContext);
                    if (!mounted) return;
                    _showItemDetail(item);
                  },
                  onTagTap: _setActiveTag,
                  emptyText: isTask
                      ? '\uC774\uB0A0 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.'
                      : '\uC774\uB0A0 \uC77C\uC815\uC774 \uC5C6\uC5B4\uC694.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setActiveTag(String tag) {
    setState(() => _activeTag = tag);
  }

  void _clearActiveTag() {
    setState(() => _activeTag = null);
  }

  void _toggleSearch() {
    if (_isSearchVisible) {
      _searchController.clear();
      setState(() {
        _isSearchVisible = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() => _isSearchVisible = true);
  }

  void _clearSearch() {
    _searchController.clear();
    if (_searchQuery.isEmpty) return;
    setState(() => _searchQuery = '');
  }

  List<BoardItem> _attentionItems(List<BoardItem> items) {
    final now = widget.now();
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

  bool _isOverdueTask(BoardItem item) {
    final dueAt = item.dueAt;
    return item.type == BoardItemType.task &&
        !item.isDone &&
        dueAt != null &&
        dueAt.isBefore(widget.now());
  }

  int _noticeBadgeCount(List<BoardItem> items) {
    return items
        .where(
          (item) =>
              item.type == BoardItemType.notice &&
              item.requiresConfirmation &&
              !item.isConfirmedByMe,
        )
        .length;
  }

  int _taskBadgeCount(List<BoardItem> items) {
    final now = widget.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    return items.where((item) {
      final dueAt = item.dueAt;
      return item.type == BoardItemType.task &&
          !item.isDone &&
          dueAt != null &&
          dueAt.isBefore(endOfToday);
    }).length;
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
    return filterTaskBoardItems(
      tasks,
      filter: _taskFilter,
      dateFilter: _taskDateFilter,
      currentUserId: widget.currentUserId,
    );
  }

  bool get _canAddItems => widget.onAddItem != null || widget.repository != null;

  bool get _hasTaskFilter =>
      _activeTag != null ||
      _taskFilter != TaskBoardFilter.open ||
      _taskDateFilter != null;

  String? get _taskEmptyActionLabel {
    if (_hasTaskFilter) return '\uD544\uD130 \uD574\uC81C';
    if (!_canAddItems) return null;
    return '\uD560 \uC77C \uCD94\uAC00';
  }

  VoidCallback? get _taskEmptyAction {
    if (_hasTaskFilter) return _clearTaskFilters;
    if (!_canAddItems) return null;
    return () => _addItem(BoardItemType.task);
  }

  String? _emptyActionLabelFor(BoardItemType type) {
    if (_activeTag != null) return '\uD544\uD130 \uD574\uC81C';
    if (!_canAddItems) return null;
    return switch (type) {
      BoardItemType.schedule => '\uC77C\uC815 \uCD94\uAC00',
      BoardItemType.task => '\uD560 \uC77C \uCD94\uAC00',
      BoardItemType.notice => '\uACF5\uC9C0 \uC791\uC131',
    };
  }

  VoidCallback? _emptyActionFor(
    BoardItemType type, {
    DateTime? initialDateTime,
  }) {
    if (_activeTag != null) return _clearActiveTag;
    if (!_canAddItems) return null;
    return () => _addItem(type, initialDateTime);
  }

  void _clearTaskFilters() {
    setState(() {
      _activeTag = null;
      _taskFilter = TaskBoardFilter.open;
      _taskDateFilter = null;
    });
  }

  String get _taskEmptyText {
    if (_taskDateFilter != null) {
      switch (_taskFilter) {
        case TaskBoardFilter.open:
          return '\uC774\uB0A0 \uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
        case TaskBoardFilter.mine:
          return '\uC774\uB0A0 \uB0B4 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
        case TaskBoardFilter.done:
          return '\uC774\uB0A0 \uC644\uB8CC\uD55C \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
      }
    }

    switch (_taskFilter) {
      case TaskBoardFilter.open:
        return '\uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
      case TaskBoardFilter.mine:
        return '\uB0B4 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
      case TaskBoardFilter.done:
        return '\uC644\uB8CC\uD55C \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
    }
  }

  void _moveTaskDateBack() {
    setState(() {
      _taskDateFilter = _taskDateOnly(
        (_taskDateFilter ?? widget.now()).subtract(const Duration(days: 1)),
      );
    });
  }

  void _moveTaskDateForward() {
    setState(() {
      _taskDateFilter = _taskDateOnly(
        (_taskDateFilter ?? widget.now()).add(const Duration(days: 1)),
      );
    });
  }

  void _selectTaskToday() {
    setState(() => _taskDateFilter = _taskDateOnly(widget.now()));
  }

  void _clearTaskDateFilter() {
    setState(() => _taskDateFilter = null);
  }

  DateTime? _initialDateTimeForAdd() {
    if (_effectiveSelectedTab != BoardTab.calendar) return null;
    final now = widget.now();
    return DateTime(
      _selectedCalendarDate.year,
      _selectedCalendarDate.month,
      _selectedCalendarDate.day,
      now.hour,
      now.minute,
    );
  }

  Future<void> _addFallbackItem([
    BoardItemType? initialType,
    DateTime? initialDateTime,
  ]) async {
    final repository = widget.repository;
    if (repository == null) return;

    final draft = await showAddItemSheet(
      context,
      initialType: initialType,
      members: widget.members,
      initialDateTime: initialDateTime,
    );
    if (draft == null) return;

    final boardId = widget.board?.id ?? 'memory-board';
    await repository.createItem(boardId, draft);
    final items = await repository.loadBoardItems(boardId: boardId);
    if (!mounted) return;
    setState(() => _fallbackItems = items);
  }

  void _selectTab(BoardTab tab) {
    if (tab == BoardTab.members) {
      widget.onOpenMembers?.call();
    }
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(tab);
    } else {
      setState(() => _localSelectedTab = tab);
    }
  }

  BoardTab _localSelectedTab = BoardTab.today;

  BoardTab get _effectiveSelectedTab =>
      widget.onTabSelected == null ? _localSelectedTab : widget.selectedTab;

  Future<void> _addItem([
    BoardItemType? initialType,
    DateTime? initialDateTime,
  ]) async {
    final onAddItem = widget.onAddItem;
    if (onAddItem != null) {
      onAddItem(initialType, initialDateTime);
      return;
    }
    await _addFallbackItem(initialType, initialDateTime);
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

  Future<List<BoardComment>> _loadComments(BoardItem item) async {
    final loadComments = widget.loadComments;
    if (loadComments != null) return loadComments(item);

    final repository = widget.repository;
    if (repository == null) return const [];
    return repository.loadComments(item.id, boardId: widget.board?.id);
  }

  Future<void> _addComment(BoardItem item, String body) async {
    final onAddComment = widget.onAddComment;
    if (onAddComment != null) {
      await onAddComment(item, body);
      return;
    }

    final repository = widget.repository;
    if (repository == null) return;
    await repository.addComment(item.id, body);
    final items = await repository.loadBoardItems(boardId: widget.board?.id);
    if (mounted) setState(() => _fallbackItems = items);
  }

  Future<void> _deleteComment(BoardComment comment) async {
    final onDeleteComment = widget.onDeleteComment;
    if (onDeleteComment != null) {
      await onDeleteComment(comment);
      return;
    }

    final repository = widget.repository;
    if (repository == null) return;
    await repository.deleteComment(comment.id);
    final items = await repository.loadBoardItems(boardId: widget.board?.id);
    if (mounted) setState(() => _fallbackItems = items);
  }

  Future<void> _showItemDetail(BoardItem item) async {
    final hasInjectedCommentCallbacks =
        widget.loadComments != null &&
        widget.onAddComment != null &&
        widget.onDeleteComment != null;
    final canShowComments =
        hasInjectedCommentCallbacks || widget.repository != null;
    final canManageItem =
        widget.board?.isAdmin == true ||
        (widget.currentUserId != null &&
            item.createdById == widget.currentUserId);

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => ItemDetailSheet(
        item: item,
        isPending: _pendingTaskIds.contains(item.id),
        members: widget.members,
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
        onEdit: canManageItem
            ? () async {
                Navigator.pop(context);
                await _editItem(item);
              }
            : null,
        onDelete: canManageItem
            ? () async {
                Navigator.pop(context);
                await _deleteItem(item);
              }
            : null,
        loadComments: canShowComments ? () => _loadComments(item) : null,
        onAddComment: canShowComments
            ? (body) => _addComment(item, body)
            : null,
        onDeleteComment: canShowComments ? _deleteComment : null,
        currentUserId: widget.currentUserId,
        subscribeComments: widget.subscribeComments,
        isAdmin: widget.board?.isAdmin == true,
      ),
    );
  }
}

class _ActiveTagFilterChip extends StatelessWidget {
  const _ActiveTagFilterChip({required this.tag, required this.onDeleted});

  final String tag;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('#$tag'),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close_rounded, size: 18),
      backgroundColor: AppColors.primarySoft.withValues(alpha: 0.8),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.18)),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: '\uAC80\uC0C9',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: IconButton(
          onPressed: onClear,
          tooltip: '\uC9C0\uC6B0\uAE30',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
  }
}

class _TaskDateNavigator extends StatelessWidget {
  const _TaskDateNavigator({
    required this.selectedDate,
    required this.today,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onAll,
  });

  final DateTime? selectedDate;
  final DateTime today;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final date = selectedDate;
    final label = date == null
        ? '\uC804\uCCB4'
        : friendlyDayLabel(date, now: today) ??
              '${date.month}\uC6D4 ${date.day}\uC77C';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '\uC774\uC804 \uB0A0',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 72),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: '\uB2E4\uC74C \uB0A0',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        ChoiceChip(
          label: const Text('\uC624\uB298'),
          selected: date != null && _isSameTaskDay(date, today),
          onSelected: (_) => onToday(),
        ),
        ChoiceChip(
          label: const Text('\uC804\uCCB4'),
          selected: date == null,
          onSelected: (_) => onAll(),
        ),
      ],
    );
  }
}

bool _isSameTaskDay(DateTime left, DateTime right) {
  final leftDay = _taskDateOnly(left);
  final rightDay = _taskDateOnly(right);
  return leftDay == rightDay;
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.selectedDate,
    required this.today,
    required this.items,
    required this.isExpanded,
    required this.onDateSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleExpanded,
    required this.onToday,
  });

  final DateTime selectedDate;
  final DateTime today;
  final List<BoardItem> items;
  final bool isExpanded;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final visibleStart = isExpanded
        ? startOfCalendarWeek(DateTime(selectedDate.year, selectedDate.month))
        : startOfCalendarWeek(selectedDate);
    final visibleDays = List.generate(
      isExpanded ? 42 : 7,
      (index) => visibleStart.add(Duration(days: index)),
    );
    final rangeEnd = visibleDays.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onPrevious,
              tooltip: isExpanded
                  ? '\uC774\uC804 \uB2EC'
                  : '\uC774\uC804 \uC8FC',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: TextButton.icon(
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    '${visibleStart.month}.${visibleStart.day} - '
                    '${rangeEnd.month}.${rangeEnd.day}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: onToday,
              child: const Text('\uC624\uB298\uB85C'),
            ),
            IconButton.filledTonal(
              onPressed: onNext,
              tooltip: isExpanded
                  ? '\uB2E4\uC74C \uB2EC'
                  : '\uB2E4\uC74C \uC8FC',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isExpanded)
          _buildMonthGrid(visibleDays)
        else
          _buildWeek(visibleDays),
      ],
    );
  }

  Widget _buildWeek(List<DateTime> days) {
    return Column(
      children: [
        Row(
          children: [
            for (final day in days)
              Expanded(
                child: _CalendarDayCell(
                  date: day,
                  weekdayLabel: calendarWeekdayLabels[day.weekday % 7],
                  isSelected: _isSameDay(day, selectedDate),
                  isToday: _isSameDay(day, today),
                  indicators: _indicatorsForDay(day),
                  isOutsideMonth: false,
                  onTap: () => onDateSelected(day),
                ),
              ),
          ],
        ),
        _CalendarWeekBarsRow(segments: _barsForWeek(days.first)),
      ],
    );
  }

  Widget _buildMonthGrid(List<DateTime> days) {
    return Column(
      children: [
        Row(
          children: [
            for (final label in calendarWeekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < 6; row += 1) ...[
          Column(
            children: [
              Row(
                children: [
                  for (var column = 0; column < 7; column += 1)
                    Expanded(
                      child: _CalendarDayCell(
                        date: days[row * 7 + column],
                        weekdayLabel: '',
                        isSelected: _isSameDay(
                          days[row * 7 + column],
                          selectedDate,
                        ),
                        isToday: _isSameDay(days[row * 7 + column], today),
                        indicators: _indicatorsForDay(days[row * 7 + column]),
                        isOutsideMonth:
                            days[row * 7 + column].month != selectedDate.month,
                        isCompact: true,
                        onTap: () => onDateSelected(days[row * 7 + column]),
                      ),
                    ),
                ],
              ),
              _CalendarWeekBarsRow(segments: _barsForWeek(days[row * 7])),
            ],
          ),
          if (row < 5) const SizedBox(height: 4),
        ],
      ],
    );
  }

  List<_CalendarIndicator> _indicatorsForDay(DateTime day) {
    final tasks = items
        .where((item) => item.type == BoardItemType.task && item.isForDate(day))
        .length;
    final indicators = <_CalendarIndicator>[
      if (tasks > 0)
        _CalendarIndicator(color: AppColors.tertiary, extraCount: tasks - 1),
    ];
    return indicators;
  }

  List<CalendarBarSegment> _barsForWeek(DateTime weekStart) {
    return calendarWeekBars(schedules: items, weekStart: weekStart);
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _CalendarIndicator {
  const _CalendarIndicator({required this.color, required this.extraCount});

  final Color color;
  final int extraCount;
}

class _CalendarWeekBarsRow extends StatelessWidget {
  const _CalendarWeekBarsRow({required this.segments});

  final List<CalendarBarSegment> segments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 21,
      child: Column(
        children: [
          for (var lane = 0; lane < 3; lane += 1) ...[
            SizedBox(
              height: 5,
              child: Row(
                children: [
                  for (var column = 0; column < 7; column += 1)
                    Expanded(child: _buildCell(lane, column)),
                ],
              ),
            ),
            if (lane < 2) const SizedBox(height: 3),
          ],
        ],
      ),
    );
  }

  Widget _buildCell(int lane, int column) {
    final segment = _segmentAt(lane, column);
    if (segment == null) return const SizedBox.expand();

    final isStart = column == segment.startColumn;
    final isEnd = column == segment.endColumn;
    return Container(
      key: isStart
          ? ValueKey(
              'calendar-bar-${segment.itemId}-${segment.lane}-'
              '${segment.startColumn}-${segment.endColumn}',
            )
          : null,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.horizontal(
          left: isStart && segment.roundedLeft
              ? const Radius.circular(AppRadius.pill)
              : Radius.zero,
          right: isEnd && segment.roundedRight
              ? const Radius.circular(AppRadius.pill)
              : Radius.zero,
        ),
      ),
    );
  }

  CalendarBarSegment? _segmentAt(int lane, int column) {
    for (final segment in segments) {
      if (segment.lane == lane &&
          column >= segment.startColumn &&
          column <= segment.endColumn) {
        return segment;
      }
    }
    return null;
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.date,
    required this.weekdayLabel,
    required this.isSelected,
    required this.isToday,
    required this.indicators,
    required this.isOutsideMonth,
    required this.onTap,
    this.isCompact = false,
  });

  final DateTime date;
  final String weekdayLabel;
  final bool isSelected;
  final bool isToday;
  final List<_CalendarIndicator> indicators;
  final bool isOutsideMonth;
  final VoidCallback onTap;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final weekendTextColor = switch (date.weekday) {
      DateTime.sunday => const Color(0xFFC94F4F),
      DateTime.saturday => const Color(0xFF3B82C4),
      _ => AppColors.text,
    };
    final textColor = isSelected
        ? colors.onPrimary
        : isOutsideMonth
        ? AppColors.mutedText
        : isToday
        ? AppColors.primary
        : weekendTextColor;
    return Semantics(
      button: true,
      selected: isSelected,
      label: _semanticLabel,
      onTap: onTap,
      child: InkWell(
        key: ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isCompact ? 42 : 58),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 0 : 1,
                vertical: isCompact ? 4 : 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (weekdayLabel.isNotEmpty) ...[
                    Text(
                      weekdayLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Container(
                    width: isCompact ? 24 : 28,
                    height: isCompact ? 24 : 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : null,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                        fontWeight: isToday || isSelected
                            ? FontWeight.w800
                            : FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _CalendarIndicatorsRow(
                    indicators: indicators,
                    isToday: isToday,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel {
    return '${date.month}\uC6D4 ${date.day}\uC77C ${_fullWeekdayLabel(date.weekday)}';
  }

  String _fullWeekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '\uC6D4\uC694\uC77C';
      case DateTime.tuesday:
        return '\uD654\uC694\uC77C';
      case DateTime.wednesday:
        return '\uC218\uC694\uC77C';
      case DateTime.thursday:
        return '\uBAA9\uC694\uC77C';
      case DateTime.friday:
        return '\uAE08\uC694\uC77C';
      case DateTime.saturday:
        return '\uD1A0\uC694\uC77C';
      case DateTime.sunday:
        return '\uC77C\uC694\uC77C';
      default:
        return '';
    }
  }
}

class _CalendarIndicatorsRow extends StatelessWidget {
  const _CalendarIndicatorsRow({
    required this.indicators,
    required this.isToday,
  });

  final List<_CalendarIndicator> indicators;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    // Dots sit in their own row below the day number, on the grid
    // background -- never on the selected blue circle -- so they always
    // keep their natural colors regardless of selection.
    const dotColor = AppColors.primary;
    final extraCount = indicators.fold<int>(
      0,
      (sum, indicator) => sum + indicator.extraCount,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isToday)
          Container(
            key: const ValueKey('calendar-today-dot'),
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        for (final indicator in indicators)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: indicator.color,
              shape: BoxShape.circle,
            ),
          ),
        if (extraCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '+$extraCount',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}
