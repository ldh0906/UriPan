import '../models/board_item.dart';

abstract class BoardRepository {
  Future<List<BoardItem>> loadTodayItems();
}

class MemoryBoardRepository implements BoardRepository {
  const MemoryBoardRepository(this._items);

  final List<BoardItem> _items;

  @override
  Future<List<BoardItem>> loadTodayItems() async {
    return List.unmodifiable(_items);
  }
}
