import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/board_item.dart';

abstract class BoardRepository {
  Future<List<BoardSummary>> loadBoards() async => const [];
  Future<BoardSummary> createBoard(String name, int maxMembers) {
    throw UnimplementedError();
  }

  Future<BoardInvite> createInvite(String boardId) {
    throw UnimplementedError();
  }

  Future<BoardSummary> joinBoardWithInvite(String code) {
    throw UnimplementedError();
  }

  Future<List<BoardItem>> loadTodayItems({String? boardId});
  Future<BoardItem> createItem(String boardId, BoardItemDraft draft) {
    throw UnimplementedError();
  }

  Future<BoardItem> completeTask(String itemId, bool isDone) {
    throw UnimplementedError();
  }
}

class MemoryBoardRepository implements BoardRepository {
  MemoryBoardRepository(this._items);

  final List<BoardItem> _items;
  final List<BoardSummary> _boards = [
    const BoardSummary(
      id: 'memory-board',
      name: '\uC6B0\uB9AC\uC9D1',
      role: 'admin',
      maxMembers: 4,
      memberCount: 1,
    ),
  ];

  @override
  Future<List<BoardSummary>> loadBoards() async => List.unmodifiable(_boards);

  @override
  Future<BoardSummary> createBoard(String name, int maxMembers) async {
    final board = BoardSummary(
      id: 'memory-board-${_boards.length + 1}',
      name: name,
      role: 'admin',
      maxMembers: maxMembers,
      memberCount: 1,
    );
    _boards.add(board);
    return board;
  }

  @override
  Future<BoardInvite> createInvite(String boardId) async {
    return BoardInvite(
      id: 'memory-invite',
      code: 'URIP-2026',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
  }

  @override
  Future<BoardSummary> joinBoardWithInvite(String code) async => _boards.first;

  @override
  Future<List<BoardItem>> loadTodayItems({String? boardId}) async {
    return List.unmodifiable(_items);
  }

  @override
  Future<BoardItem> createItem(String boardId, BoardItemDraft draft) async {
    final item = BoardItem(
      id: 'memory-item-${_items.length + 1}',
      type: draft.type,
      title: draft.title,
      detail: draft.detail,
      owner: '\uC6B0\uB9AC',
      timeLabel: draft.type == BoardItemType.schedule
          ? '09:00'
          : '\uC624\uB298',
      isPinned: draft.isPinned,
    );
    _items.add(item);
    return item;
  }

  @override
  Future<BoardItem> completeTask(String itemId, bool isDone) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) throw StateError('Item not found');
    final old = _items[index];
    final updated = BoardItem(
      id: old.id,
      type: old.type,
      title: old.title,
      detail: old.detail,
      owner: old.owner,
      timeLabel: old.timeLabel,
      isDone: isDone,
      isPinned: old.isPinned,
    );
    _items[index] = updated;
    return updated;
  }
}

class SupabaseBoardRepository implements BoardRepository {
  const SupabaseBoardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BoardSummary>> loadBoards() async {
    final rows = await _client
        .from('board_members')
        .select('role, boards(id, name, max_members, board_members(user_id))')
        .order('joined_at');

    return rows
        .map<BoardSummary>((row) {
          final board = Map<String, dynamic>.from(row['boards'] as Map);
          final members = (board['board_members'] as List?) ?? const [];
          return BoardSummary(
            id: board['id'] as String,
            name: board['name'] as String,
            role: row['role'] as String,
            maxMembers: board['max_members'] as int,
            memberCount: members.length,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<BoardSummary> createBoard(String name, int maxMembers) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_family_board',
      params: {'board_name': name, 'member_limit': maxMembers},
    );

    return BoardSummary(
      id: row['id'] as String,
      name: row['name'] as String,
      role: 'admin',
      maxMembers: row['max_members'] as int,
      memberCount: 1,
    );
  }

  @override
  Future<BoardInvite> createInvite(String boardId) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'create_board_invite',
      params: {'target_board_id': boardId},
    );

    return BoardInvite(
      id: row['id'] as String,
      code: row['code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }

  @override
  Future<BoardSummary> joinBoardWithInvite(String code) async {
    final member = await _client.rpc<Map<String, dynamic>>(
      'join_board_with_invite',
      params: {'invite_code': code},
    );
    final boardId = member['board_id'] as String;
    final board = await _client
        .from('boards')
        .select('id, name, max_members, board_members(user_id)')
        .eq('id', boardId)
        .single();
    final members = (board['board_members'] as List?) ?? const [];

    return BoardSummary(
      id: board['id'] as String,
      name: board['name'] as String,
      role: member['role'] as String,
      maxMembers: board['max_members'] as int,
      memberCount: members.length,
    );
  }

  @override
  Future<List<BoardItem>> loadTodayItems({String? boardId}) async {
    if (boardId == null) return const [];

    final rows = await _client
        .from('board_items')
        .select(
          'id, type, title, detail, starts_at, due_at, is_done, is_pinned',
        )
        .eq('board_id', boardId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    return rows.map<BoardItem>(_itemFromRow).toList(growable: false);
  }

  @override
  Future<BoardItem> createItem(String boardId, BoardItemDraft draft) async {
    final now = DateTime.now();
    final startsAt = draft.type == BoardItemType.schedule
        ? draft.startsAt ?? now
        : draft.startsAt;
    final dueAt = draft.type == BoardItemType.task
        ? draft.dueAt ?? now
        : draft.dueAt;
    final userId = _client.auth.currentUser!.id;

    final row = await _client
        .from('board_items')
        .insert({
          'board_id': boardId,
          'type': draft.type.wireName,
          'title': draft.title,
          'detail': draft.detail,
          'starts_at': startsAt?.toIso8601String(),
          'due_at': dueAt?.toIso8601String(),
          'assigned_to': draft.assignedTo,
          'created_by': userId,
          'requires_confirmation': draft.requiresConfirmation,
          'is_pinned': draft.isPinned,
        })
        .select(
          'id, type, title, detail, starts_at, due_at, is_done, is_pinned',
        )
        .single();

    return _itemFromRow(row);
  }

  @override
  Future<BoardItem> completeTask(String itemId, bool isDone) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'complete_task',
      params: {'target_item_id': itemId, 'completed': isDone},
    );

    return _itemFromRow(row);
  }

  BoardItem _itemFromRow(Map<String, dynamic> row) {
    final type = BoardItemTypeWire.fromWireName(row['type'] as String);
    final startsAt = DateTime.tryParse((row['starts_at'] as String?) ?? '');
    final dueAt = DateTime.tryParse((row['due_at'] as String?) ?? '');

    return BoardItem(
      id: row['id'] as String,
      type: type,
      title: row['title'] as String,
      detail: (row['detail'] as String?) ?? '',
      owner: '\uC6B0\uB9AC',
      timeLabel: _timeLabel(type, startsAt, dueAt),
      isDone: (row['is_done'] as bool?) ?? false,
      isPinned: (row['is_pinned'] as bool?) ?? false,
    );
  }

  String _timeLabel(BoardItemType type, DateTime? startsAt, DateTime? dueAt) {
    final value = type == BoardItemType.schedule ? startsAt : dueAt;
    if (value == null) {
      return type == BoardItemType.notice ? '\uC77D\uAE30' : '\uC624\uB298';
    }

    final local = value.toLocal();
    if (type == BoardItemType.schedule) {
      return '${_two(local.hour)}:${_two(local.minute)}';
    }

    return '${local.month}/${local.day}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
