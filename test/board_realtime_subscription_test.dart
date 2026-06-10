import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/services/board_realtime_subscription.dart';

void main() {
  group('shouldRefreshItemsForItemChildChange', () {
    test('refreshes inserts and updates only for the current board', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.insert,
          newRecord: {'item_id': 'item-1', 'board_id': 'board-1'},
          boardId: 'board-1',
        ),
        isTrue,
      );
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.update,
          newRecord: {'item_id': 'item-2', 'board_id': 'board-2'},
          boardId: 'board-1',
        ),
        isFalse,
      );
    });

    test('skips insert and update payloads without board id', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.insert,
          newRecord: {'id': 'confirmation-1'},
          boardId: 'board-1',
        ),
        isFalse,
      );
    });

    test('refreshes deletes because old payload may omit board id', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.delete,
          newRecord: const {},
          boardId: 'board-1',
        ),
        isTrue,
      );
    });
  });
}
