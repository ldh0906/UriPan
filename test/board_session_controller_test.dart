import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/board_session_controller.dart';

void main() {
  test(
    'loads boards, keeps the preferred board active, and loads its items',
    () async {
      final repository = _FakeBoardRepository(
        boards: [
          const BoardSummary(
            id: 'first',
            name: 'First board',
            role: 'member',
            maxMembers: 4,
            memberCount: 2,
          ),
          const BoardSummary(
            id: 'second',
            name: 'Second board',
            role: 'admin',
            maxMembers: 6,
            memberCount: 1,
          ),
        ],
        itemsByBoard: {
          'second': [
            BoardItem(
              id: 'task-1',
              type: BoardItemType.task,
              title: 'Buy milk',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
              startsAt: DateTime(2026, 5, 29, 9),
            ),
          ],
        },
      );
      final controller = BoardSessionController(repository);

      await controller.load(preferredBoardId: 'second');

      expect(controller.activeBoard?.id, 'second');
      expect(controller.items.single.title, 'Buy milk');
      expect(repository.loadedItemBoardIds, ['second']);
    },
  );

  test('completing load after dispose does not notify', () async {
    final repository = _DelayedLoadRepository();
    final controller = BoardSessionController(repository);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    final loadFuture = controller.load();
    expect(notifications, 1);

    controller.dispose();
    repository.boards.complete([_adminBoard]);

    await loadFuture;
    expect(notifications, 1);
  });

  test(
    'reloads items from the repository after creating, completing, and deleting items',
    () async {
      final repository = _FakeBoardRepository(
        boards: [_adminBoard],
        itemsByBoard: {'board-1': []},
      );
      final controller = BoardSessionController(repository);
      await controller.load();

      await controller.createItem(
        const BoardItemDraft(
          type: BoardItemType.task,
          title: 'Pack bag',
          detail: '',
          tags: ['School', 'School', '  #Bag  '],
        ),
      );
      await controller.completeTask('created-1', true);

      expect(controller.items.single.id, 'created-1');
      expect(controller.items.single.isDone, isTrue);
      expect(controller.items.single.tags, ['School', 'Bag']);
      await controller.deleteItem('created-1');

      expect(controller.items, isEmpty);
      expect(repository.loadedItemBoardIds, [
        'board-1',
        'board-1',
        'board-1',
        'board-1',
      ]);
    },
  );

  test('memory-created items keep the assigned user id after reload', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.createItem(
      const BoardItemDraft(
        type: BoardItemType.task,
        title: 'Take out trash',
        detail: '',
        assignedTo: 'user-2',
      ),
    );

    expect(controller.items.single.assignedToId, 'user-2');
  });

  test('load populates members from the repository', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);

    await controller.load();

    expect(controller.members, isNotEmpty);
    expect(controller.members.first.displayName, '\uC9C0\uC6B0');
    expect(controller.members.first.isAdmin, isTrue);
  });

  test('updateMemberRole changes a member role in memory', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.updateMemberRole('memory-user-2', 'admin');

    final updated = controller.members.firstWhere(
      (member) => member.userId == 'memory-user-2',
    );
    expect(updated.role, 'admin');
    expect(updated.isAdmin, isTrue);
  });

  test('removeMember drops a member from memory', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.removeMember('memory-user-2');

    expect(
      controller.members.any((member) => member.userId == 'memory-user-2'),
      isFalse,
    );
  });

  test('updateMyProfile changes and reloads the memory profile', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.updateMyProfile(
      displayName: '\uBBFC\uC9C0',
      avatarColor: '#4B7BE7',
    );

    expect(controller.myProfile?.displayName, '\uBBFC\uC9C0');
    expect(controller.myProfile?.avatarColor, '#4B7BE7');

    final reloaded = BoardSessionController(repository);
    await reloaded.load();

    expect(reloaded.myProfile?.displayName, '\uBBFC\uC9C0');
    expect(reloaded.myProfile?.avatarColor, '#4B7BE7');
  });

  test('updateMyProfile reloads active board member and item names', () async {
    final repository = _FakeBoardRepository(
      boards: [_adminBoard],
      membersByBoard: {
        'board-1': [
          BoardMember(
            userId: 'user-1',
            displayName: 'Mina',
            avatarColor: '#647D31',
            role: 'admin',
            joinedAt: DateTime(2026, 6),
          ),
        ],
      },
      itemsByBoard: {
        'board-1': [
          const BoardItem(
            id: 'task-1',
            type: BoardItemType.task,
            title: 'Task',
            detail: '',
            owner: 'Mina',
            createdById: 'user-1',
            assignedToId: 'user-1',
            assigneeName: 'Mina',
            timeLabel: 'Today',
          ),
        ],
      },
    );
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.updateMyProfile(displayName: 'Nari');

    expect(controller.members.single.displayName, 'Nari');
    expect(controller.items.single.owner, 'Nari');
    expect(controller.items.single.assigneeName, 'Nari');
    expect(repository.loadedItemBoardIds, ['board-1', 'board-1']);
  });

  test(
    'setBoardNickname reloads active board members and item names',
    () async {
      final repository = MemoryBoardRepository([]);
      final controller = BoardSessionController(repository);
      await controller.load();

      await controller.createItem(
        const BoardItemDraft(
          type: BoardItemType.task,
          title: 'Buy milk',
          detail: '',
        ),
      );
      await controller.setBoardNickname('\uC9D1\uC9C0\uC6B0');

      expect(controller.members.first.effectiveName, '\uC9D1\uC9C0\uC6B0');
      expect(controller.items.single.owner, '\uC9D1\uC9C0\uC6B0');
    },
  );

  test('setBoardNickname clears blank nickname values', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.setBoardNickname('\uC9D1\uC9C0\uC6B0');
    await controller.setBoardNickname('');

    expect(controller.members.first.nickname, isNull);
    expect(controller.members.first.effectiveName, '\uC9C0\uC6B0');
  });

  test('updateBoard changes name and maxMembers on the active board', () async {
    final repository = MemoryBoardRepository([]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.updateBoard(name: 'New home', maxMembers: 6);

    expect(controller.activeBoard?.name, 'New home');
    expect(controller.activeBoard?.maxMembers, 6);

    final reloaded = BoardSessionController(repository);
    await reloaded.load();

    expect(reloaded.activeBoard?.name, 'New home');
    expect(reloaded.activeBoard?.maxMembers, 6);
  });

  test('load populates the active invite for admin boards', () async {
    final repository = _FakeBoardRepository(
      boards: [_adminBoard],
      itemsByBoard: {'board-1': []},
      activeInvite: BoardInvite(
        id: 'invite-1',
        code: 'URIP-0001',
        expiresAt: DateTime(2026, 6, 8),
      ),
    );
    final controller = BoardSessionController(repository);

    await controller.load();

    expect(controller.activeInvite?.code, 'URIP-0001');
  });

  test('refreshActiveInvite reloads a stale admin invite', () async {
    final repository = _FakeBoardRepository(
      boards: [_adminBoard],
      itemsByBoard: {'board-1': []},
      activeInvite: BoardInvite(
        id: 'invite-1',
        code: 'URIP-OLD',
        expiresAt: DateTime(2026, 6, 8),
      ),
    );
    final controller = BoardSessionController(repository);
    await controller.load();

    repository.activeInvite = BoardInvite(
      id: 'invite-2',
      code: 'URIP-NEW',
      expiresAt: DateTime(2026, 6, 9),
    );
    await controller.refreshActiveInvite();

    expect(controller.activeInvite?.code, 'URIP-NEW');
  });

  test(
    'regenerateInvite sets activeInvite and revokeInvite clears it',
    () async {
      final repository = MemoryBoardRepository([]);
      final controller = BoardSessionController(repository);
      await controller.load();

      final invite = await controller.regenerateInvite();

      expect(invite.code, 'URIP-2026');
      expect(controller.activeInvite?.code, 'URIP-2026');

      await controller.revokeInvite();

      expect(controller.activeInvite, isNull);
    },
  );

  test(
    'leaveBoard removes the memory membership and clears active board',
    () async {
      final repository = MemoryBoardRepository([]);
      final controller = BoardSessionController(repository);
      await controller.load();

      await controller.leaveBoard();

      expect(controller.activeBoard, isNull);
      expect(controller.boards, isEmpty);
      expect(controller.items, isEmpty);
      expect(controller.members, isEmpty);
    },
  );

  test(
    'updateItem changes a memory item and reloads controller items',
    () async {
      final repository = MemoryBoardRepository([
        BoardItem(
          id: 'task-1',
          type: BoardItemType.task,
          title: 'Old title',
          detail: 'Old detail',
          owner: 'Us',
          timeLabel: 'Today',
          dueAt: DateTime(2026, 6, 1, 9),
          isDone: true,
          tags: const ['Old'],
        ),
      ]);
      final controller = BoardSessionController(repository);
      await controller.load();

      await controller.updateItem(
        'task-1',
        BoardItemDraft(
          type: BoardItemType.task,
          title: 'New title',
          detail: 'New detail',
          dueAt: DateTime(2026, 6, 2, 18),
          isPinned: true,
          tags: const ['Home', 'Home', '#Errand'],
        ),
      );

      final item = controller.items.single;
      expect(item.id, 'task-1');
      expect(item.type, BoardItemType.task);
      expect(item.title, 'New title');
      expect(item.detail, 'New detail');
      expect(item.isDone, isTrue);
      expect(item.isPinned, isTrue);
      expect(item.tags, ['Home', 'Errand']);
      expect(item.dueAt, DateTime(2026, 6, 2, 18));
    },
  );

  test('updateItem persists task reassignment and clearing assignee', () async {
    final repository = MemoryBoardRepository([
      const BoardItem(
        id: 'task-1',
        type: BoardItemType.task,
        title: 'Task',
        detail: '',
        owner: 'Us',
        assignedToId: 'user-2',
        timeLabel: 'Today',
      ),
    ]);
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.updateItem(
      'task-1',
      const BoardItemDraft(
        type: BoardItemType.task,
        title: 'Task',
        detail: '',
        assignedTo: 'user-1',
      ),
    );

    expect(controller.items.single.assignedToId, 'user-1');

    await controller.updateItem(
      'task-1',
      const BoardItemDraft(type: BoardItemType.task, title: 'Task', detail: ''),
    );

    expect(controller.items.single.assignedToId, isNull);
  });

  test(
    'reconciles boards and items when membership changes through realtime',
    () async {
      final repository = _FakeBoardRepository(
        boards: [_adminBoard],
        itemsByBoard: {'board-1': []},
      );
      final controller = BoardSessionController(repository);
      await controller.load();

      repository.boards = [];
      await controller.handleBoardMembershipChanged();

      expect(controller.activeBoard, isNull);
      expect(controller.items, isEmpty);
    },
  );

  test(
    'switchBoard selects another board and skips active board reload',
    () async {
      final repository = _FakeBoardRepository(
        boards: [_adminBoard, _secondBoard],
        itemsByBoard: {
          'board-1': [
            const BoardItem(
              id: 'first-item',
              type: BoardItemType.task,
              title: 'First item',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
            ),
          ],
          'board-2': [
            const BoardItem(
              id: 'second-item',
              type: BoardItemType.notice,
              title: 'Second item',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
            ),
          ],
        },
      );
      final controller = BoardSessionController(repository);
      await controller.load();

      await controller.switchBoard('board-2');
      await controller.switchBoard('board-2');

      expect(controller.activeBoard?.id, 'board-2');
      expect(controller.items.single.id, 'second-item');
      expect(repository.loadedItemBoardIds, ['board-1', 'board-2']);
    },
  );

  test('confirmNotice reloads items with my confirmation state', () async {
    final repository = _FakeBoardRepository(
      boards: [_adminBoard],
      itemsByBoard: {
        'board-1': [
          const BoardItem(
            id: 'notice-1',
            type: BoardItemType.notice,
            title: 'Read this',
            detail: '',
            owner: 'Us',
            timeLabel: 'Read',
            requiresConfirmation: true,
          ),
        ],
      },
    );
    final controller = BoardSessionController(repository);
    await controller.load();

    await controller.confirmNotice('notice-1', true);

    expect(controller.items.single.confirmationCount, 1);
    expect(controller.items.single.isConfirmedByMe, isTrue);
    expect(repository.loadedItemBoardIds, ['board-1', 'board-1']);
  });

  test('reloads active board items when item realtime events arrive', () async {
    final repository = _FakeBoardRepository(
      boards: [_adminBoard],
      itemsByBoard: {'board-1': []},
    );
    final controller = BoardSessionController(repository);
    await controller.load();

    repository.itemsByBoard['board-1'] = [
      const BoardItem(
        id: 'notice-1',
        type: BoardItemType.notice,
        title: 'Door code changed',
        detail: '',
        owner: 'Us',
        timeLabel: 'Read',
      ),
    ];
    await controller.handleBoardItemsChanged();

    expect(controller.items.single.id, 'notice-1');
    expect(repository.loadedItemBoardIds, ['board-1', 'board-1']);
  });

  test('ignores stale item refreshes after active board changes', () async {
    final repository = _FakeBoardRepository(
      boards: [_adminBoard],
      itemsByBoard: {
        'board-1': [
          const BoardItem(
            id: 'initial',
            type: BoardItemType.task,
            title: 'Initial task',
            detail: '',
            owner: 'Us',
            timeLabel: 'Today',
          ),
        ],
      },
    );
    final controller = BoardSessionController(repository);
    await controller.load();

    final staleRefresh = Completer<List<BoardItem>>();
    final freshLoad = Completer<List<BoardItem>>();
    repository.queuedItemLoads.add(staleRefresh);
    final staleFuture = controller.refreshItems();

    repository
      ..boards = [_secondBoard]
      ..queuedItemLoads.add(freshLoad);
    final freshFuture = controller.handleBoardMembershipChanged();

    freshLoad.complete([
      const BoardItem(
        id: 'fresh',
        type: BoardItemType.notice,
        title: 'Fresh board item',
        detail: '',
        owner: 'Us',
        timeLabel: 'Read',
      ),
    ]);
    await freshFuture;

    staleRefresh.complete([
      const BoardItem(
        id: 'stale',
        type: BoardItemType.notice,
        title: 'Stale item',
        detail: '',
        owner: 'Us',
        timeLabel: 'Read',
      ),
    ]);
    await staleFuture;

    expect(controller.activeBoard?.id, 'board-2');
    expect(controller.items.single.id, 'fresh');
    expect(repository.loadedItemBoardIds, ['board-1', 'board-1', 'board-2']);
  });
}

