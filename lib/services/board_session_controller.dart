import 'package:flutter/foundation.dart';

import '../models/board_item.dart';
import 'board_repository.dart';

class BoardSessionController extends ChangeNotifier {
  BoardSessionController(this._repository);

  final BoardRepository _repository;

  List<BoardSummary> _boards = const [];
  List<BoardItem> _items = const [];
  BoardSummary? _activeBoard;
  bool _isLoading = false;
  String? _errorMessage;

  List<BoardSummary> get boards => _boards;
  List<BoardItem> get items => _items;
  BoardSummary? get activeBoard => _activeBoard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNoBoard => !_isLoading && _activeBoard == null;

  Future<void> load({String? preferredBoardId}) async {
    await _runLoadingAction(() async {
      final loadedBoards = await _repository.loadBoards();
      _boards = loadedBoards;
      _activeBoard = _selectBoard(loadedBoards, preferredBoardId);
      _items = _activeBoard == null
          ? const []
          : await _repository.loadTodayItems(boardId: _activeBoard!.id);
    });
  }

  Future<void> refreshItems() async {
    final board = _activeBoard;
    if (board == null) {
      _items = const [];
      notifyListeners();
      return;
    }

    await _runAction(() async {
      _items = await _repository.loadTodayItems(boardId: board.id);
    });
  }

  Future<BoardSummary> createBoard(String name, int maxMembers) async {
    late BoardSummary created;
    await _runAction(() async {
      created = await _repository.createBoard(name, maxMembers);
      await load(preferredBoardId: created.id);
    });
    return created;
  }

  Future<BoardInvite> createInvite() async {
    final board = _requireActiveBoard();
    late BoardInvite invite;
    await _runAction(() async {
      invite = await _repository.createInvite(board.id);
    });
    return invite;
  }

  Future<BoardSummary> joinBoardWithInvite(String code) async {
    late BoardSummary joined;
    await _runAction(() async {
      joined = await _repository.joinBoardWithInvite(code);
      await load(preferredBoardId: joined.id);
    });
    return joined;
  }

  Future<void> createItem(BoardItemDraft draft) async {
    final board = _requireActiveBoard();
    await _runAction(() async {
      await _repository.createItem(board.id, draft);
      _items = await _repository.loadTodayItems(boardId: board.id);
    });
  }

  Future<void> completeTask(String itemId, bool isDone) async {
    final board = _requireActiveBoard();
    await _runAction(() async {
      await _repository.completeTask(itemId, isDone);
      _items = await _repository.loadTodayItems(boardId: board.id);
    });
  }

  Future<void> handleBoardMembershipChanged() async {
    await load(preferredBoardId: _activeBoard?.id);
  }

  Future<void> handleBoardItemsChanged() async {
    await refreshItems();
  }

  BoardSummary? _selectBoard(
    List<BoardSummary> loadedBoards,
    String? preferredBoardId,
  ) {
    if (loadedBoards.isEmpty) return null;

    final targetBoardId = preferredBoardId ?? _activeBoard?.id;
    for (final board in loadedBoards) {
      if (board.id == targetBoardId) return board;
    }
    return loadedBoards.first;
  }

  BoardSummary _requireActiveBoard() {
    final board = _activeBoard;
    if (board == null) {
      throw StateError('No active board');
    }
    return board;
  }

  Future<void> _runLoadingAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
