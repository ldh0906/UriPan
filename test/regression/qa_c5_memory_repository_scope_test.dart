// QA-C5: Memory repository fallback must keep board items, members, and invites scoped per board.
import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';

void main() {
  test('QA-C5 keeps MemoryBoardRepository data isolated per board', () async {
    final repository = MemoryBoardRepository([]);
    final secondBoard = await repository.createBoard('Second', 4);
    final firstInvite = await repository.createInvite('memory-board');
    final secondInvite = await repository.createInvite(secondBoard.id);
    final firstItem = await repository.createItem(
      'memory-board',
      const BoardItemDraft(
        type: BoardItemType.notice,
        title: 'First notice',
        detail: '',
      ),
    );
    final secondItem = await repository.createItem(
      secondBoard.id,
      const BoardItemDraft(
        type: BoardItemType.notice,
        title: 'Second notice',
        detail: '',
      ),
    );

    await repository.leaveBoard(secondBoard.id);

    expect(await repository.loadBoardItems(boardId: 'memory-board'), [
      firstItem,
    ]);
    expect(await repository.loadBoardItems(boardId: secondBoard.id), isEmpty);
    expect(await repository.loadMembers('memory-board'), isNotEmpty);
    expect(await repository.loadMembers(secondBoard.id), isEmpty);
    expect(await repository.loadActiveInvite('memory-board'), firstInvite);
    expect(await repository.loadActiveInvite(secondBoard.id), isNull);
    expect(firstInvite.id, isNot(secondInvite.id));
    expect(secondItem.id, isNot(firstItem.id));
  });
}