class _DelayedLoadRepository extends BoardRepository {
  final boards = Completer<List<BoardSummary>>();

  @override
  Future<List<BoardSummary>> loadBoards() => boards.future;

  @override
  Future<UserProfile?> loadMyProfile() async {
    return const UserProfile(
      id: 'user-1',
      displayName: 'Mina',
      avatarColor: '#647D31',
    );
  }

  @override
  Future<List<BoardItem>> loadBoardItems({String? boardId}) async => const [];

  @override
  Future<List<BoardMember>> loadMembers(String boardId) async => const [];
}

const _adminBoard = BoardSummary(
  id: 'board-1',
  name: 'Home',
  role: 'admin',
  maxMembers: 4,
  memberCount: 1,
);

const _secondBoard = BoardSummary(
  id: 'board-2',
  name: 'Second home',
  role: 'admin',
  maxMembers: 5,
  memberCount: 2,
);

class _FakeBoardRepository implements BoardRepository {
  _FakeBoardRepository({
    required List<BoardSummary> boards,
    required this.itemsByBoard,
    Map<String, List<BoardMember>>? membersByBoard,
    this.activeInvite,
    UserProfile? myProfile,
  }) : boards = List.of(boards),
       membersByBoard = membersByBoard ?? const {},
       myProfile =
           myProfile ??
           const UserProfile(
             id: 'user-1',
             displayName: 'Mina',
             avatarColor: '#647D31',
           );

