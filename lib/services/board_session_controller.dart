import 'package:flutter/foundation.dart';

import '../models/board_item.dart';
import 'board_repository.dart';

class BoardSessionController extends ChangeNotifier {
  BoardSessionController(this._repository);

  final BoardRepository _repository;

  List<BoardSummary> _boards = const [];
  List<BoardItem> _items = const [];
  List<BoardMember> _members = const [];
  BoardInvite? _activeInvite;
  UserProfile? _myProfile;
  BoardSummary? _activeBoard;
  bool _isLoading = false;
  String? _errorMessage;
  int _stateRequestId = 0;

  List<BoardSummary> get boards => _boards;
  List<BoardItem> get items => _items;
  List<BoardMember> get members => _members;
  BoardInvite? get activeInvite => _activeInvite;
  UserProfile? get myProfile => _myProfile;
  BoardSummary? get activeBoard => _activeBoard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasNoBoard => !_isLoading && _activeBoard == null;

  Future<void> load({String? preferredBoardId}) async {
    final requestId = _nextStateRequest();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedBoards = await _repository.loadBoards();
      final loadedProfile = await _repository.loadMyProfile();
      final activeBoard = _selectBoard(loadedBoards, preferredBoardId);
      final loadedItems = activeBoard == null
          ? const <BoardItem>[]
          : await _repository.loadBoardItems(boardId: activeBoard.id);
      final loadedMembers = activeBoard == null
          ? const <BoardMember>[]
          : await _repository.loadMembers(activeBoard.id);
      final loadedInvite = activeBoard?.isAdmin == true
          ? await _repository.loadActiveInvite(activeBoard!.id)
          : null;
      if (!_isCurrentStateRequest(requestId)) return;

      _boards = loadedBoards;
      _activeBoard = activeBoard;
      _items = loadedItems;
      _members = loadedMembers;
      _activeInvite = loadedInvite;
      _myProfile = loadedProfile;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshItems() async {
    final board = _activeBoard;
    if (board == null) {
      _items = const [];
      _members = const [];
      _activeInvite = null;
      notifyListeners();
      return;
    }

    final requestId = _nextStateRequest();
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedItems = await _repository.loadBoardItems(boardId: board.id);
      if (!_isCurrentStateRequest(requestId) || _activeBoard?.id != board.id) {
        return;
      }
      _items = loadedItems;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) notifyListeners();
    }
  }

  Future<BoardSummary> createBoard(String name, int maxMembers) async {
    late BoardSummary created;
    await _runAction(() async {
      created = await _repository.createBoard(name, maxMembers);
      await load(preferredBoardId: created.id);
    });
    return created;
  }

  Future<void> updateBoard({String? name, int? maxMembers}) async {
    final board = _requireActiveBoard();
    await _runAction(() async {
      await _repository.updateBoard(
        board.id,
        name: name,
        maxMembers: maxMembers,
      );
      await load(preferredBoardId: board.id);
    });
  }

  Future<BoardInvite> createInvite() async {
    return regenerateInvite();
  }

  Future<BoardInvite> regenerateInvite() async {
    final board = _requireActiveBoard();
    late BoardInvite invite;
    await _runAction(() async {
      invite = await _repository.createInvite(board.id);
      _activeInvite = invite;
    });
    return invite;
  }

  Future<void> revokeInvite() async {
    final invite = _activeInvite;
    if (invite == null) return;

    await _runAction(() async {
      await _repository.revokeInvite(invite.id);
      _activeInvite = null;
    });
  }

  Future<BoardSummary> joinBoardWithInvite(String code) async {
    late BoardSummary joined;
    await _runAction(() async {
      joined = await _repository.joinBoardWithInvite(code);
      await load(preferredBoardId: joined.id);
    });
    return joined;
  }

  Future<void> switchBoard(String boardId) async {
    if (boardId == _activeBoard?.id) return;

    await load(preferredBoardId: boardId);
  }

  Future<void> leaveBoard() async {
    final board = _requireActiveBoard();
    await _runAction(() async {
      await _repository.leaveBoard(board.id);
      await load();
    });
  }

  Future<void> updateMyProfile({
    String? displayName,
    String? avatarColor,
  }) async {
    await _runAction(() async {
      _myProfile = await _repository.updateMyProfile(
        displayName: displayName,
        avatarColor: avatarColor,
      );
    });
  }

  Future<void> createItem(BoardItemDraft draft) async {
    final board = _requireActiveBoard();
    final requestId = _nextStateRequest();
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createItem(board.id, draft);
      final loadedItems = await _repository.loadBoardItems(boardId: board.id);
      if (!_isCurrentStateRequest(requestId) || _activeBoard?.id != board.id) {
        return;
      }
      _items = loadedItems;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) notifyListeners();
    }
  }

  Future<void> updateItem(String itemId, BoardItemDraft draft) async {
    final board = _requireActiveBoard();
    final requestId = _nextStateRequest();
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateItem(itemId, draft);
      final loadedItems = await _repository.loadBoardItems(boardId: board.id);
      if (!_isCurrentStateRequest(requestId) || _activeBoard?.id != board.id) {
        return;
      }
      _items = loadedItems;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) notifyListeners();
    }
  }

  Future<void> completeTask(String itemId, bool isDone) async {
    final board = _requireActiveBoard();
    final requestId = _nextStateRequest();
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.completeTask(itemId, isDone);
      final loadedItems = await _repository.loadBoardItems(boardId: board.id);
      if (!_isCurrentStateRequest(requestId) || _activeBoard?.id != board.id) {
        return;
      }
      _items = loadedItems;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) notifyListeners();
    }
  }

  Future<void> confirmNotice(String itemId, bool confirmed) async {
    final board = _requireActiveBoard();
    final requestId = _nextStateRequest();
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.confirmNotice(itemId, confirmed);
      final loadedItems = await _repository.loadBoardItems(boardId: board.id);
      if (!_isCurrentStateRequest(requestId) || _activeBoard?.id != board.id) {
        return;
      }
      _items = loadedItems;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) notifyListeners();
    }
  }

  Future<void> deleteItem(String itemId) async {
    final board = _requireActiveBoard();
    final requestId = _nextStateRequest();
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteItem(itemId);
      final loadedItems = await _repository.loadBoardItems(boardId: board.id);
      if (!_isCurrentStateRequest(requestId) || _activeBoard?.id != board.id) {
        return;
      }
      _items = loadedItems;
    } catch (error) {
      if (!_isCurrentStateRequest(requestId)) return;
      _errorMessage = error.toString();
      rethrow;
    } finally {
      if (_isCurrentStateRequest(requestId)) notifyListeners();
    }
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

  int _nextStateRequest() => ++_stateRequestId;

  bool _isCurrentStateRequest(int requestId) => requestId == _stateRequestId;

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
