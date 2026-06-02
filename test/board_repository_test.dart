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