  List<BoardSummary> boards;
  Map<String, List<BoardItem>> itemsByBoard;
  Map<String, List<BoardMember>> membersByBoard;
  BoardInvite? activeInvite;
  UserProfile? myProfile;
  final queuedItemLoads = <Completer<List<BoardItem>>>[];
  final loadedItemBoardIds = <String?>[];

  @override
  Future<List<BoardSummary>> loadBoards() async => List.unmodifiable(boards);

  @override
  Future<UserProfile?> loadMyProfile() async => myProfile;

  @override
  Future<UserProfile> updateMyProfile({
    String? displayName,
    String? avatarColor,
  }) async {
    final old = myProfile!;
    final updated = UserProfile(
      id: old.id,
      displayName: displayName ?? old.displayName,
      avatarColor: avatarColor ?? old.avatarColor,
    );
    myProfile = updated;
    if (displayName != null) {
      for (final entry in membersByBoard.entries) {
        membersByBoard[entry.key] = entry.value
            .map(
              (member) => member.userId == updated.id
                  ? BoardMember(
                      userId: member.userId,
                      displayName: displayName,
                      avatarColor: avatarColor ?? member.avatarColor,
                      role: member.role,
                      joinedAt: member.joinedAt,
                      nickname: member.nickname,
                    )
                  : member,
            )
            .toList();
      }
      for (final entry in itemsByBoard.entries) {
        itemsByBoard[entry.key] = entry.value
            .map(
              (item) => item.copyWith(
                owner: item.createdById == updated.id ? displayName : null,
                assigneeName: item.assignedToId == updated.id
                    ? displayName
                    : null,
              ),
            )
            .toList();
      }
    }
    return updated;
  }

