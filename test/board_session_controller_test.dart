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

  test(
    'reloads items from the repository after creating and completing items',
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
        ),
      );
      await controller.completeTask('created-1', true);

      expect(controller.items.single.id, 'created-1');
      expect(controller.items.single.isDone, isTrue);
      expect(repository.loadedItemBoardIds, ['board-1', 'board-1', 'board-1']);
    },
  );

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
}

const _adminBoard = BoardSummary(
  id: 'board-1',
  name: 'Home',
  role: 'admin',
  maxMembers: 4,
  memberCount: 1,
);

class _FakeBoardRepository implements BoardRepository {
  _FakeBoardRepository({
    required List<BoardSummary> boards,
    required this.itemsByBoard,
  }) : boards = List.of(boards);

  List<BoardSummary> boards;
  Map<String, List<BoardItem>> itemsByBoard;
  final loadedItemBoardIds = <String?>[];

  @override
  Future<List<BoardSummary>> loadBoards() async => List.unmodifiable(boards);

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
  Future<BoardInvite> createInvite(String boardId) async {
    return BoardInvite(
      id: 'invite-1',
      code: 'URIP-0001',
      expiresAt: DateTime(2026, 6),
    );
  }

  @override
  Future<BoardSummary> joinBoardWithInvite(String code) async => boards.first;

  @override
  Future<List<BoardItem>> loadTodayItems({String? boardId}) async {
    loadedItemBoardIds.add(boardId);
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
      timeLabel: 'Today',
      startsAt: draft.startsAt,
      dueAt: draft.dueAt,
    );
    itemsByBoard[boardId] = [...itemsByBoard[boardId] ?? const [], item];
    return item;
  }

  @override
  Future<BoardItem> completeTask(String itemId, bool isDone) async {
    for (final entry in itemsByBoard.entries) {
      final index = entry.value.indexWhere((item) => item.id == itemId);
      if (index >= 0) {
        final old = entry.value[index];
        final updated = BoardItem(
          id: old.id,
          type: old.type,
          title: old.title,
          detail: old.detail,
          owner: old.owner,
          timeLabel: old.timeLabel,
          startsAt: old.startsAt,
          dueAt: old.dueAt,
          isDone: isDone,
          isPinned: old.isPinned,
        );
        entry.value[index] = updated;
        return updated;
      }
    }
    throw StateError('Item not found');
  }
}
