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

  Future<List<BoardItem>> loadBoardItems({String? boardId});
  Future<BoardItem> createItem(String boardId, BoardItemDraft draft) {
    throw UnimplementedError();
  }

  Future<BoardItem> updateItem(String itemId, BoardItemDraft draft) {
    throw UnimplementedError();
  }

  Future<BoardItem> completeTask(String itemId, bool isDone) {
    throw UnimplementedError();
  }

  Future<void> confirmNotice(String itemId, bool confirmed) {
    throw UnimplementedError();
  }

  Future<void> deleteItem(String itemId) {
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
  Future<List<BoardItem>> loadBoardItems({String? boardId}) async {
    return List.unmodifiable(_items);
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
    final item = BoardItem(
      id: 'memory-item-${_items.length + 1}',
      type: draft.type,
      title: draft.title,
      detail: draft.detail,
      owner: '\uC6B0\uB9AC',
      assignedToId: draft.assignedTo,
      timeLabel: _timeLabel(draft.type, startsAt, dueAt),
      startsAt: startsAt,
      dueAt: dueAt,
      isPinned: draft.isPinned,
      requiresConfirmation: draft.requiresConfirmation,
      tags: normalizeBoardItemTags(draft.tags),
    );
    _items.add(item);
    return item;
  }

  @override
  Future<BoardItem> updateItem(String itemId, BoardItemDraft draft) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) throw StateError('Item not found');

    final old = _items[index];
    final startsAt = draft.type == BoardItemType.schedule
        ? draft.startsAt ?? DateTime.now()
        : draft.startsAt;
    final dueAt = draft.type == BoardItemType.task
        ? draft.dueAt ?? DateTime.now()
        : draft.dueAt;
    final updated = old.copyWith(
      title: draft.title,
      detail: draft.detail,
      timeLabel: _timeLabel(old.type, startsAt, dueAt),
      startsAt: startsAt,
      dueAt: dueAt,
      isPinned: draft.isPinned,
      requiresConfirmation: draft.requiresConfirmation,
      tags: normalizeBoardItemTags(draft.tags),
    );
    _items[index] = updated;
    return updated;
  }

  @override
  Future<BoardItem> completeTask(String itemId, bool isDone) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) throw StateError('Item not found');
    final old = _items[index];
    final updated = old.copyWith(isDone: isDone);
    _items[index] = updated;
    return updated;
  }

  @override
  Future<void> confirmNotice(String itemId, bool confirmed) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index < 0) throw StateError('Item not found');

    final old = _items[index];
    if (confirmed && !old.isConfirmedByMe) {
      _items[index] = old.copyWith(
        isConfirmedByMe: true,
        confirmationCount: old.confirmationCount + 1,
      );
    } else if (!confirmed && old.isConfirmedByMe) {
      _items[index] = old.copyWith(
        isConfirmedByMe: false,
        confirmationCount: old.confirmationCount > 0
            ? old.confirmationCount - 1
            : 0,
      );
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    final before = _items.length;
    _items.removeWhere((item) => item.id == itemId);
    if (_items.length == before) throw StateError('Item not found');
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

class SupabaseBoardRepository implements BoardRepository {
  const SupabaseBoardRepository(this._client);

  static const _itemSelectColumns =
      'id, type, title, detail, starts_at, due_at, is_done, is_pinned, requires_confirmation, tags, created_by, assigned_to, item_confirmations(user_id)';

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
  Future<List<BoardItem>> loadBoardItems({String? boardId}) async {
    if (boardId == null) return const [];

    final rows = await _client
        .from('board_items')
        .select(_itemSelectColumns)
        .eq('board_id', boardId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);

    final names = await _displayNames(_userIdsFromRows(rows));
    return rows
        .map<BoardItem>((row) => _itemFromRow(row, names))
        .toList(growable: false);
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
          'tags': normalizeBoardItemTags(draft.tags),
        })
        .select(_itemSelectColumns)
        .single();

    final names = await _displayNames(_userIdsFromRow(row));
    return _itemFromRow(row, names);
  }

  @override
  Future<BoardItem> updateItem(String itemId, BoardItemDraft draft) async {
    final now = DateTime.now();
    final startsAt = draft.type == BoardItemType.schedule
        ? draft.startsAt ?? now
        : draft.startsAt;
    final dueAt = draft.type == BoardItemType.task
        ? draft.dueAt ?? now
        : draft.dueAt;

    final row = await _client
        .from('board_items')
        .update({
          'title': draft.title,
          'detail': draft.detail,
          'starts_at': startsAt?.toIso8601String(),
          'due_at': dueAt?.toIso8601String(),
          'requires_confirmation': draft.requiresConfirmation,
          'is_pinned': draft.isPinned,
          'tags': normalizeBoardItemTags(draft.tags),
        })
        .eq('id', itemId)
        .select(_itemSelectColumns)
        .single();

    final names = await _displayNames(_userIdsFromRow(row));
    return _itemFromRow(row, names);
  }

  @override
  Future<BoardItem> completeTask(String itemId, bool isDone) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'complete_task',
      params: {'target_item_id': itemId, 'completed': isDone},
    );

    final names = await _displayNames(_userIdsFromRow(row));
    return _itemFromRow(row, names);
  }

  @override
  Future<void> confirmNotice(String itemId, bool confirmed) async {
    final userId = _client.auth.currentUser!.id;
    if (confirmed) {
      await _client.from('item_confirmations').insert({
        'item_id': itemId,
        'user_id': userId,
      });
      return;
    }

    await _client
        .from('item_confirmations')
        .delete()
        .eq('item_id', itemId)
        .eq('user_id', userId);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _client.from('board_items').delete().eq('id', itemId);
  }

  Future<Map<String, String>> _displayNames(Set<String> userIds) async {
    if (userIds.isEmpty) return const {};

    final rows = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', userIds.toList());

    return {
      for (final row in rows)
        if (row['id'] is String && row['display_name'] is String)
          row['id'] as String: row['display_name'] as String,
    };
  }

  Set<String> _userIdsFromRows(Iterable<Map<String, dynamic>> rows) {
    return rows.expand(_userIdsFromRow).toSet();
  }

  Set<String> _userIdsFromRow(Map<String, dynamic> row) {
    return {
      if (row['created_by'] case final String createdBy) createdBy,
      if (row['assigned_to'] case final String assignedTo) assignedTo,
    };
  }

  BoardItem _itemFromRow(Map<String, dynamic> row, Map<String, String> names) {
    final type = BoardItemTypeWire.fromWireName(row['type'] as String);
    final startsAt = DateTime.tryParse((row['starts_at'] as String?) ?? '');
    final dueAt = DateTime.tryParse((row['due_at'] as String?) ?? '');
    final confirmations = (row['item_confirmations'] as List?) ?? const [];
    final currentUserId = _client.auth.currentUser?.id;
    final createdById = row['created_by'] as String?;
    final assignedToId = row['assigned_to'] as String?;

    return BoardItem(
      id: row['id'] as String,
      type: type,
      title: row['title'] as String,
      detail: (row['detail'] as String?) ?? '',
      owner: names[createdById] ?? '???',
      createdById: createdById,
      assignedToId: assignedToId,
      assigneeName: assignedToId == null ? null : names[assignedToId],
      timeLabel: _timeLabel(type, startsAt, dueAt),
      startsAt: startsAt,
      dueAt: dueAt,
      isDone: (row['is_done'] as bool?) ?? false,
      isPinned: (row['is_pinned'] as bool?) ?? false,
      requiresConfirmation: (row['requires_confirmation'] as bool?) ?? false,
      confirmationCount: confirmations.length,
      isConfirmedByMe:
          currentUserId != null &&
          confirmations.any((confirmation) {
            if (confirmation is! Map) return false;
            return confirmation['user_id'] == currentUserId;
          }),
      tags: _tagsFromRow(row['tags']),
    );
  }

  List<String> _tagsFromRow(Object? value) {
    if (value is List) {
      return normalizeBoardItemTags(value.whereType<String>());
    }
    return const [];
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