  @override
  Future<List<BoardMember>> loadMembers(String boardId) async {
    return List.unmodifiable(membersByBoard[boardId] ?? const []);
  }

  @override
  Future<BoardSummary> createBoard(String name, int maxMembers) async {
    final board = BoardSummary(
      id: 'created-board',
      name: name,
      role: 'admin',
      maxMembers: maxMembers,
      memberCount: 1,
    );
    boards.add(board);
    itemsByBoard[board.id] = [];
    return board;
  }

  @override
  Future<BoardSummary> updateBoard(
    String boardId, {
    String? name,
    int? maxMembers,
  }) async {
    final index = boards.indexWhere((board) => board.id == boardId);
    if (index < 0) throw StateError('Board not found');

    final old = boards[index];
    final updated = BoardSummary(
      id: old.id,
      name: name ?? old.name,
      role: old.role,
      maxMembers: maxMembers ?? old.maxMembers,
      memberCount: old.memberCount,
    );
    boards[index] = updated;
    return updated;
  }

  @override
  Future<BoardInvite> createInvite(String boardId) async {
    final invite = BoardInvite(
      id: 'invite-1',
      code: 'URIP-0001',
      expiresAt: DateTime(2026, 6),
    );
    activeInvite = invite;
    return invite;
  }

  @override
  Future<BoardInvite?> loadActiveInvite(String boardId) async => activeInvite;

