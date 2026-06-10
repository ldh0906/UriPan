import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';

void main() {
  group('MemoryBoardRepository comments', () {
    test('addComment then loadComments returns the comment', () async {
      final repository = MemoryBoardRepository([_item(id: 'item-1')]);

      final comment = await repository.addComment('item-1', 'Looks good');
      final comments = await repository.loadComments('item-1');
      final items = await repository.loadBoardItems();

      expect(comments, [comment]);
      expect(comment.id, 'memory-comment-1');
      expect(comment.itemId, 'item-1');
      expect(comment.authorId, 'memory-user-1');
      expect(comment.authorName, '\uC9C0\uC6B0');
      expect(comment.authorAvatarColor, '#647D31');
      expect(comment.body, 'Looks good');
      expect(items.single.commentCount, 1);
    });

    test('loadComments returns multiple comments sorted ascending', () async {
      final repository = MemoryBoardRepository([_item(id: 'item-1')]);

      final first = await repository.addComment('item-1', 'First');
      await Future<void>.delayed(const Duration(milliseconds: 1));
      final second = await repository.addComment('item-1', 'Second');

      expect(await repository.loadComments('item-1'), [first, second]);
      expect(first.createdAt.isAfter(second.createdAt), isFalse);
    });

    test('deleteComment removes the comment', () async {
      final repository = MemoryBoardRepository([_item(id: 'item-1')]);
      final comment = await repository.addComment('item-1', 'Remove me');

      await repository.deleteComment(comment.id);
      final items = await repository.loadBoardItems();

      expect(await repository.loadComments('item-1'), isEmpty);
      expect(items.single.commentCount, 0);
    });

    test('deleteComment throws when the comment is missing', () async {
      final repository = MemoryBoardRepository([]);

      expect(
        () => repository.deleteComment('missing-comment'),
        throwsStateError,
      );
    });

    test('loadComments for an unrelated item returns empty', () async {
      final repository = MemoryBoardRepository([_item(id: 'item-1')]);
      await repository.addComment('item-1', 'Only item one');

      expect(await repository.loadComments('item-2'), isEmpty);
    });
  });

  group('MemoryBoardRepository board nicknames', () {
    test('setBoardNickname changes member, item, and comment names', () async {
      final repository = MemoryBoardRepository([]);
      await repository.setBoardNickname('memory-board', '\uC9D1\uC9C0\uC6B0');

      final item = await repository.createItem(
        'memory-board',
        const BoardItemDraft(
          type: BoardItemType.task,
          title: 'Pack bag',
          detail: '',
        ),
      );
      await repository.addComment(item.id, 'Done');

      final members = await repository.loadMembers('memory-board');
      final items = await repository.loadBoardItems(boardId: 'memory-board');
      final comments = await repository.loadComments(
        item.id,
        boardId: 'memory-board',
      );

      expect(members.first.effectiveName, '\uC9D1\uC9C0\uC6B0');
      expect(items.single.owner, '\uC9D1\uC9C0\uC6B0');
      expect(comments.single.authorName, '\uC9D1\uC9C0\uC6B0');
    });

    test('empty nickname clears the board override', () async {
      final repository = MemoryBoardRepository([]);
      await repository.setBoardNickname('memory-board', '\uC9D1\uC9C0\uC6B0');
      await repository.setBoardNickname('memory-board', '   ');

      final members = await repository.loadMembers('memory-board');

      expect(members.first.effectiveName, '\uC9C0\uC6B0');
      expect(members.first.nickname, isNull);
    });

    test('nickname is scoped to one board', () async {
      final repository = MemoryBoardRepository([]);
      final second = await repository.createBoard('Second', 4);
      await repository.setBoardNickname(second.id, '\uB2E4\uB978\uC9C0\uC6B0');

      final defaultMembers = await repository.loadMembers('memory-board');
      final secondMembers = await repository.loadMembers(second.id);

      expect(defaultMembers.first.effectiveName, '\uC9C0\uC6B0');
      expect(secondMembers.first.effectiveName, '\uB2E4\uB978\uC9C0\uC6B0');
    });

    test('members are scoped to each board', () async {
      final repository = MemoryBoardRepository([]);
      final second = await repository.createBoard('Second', 4);

      await repository.removeMember(second.id, 'memory-user-1');

      final defaultMembers = await repository.loadMembers('memory-board');
      final secondMembers = await repository.loadMembers(second.id);
      final boards = await repository.loadBoards();

      expect(defaultMembers.map((member) => member.userId), [
        'memory-user-1',
        'memory-user-2',
      ]);
      expect(secondMembers, isEmpty);
      expect(
        boards.firstWhere((board) => board.id == second.id).memberCount,
        0,
      );
      expect(
        boards.firstWhere((board) => board.id == 'memory-board').memberCount,
        2,
      );
    });
  });
}

BoardItem _item({required String id}) {
  return BoardItem(
    id: id,
    type: BoardItemType.notice,
    title: 'Notice',
    detail: '',
    owner: 'Us',
    timeLabel: 'Read',
  );
}
