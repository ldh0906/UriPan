import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/board_item.dart';

abstract class BoardRepository {
  Future<List<BoardSummary>> loadBoards() async => const [];
  Future<UserProfile?> loadMyProfile() async => null;
  Future<List<BoardMember>> loadMembers(String boardId) async => const [];
  Future<BoardSummary> createBoard(String name, int maxMembers) {
    throw UnimplementedError();
  }

  Future<BoardSummary> updateBoard(
    String boardId, {
    String? name,
    int? maxMembers,
  }) {
    throw UnimplementedError();
  }

  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? avatarColor,
  }) {
    throw UnimplementedError();
  }

  Future<BoardInvite> createInvite(String boardId) {
    throw UnimplementedError();
  }

  Future<BoardInvite?> loadActiveInvite(String boardId) async => null;

  Future<void> revokeInvite(String inviteId) {
    throw UnimplementedError();
  }

  Future<BoardSummary> joinBoardWithInvite(String code) {
    throw UnimplementedError();
  }

  Future<void> leaveBoard(String boardId) {
    throw UnimplementedError();
  }

  Future<void> updateMemberRole(String boardId, String userId, String role) {
    throw UnimplementedError();
  }

  Future<void> removeMember(String boardId, String userId) {
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
  BoardInvite? _activeInvite;
  final List<BoardSummary> _boards = [
    const BoardSummary(
      id: 'memory-board',
      name: '\uC6B0\uB9AC\uC9D1',
      role: 'admin',
      maxMembers: 4,
      memberCount: 2,
    ),
  ];
  final List<BoardMember> _members = [
    BoardMember(
      userId: 'memory-user-1',
      displayName: '\uC9C0\uC6B0',
      avatarColor: '#647D31',
      role: 'admin',
      joinedAt: DateTime(2026, 6),
    ),
    BoardMember(
      userId: 'memory-user-2',
      displayName: '\uBBFC\uC900',
      avatarColor: '#E7A14B',
      role: 'member',
      joinedAt: DateTime(2026, 6, 1, 1),
    ),
  ];
  UserProfile _myProfile = const UserProfile(
    id: 'memory-user-1',
    displayName: '\uC9C0\uC6B0',
    avatarColor: '#647D31',
  );

  @override
  Future<List<BoardSummary>> loadBoards() async => List.unmodifiable(_boards);

  @override
  Future<UserProfile?> loadMyProfile() async => _myProfile;

  @override
  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? avatarColor,
  }) async {
    _myProfile = UserProfile(
      id: _myProfile.id,
      displayName: displayName ?? _myProfile.displayName,
      avatarColor: avatarColor ?? _myProfile.avatarColor,
    );
    return _myProfile;
  }

  @override
  Future<List<BoardMember>> loadMembers(String boardId) async {
    return List.unmodifiable(_members);
  }

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
  Future<BoardSummary> updateBoard(
    String boardId, {
    String? name,
    int? maxMembers,
  }) async {
    final index = _boards.indexWhere((board) => board.id == boardId);
    if (index < 0) throw StateError('Board not found');

    final old = _boards[index];
    final updated = BoardSummary(
      id: old.id,
      name: name ?? old.name,
      role: old.role,
      maxMembers: maxMembers ?? old.maxMembers,
      memberCount: old.memberCount,
    );
    _boards[index] = updated;
    return updated;
  }

  @override
  Future<BoardInvite> createInvite(String boardId) async {
    final invite = BoardInvite(
      id: 'memory-invite',
      code: 'URIP-2026',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    );
    _activeInvite = invite;
    return invite;
  }

  @override
  Future<BoardInvite?> loadActiveInvite(String boardId) async {
    final invite = _activeInvite;
    if (invite == null || invite.expiresAt.isBefore(DateTime.now())) {
      return null;
    }
    return invite;
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    _activeInvite = null;
  }

  @override
  Future<BoardSummary> joinBoardWithInvite(String code) async => _boards.first;

  @override
  Future<void> leaveBoard(String boardId) async {
    _boards.removeWhere((board) => board.id == boardId);
    _members.clear();
    _activeInvite = null;
  }

  @override
  Future<void> updateMemberRole(
    String boardId,
    String userId,
    String role,
  ) async {
    final index = _members.indexWhere((member) => member.userId == userId);
    if (index < 0) throw StateError('Member not found');
    final old = _members[index];
    _members[index] = BoardMember(
      userId: old.userId,
      displayName: old.displayName,
      avatarColor: old.avatarColor,
      role: role,
      joinedAt: old.joinedAt,
    );
  }

  @override
  Future<void> removeMember(String boardId, String userId) async {
    final before = _members.length;
    _members.removeWhere((member) => member.userId == userId);
    if (_members.length == before) throw StateError('Member not found');
    _updateBoardMemberCount(boardId);
  }

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
      assignedToId: draft.type == BoardItemType.task ? draft.assignedTo : null,
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

  void _updateBoardMemberCount(String boardId) {
    final index = _boards.indexWhere((board) => board.id == boardId);
    if (index < 0) return;
    final old = _boards[index];
    _boards[index] = BoardSummary(
      id: old.id,
      name: old.name,
      role: old.role,
      maxMembers: old.maxMembers,
      memberCount: _members.length,
    );
  }
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
        .map<BoardSummary>(_boardSummaryFromMembershipRow)
        .toList(growable: false);
  }

  @override
  Future<UserProfile?> loadMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final rows = await _client
        .from('profiles')
        .select('id, display_name, avatar_color')
        .eq('id', userId)
        .limit(1);

    if (rows.isEmpty) return null;
    return _userProfileFromRow(Map<String, dynamic>.from(rows.first as Map));
  }

  @override
  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? avatarColor,
  }) async {
    final values = <String, dynamic>{};
    if (displayName != null) values['display_name'] = displayName;
    if (avatarColor != null) values['avatar_color'] = avatarColor;
    final userId = _client.auth.currentUser!.id;

    final row = await _client
        .from('profiles')
        .update(values)
        .eq('id', userId)
        .select('id, display_name, avatar_color')
        .single();

    return _userProfileFromRow(Map<String, dynamic>.from(row));
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
  Future<BoardSummary> updateBoard(
    String boardId, {
    String? name,
    int? maxMembers,
  }) async {
    final values = <String, dynamic>{};
    if (name != null) values['name'] = name;
    if (maxMembers != null) values['max_members'] = maxMembers;
    if (values.isNotEmpty) {
      await _client.from('boards').update(values).eq('id', boardId);
    }

    final rows = await _client
        .from('board_members')
        .select('role, boards(id, name, max_members, board_members(user_id))')
        .eq('board_id', boardId)
        .eq('user_id', _client.auth.currentUser!.id)
        .limit(1);

    if (rows.isEmpty) throw StateError('Board not found');
    return _boardSummaryFromMembershipRow(
      Map<String, dynamic>.from(rows.first as Map),
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
  Future<BoardInvite?> loadActiveInvite(String boardId) async {
    final rows = await _client
        .from('board_invites')
        .select('id, code, expires_at')
        .eq('board_id', boardId)
        .filter('revoked_at', 'is', null)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('expires_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return _inviteFromRow(Map<String, dynamic>.from(rows.first as Map));
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    await _client.rpc<void>(
      'revoke_board_invite',
      params: {'target_invite_id': inviteId},
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
  Future<void> leaveBoard(String boardId) async {
    await _client
        .from('board_members')
        .delete()
        .eq('board_id', boardId)
        .eq('user_id', _client.auth.currentUser!.id);
  }

  @override
  Future<void> updateMemberRole(
    String boardId,
    String userId,
    String role,
  ) async {
    await _client
        .from('board_members')
        .update({'role': role})
        .eq('board_id', boardId)
        .eq('user_id', userId);
  }

  @override
  Future<void> removeMember(String boardId, String userId) async {
    await _client
        .from('board_members')
        .delete()
        .eq('board_id', boardId)
        .eq('user_id', userId);
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
  Future<List<BoardMember>> loadMembers(String boardId) async {
    final memberRows = await _client
        .from('board_members')
        .select('user_id, role, joined_at')
        .eq('board_id', boardId);
    final userIds = memberRows
        .map<String?>((row) => row['user_id'] as String?)
        .whereType<String>()
        .toSet();
    final profiles = await _profiles(userIds);
    final members = memberRows
        .map<BoardMember>((row) {
          final userId = row['user_id'] as String;
          final profile = profiles[userId];
          return BoardMember(
            userId: userId,
            displayName: profile?.displayName ?? userId,
            avatarColor: profile?.avatarColor ?? '#647D31',
            role: row['role'] as String,
            joinedAt: DateTime.parse(row['joined_at'] as String),
          );
        })
        .toList(growable: false);

    return members.toList()..sort((a, b) {
      if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });
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
          'assigned_to': draft.type == BoardItemType.task
              ? draft.assignedTo
              : null,
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

  BoardSummary _boardSummaryFromMembershipRow(Map<String, dynamic> row) {
    final board = Map<String, dynamic>.from(row['boards'] as Map);
    final members = (board['board_members'] as List?) ?? const [];
    return BoardSummary(
      id: board['id'] as String,
      name: board['name'] as String,
      role: row['role'] as String,
      maxMembers: board['max_members'] as int,
      memberCount: members.length,
    );
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

  Future<Map<String, _ProfileRow>> _profiles(Set<String> userIds) async {
    if (userIds.isEmpty) return const {};

    final rows = await _client
        .from('profiles')
        .select('id, display_name, avatar_color')
        .inFilter('id', userIds.toList());

    return {
      for (final row in rows)
        if (row['id'] is String)
          row['id'] as String: _ProfileRow(
            displayName: row['display_name'] as String?,
            avatarColor: row['avatar_color'] as String?,
          ),
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

  BoardInvite _inviteFromRow(Map<String, dynamic> row) {
    return BoardInvite(
      id: row['id'] as String,
      code: row['code'] as String,
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }

  UserProfile _userProfileFromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      displayName: row['display_name'] as String,
      avatarColor: row['avatar_color'] as String,
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

class _ProfileRow {
  const _ProfileRow({required this.displayName, required this.avatarColor});

  final String? displayName;
  final String? avatarColor;
}