  @override
  Future<void> revokeInvite(String inviteId) async {
    activeInvite = null;
  }

  @override
  Future<BoardSummary> joinBoardWithInvite(String code) async => boards.first;

  @override
  Future<void> leaveBoard(String boardId) async {
    boards.removeWhere((board) => board.id == boardId);
    itemsByBoard.remove(boardId);
    membersByBoard.remove(boardId);
    activeInvite = null;
  }

  @override
  Future<void> setBoardNickname(String boardId, String? nickname) async {}

  @override
  Future<void> updateMemberRole(
    String boardId,
    String userId,
    String role,
  ) async {
    final members = membersByBoard[boardId];
    if (members == null) throw StateError('Board not found');
    final index = members.indexWhere((member) => member.userId == userId);
    if (index < 0) throw StateError('Member not found');
    final old = members[index];
    members[index] = BoardMember(
      userId: old.userId,
      displayName: old.displayName,
      avatarColor: old.avatarColor,
      role: role,
      joinedAt: old.joinedAt,
      nickname: old.nickname,
    );
  }

  @override
  Future<void> removeMember(String boardId, String userId) async {
    final members = membersByBoard[boardId];
    if (members == null) throw StateError('Board not found');
    final before = members.length;
    members.removeWhere((member) => member.userId == userId);
    if (members.length == before) throw StateError('Member not found');
  }

