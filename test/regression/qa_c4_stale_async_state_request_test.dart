// QA-C4: Old async results must not overwrite the active board after board switching.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/board_session_controller.dart';

void main() {
  test(
    'QA-C4 keeps fresh board items, members, and invite after stale load completes',
    () async {
      final repository = _QueuedLoadRepository();
      final controller = BoardSessionController(repository);

      final staleFuture = controller.load(preferredBoardId: 'board-1');
      await repository.waitForItemLoad('board-1');

      final freshFuture = controller.load(preferredBoardId: 'board-2');
      await repository.waitForItemLoad('board-2');

      repository.completeItems('board-2');
      await repository.waitForMemberLoad('board-2');
      repository.completeMembers('board-2');
      await repository.waitForInviteLoad('board-2');
      repository.completeInvite('board-2');
      await freshFuture;

      repository.completeItems('board-1');
      await repository.waitForMemberLoad('board-1');
      repository.completeMembers('board-1');
      await repository.waitForInviteLoad('board-1');
      repository.completeInvite('board-1');
      await staleFuture;

      expect(controller.activeBoard?.id, 'board-2');
      expect(controller.items.single.id, 'item-board-2');
      expect(controller.members.single.userId, 'member-board-2');
      expect(controller.activeInvite?.code, 'INVITE-board-2');
    },
  );
}

class _QueuedLoadRepository extends BoardRepository {
  final _items = <String, Completer<List<BoardItem>>>{};
  final _members = <String, Completer<List<BoardMember>>>{};
  final _invites = <String, Completer<BoardInvite?>>{};

  @override
  Future<List<BoardSummary>> loadBoards() async => const [
        BoardSummary(
          id: 'board-1',
          name: 'First',
          role: 'admin',
          maxMembers: 4,
          memberCount: 1,
        ),
        BoardSummary(
          id: 'board-2',
          name: 'Second',
          role: 'admin',
          maxMembers: 4,
          memberCount: 1,
        ),
      ];

  @override
  Future<UserProfile?> loadMyProfile() async => const UserProfile(
        id: 'user-1',
        displayName: 'Mina',
        avatarColor: '#647D31',
      );

  @override
  Future<List<BoardItem>> loadBoardItems({String? boardId}) {
    return _items.putIfAbsent(boardId!, Completer<List<BoardItem>>.new).future;
  }

  @override
  Future<List<BoardMember>> loadMembers(String boardId) {
    return _members
        .putIfAbsent(boardId, Completer<List<BoardMember>>.new)
        .future;
  }

  @override
  Future<BoardInvite?> loadActiveInvite(String boardId) {
    return _invites.putIfAbsent(boardId, Completer<BoardInvite?>.new).future;
  }

  Future<void> waitForItemLoad(String boardId) async {
    while (!_items.containsKey(boardId)) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> waitForMemberLoad(String boardId) async {
    while (!_members.containsKey(boardId)) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> waitForInviteLoad(String boardId) async {
    while (!_invites.containsKey(boardId)) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  void completeItems(String boardId) {
    _items[boardId]!.complete([
      BoardItem(
        id: 'item-$boardId',
        type: BoardItemType.notice,
        title: boardId,
        detail: '',
        owner: 'Mina',
        timeLabel: '',
      ),
    ]);
  }

  void completeMembers(String boardId) {
    _members[boardId]!.complete([
      BoardMember(
        userId: 'member-$boardId',
        displayName: boardId,
        avatarColor: '#647D31',
        role: 'admin',
        joinedAt: DateTime(2026, 6),
      ),
    ]);
  }

  void completeInvite(String boardId) {
    _invites[boardId]!.complete(
      BoardInvite(
        id: 'invite-$boardId',
        code: 'INVITE-$boardId',
        expiresAt: DateTime(2026, 6, 30),
      ),
    );
  }
}
