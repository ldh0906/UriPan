import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';

void main() {
  group('boardItemMatchesQuery', () {
    const item = BoardItem(
      id: 'item-1',
      type: BoardItemType.task,
      title: 'Buy milk',
      detail: 'Use the family card',
      owner: 'Nari',
      assigneeName: 'Dami',
      timeLabel: 'Today',
      tags: ['Errand', 'Kitchen'],
    );

    test('matches title case-insensitively', () {
      expect(boardItemMatchesQuery(item, 'MILK'), isTrue);
    });

    test('matches tags case-insensitively', () {
      expect(boardItemMatchesQuery(item, 'kitchen'), isTrue);
    });

    test('misses when no searchable field contains the query', () {
      expect(boardItemMatchesQuery(item, 'soccer'), isFalse);
    });

    test('empty query matches', () {
      expect(boardItemMatchesQuery(item, '   '), isTrue);
    });
  });
}