  @override
  Future<List<BoardItem>> loadBoardItems({String? boardId}) async {
    loadedItemBoardIds.add(boardId);
    if (queuedItemLoads.isNotEmpty) {
      return queuedItemLoads.removeAt(0).future;
    }
    return List.unmodifiable(itemsByBoard[boardId] ?? const []);
  }

  @override
  Future<BoardItem> createItem(String boardId, BoardItemDraft draft) async {
    final item = BoardItem(
      id: 'created-1',
      type: draft.type,
      title: draft.title,
      detail: draft.detail,
      owner: 'Us',
      assignedToId: draft.assignedTo,
      timeLabel: 'Today',
      startsAt: draft.startsAt,
      dueAt: draft.dueAt,
      tags: normalizeBoardItemTags(draft.tags),
      requiresConfirmation: draft.requiresConfirmation,
    );
    itemsByBoard[boardId] = [...itemsByBoard[boardId] ?? const [], item];
    return item;
  }

  @override
  Future<void> createRecurringItem(String boardId, BoardItemDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateRecurringSeries(
    String recurrenceId,
    BoardItemDraft draft,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> ensureRecurrences(String boardId) async {}

  @override
  Future<BoardItem> updateItem(String itemId, BoardItemDraft draft) async {
    for (final entry in itemsByBoard.entries) {
      final index = entry.value.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        final old = entry.value[index];
        final updated = old.copyWith(
          title: draft.title,
          detail: draft.detail,
          startsAt: draft.startsAt,
          dueAt: draft.dueAt,
          assignedToId: draft.assignedTo,
          isPinned: draft.isPinned,
          requiresConfirmation: draft.requiresConfirmation,
          tags: normalizeBoardItemTags(draft.tags),
        );
        entry.value[index] = updated;
        return updated;
      }
    }
    throw StateError('Item not found');
  }

  @override
  Future<BoardItem> completeTask(String itemId, bool isDone) async {
    for (final entry in itemsByBoard.entries) {
      final index = entry.value.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        final old = entry.value[index];
        final updated = old.copyWith(isDone: isDone);
        entry.value[index] = updated;
        return updated;
      }
    }
    throw StateError('Item not found');
  }

  @override
  Future<void> confirmNotice(String itemId, bool confirmed) async {
    for (final entry in itemsByBoard.entries) {
      final index = entry.value.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        final old = entry.value[index];
        entry.value[index] = old.copyWith(
          confirmationCount: confirmed ? 1 : 0,
          isConfirmedByMe: confirmed,
        );
        return;
      }
    }
    throw StateError('Item not found');
  }

  @override
  Future<List<BoardComment>> loadComments(
    String itemId, {
    String? boardId,
  }) async => const [];

  @override
  Future<BoardComment> addComment(String itemId, String body) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteComment(String commentId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteItem(String itemId) async {
    for (final entry in itemsByBoard.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((item) => item.id == itemId);
      if (entry.value.length != before) return;
    }
    throw StateError('Item not found');
  }
}
