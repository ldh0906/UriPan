import 'package:flutter/material.dart';

import '../models/board_item.dart';
import '../services/board_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/board_action_sheets.dart';
import '../widgets/board_header.dart';
import '../widgets/board_item_card.dart';
import '../widgets/comment_thread.dart';
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
  _TaskFilter _taskFilter = _TaskFilter.open;
  late DateTime _selectedCalendarDate;

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
                      if (_isSearchVisible) ...[
                        _SearchField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          onClear: _clearSearch,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_activeTag != null) ...[
                        _ActiveTagFilterChip(
                          tag: _activeTag!,
                          onDeleted: _clearActiveTag,
                        ),
                        const SizedBox(height: 16),
                      ],
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
                        )
                      else if (selectedTab == BoardTab.today) ...[
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
                            showCheckbox: true,
                            onToggle: _toggleTask,
                            pendingTaskIds: _pendingTaskIds,
                            isOverdue: _isOverdueTask,
                            onItemTap: _showItemDetail,
                            onTagTap: _setActiveTag,
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
                          onTagTap: _setActiveTag,
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
                          onTagTap: _setActiveTag,
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
                          onTagTap: _setActiveTag,
                        ),
                      ] else if (selectedTab == BoardTab.calendar) ...[
                        _CalendarWeekStrip(
                          selectedDate: _selectedCalendarDate,
                          today: widget.now(),
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
                          onTagTap: _setActiveTag,
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
                          isOverdue: _isOverdueTask,
                          onItemTap: _showItemDetail,
                          onTagTap: _setActiveTag,
                          emptyText: _taskEmptyText,
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
                          onTagTap: _setActiveTag,
                          emptyText:
                              '\uC77D\uC744 \uACF5\uC9C0\uAC00 \uC5C6\uC5B4\uC694.',
                        )
                      else
                        MembersPanel(
                          board: widget.board,
                          members: widget.members,
                          currentUserId: widget.currentUserId,
                          activeInvite: widget.activeInvite,
                          onCreateInvite: widget.onCreateInvite,
                          onRegenerateInvite: widget.onRegenerateInvite,
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

  String get _taskEmptyText {
    switch (_taskFilter) {
      case _TaskFilter.open:
        return '\uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
      case _TaskFilter.mine:
        return '\uB0B4 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
      case _TaskFilter.done:
        return '\uC644\uB8CC\uD55C \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.';
    }
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
    return repository.loadComments(item.id);
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
      showDragHandle: true,
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

class _CalendarWeekStrip extends StatelessWidget {
  const _CalendarWeekStrip({
    required this.selectedDate,
    required this.today,
    required this.onDateSelected,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime selectedDate;
  final DateTime today;
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
                  isToday: _isSameDay(day, today),
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
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final String weekdayLabel;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: isSelected,
      label: _semanticLabel,
      onTap: onTap,
      child: InkWell(
        key: ValueKey('calendar-day-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
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
                      color: isSelected
                          ? colors.onPrimary
                          : AppColors.mutedText,
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
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 4,
                    child: isToday
                        ? Container(
                            key: const ValueKey('calendar-today-dot'),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.onPrimary
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
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
