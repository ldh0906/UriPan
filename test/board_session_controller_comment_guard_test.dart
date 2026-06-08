import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/board_session_controller.dart';

void main() {
  test(
    'ignores stale comment add reloads after active board changes',
    () async {
      final repository = _CommentGuardRepository();
      final controller = BoardSessionController(repository);
      await controller.load();

      final staleReload = Completer<List<BoardItem>>();
      final freshReload = Completer<List<BoardItem>>();
      repository.queuedItemLoads.add(staleReload);
      final staleFuture = controller.addComment('item-1', 'old board comment');

      repository
        ..boards = const [_secondBoard]
        ..queuedItemLoads.add(freshReload);
      final freshFuture = controller.handleBoardMembershipChanged();

      freshReload.complete([_item('fresh')]);
      await freshFuture;

      staleReload.complete([_item('stale')]);
      await staleFuture;

      expect(controller.activeBoard?.id, 'board-2');
      expect(controller.items.single.id, 'fresh');
    },
  );

  test(
    'ignores stale comment delete reloads after active board changes',
    () async {
      final repository = _CommentGuardRepository();
      final controller = BoardSessionController(repository);
      await controller.load();

      final staleReload = Completer<List<BoardItem>>();
      final freshReload = Completer<List<BoardItem>>();
      repository.queuedItemLoads.add(staleReload);
      final staleFuture = controller.deleteComment('comment-1');

      repository
        ..boards = const [_secondBoard]
        ..queuedItemLoads.add(freshReload);
      final freshFuture = controller.handleBoardMembershipChanged();

      freshReload.complete([_item('fresh')]);
      await freshFuture;

      staleReload.complete([_item('stale')]);
      await staleFuture;

      expect(controller.activeBoard?.id, 'board-2');
      expect(controller.items.single.id, 'fresh');
    },
  );
}

const _firstBoard = BoardSummary(
  id: 'board-1',
  name: 'Home',
  role: 'member',
  maxMembers: 4,
  memberCount: 1,
);

const _secondBoard = BoardSummary(
  id: 'board-2',
  name: 'Second home',
  role: 'member',
  maxMembers: 4,
  memberCount: 1,
);

BoardItem _item(String id) {
  return BoardItem(
    id: id,
    type: BoardItemType.notice,
    title: id,
    detail: '',
    owner: 'Mina',
    timeLabel: '',
  );
}

class _CommentGuardRepository extends BoardRepository {
  List<BoardSummary> boards = const [_firstBoard];
  final queuedItemLoads = <Completer<List<BoardItem>>>[];

  @override
  Future<List<BoardSummary>> loadBoards() async => boards;

  @override
  Future<List<BoardMember>> loadMembers(String boardId) async => const [];

  @override
  Future<List<BoardItem>> loadBoardItems({String? boardId}) {
    if (queuedItemLoads.isNotEmpty) {
      return queuedItemLoads.removeAt(0).future;
    }
    return Future.value([_item('initial')]);
  }

  @override
  Future<BoardComment> addComment(String itemId, String body) async {
    return BoardComment(
      id: 'comment-1',
      itemId: itemId,
      authorId: 'user-1',
      authorName: 'Mina',
      authorAvatarColor: '#647D31',
      body: body,
      createdAt: DateTime(2026, 6, 8),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {}
}
