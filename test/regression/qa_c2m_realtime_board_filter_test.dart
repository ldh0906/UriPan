// QA-C2m: Child realtime events from another board must not refresh the current board.
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/services/board_realtime_subscription.dart';

void main() {
  group('QA-C2m shouldRefreshItemsForItemChildChange', () {
    test('ignores insert/update payloads for another board or without board_id', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.insert,
          newRecord: {'item_id': 'item-1', 'board_id': 'other-board'},
          boardId: 'current-board',
        ),
        isFalse,
      );
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.update,
          newRecord: {'item_id': 'item-1'},
          boardId: 'current-board',
        ),
        isFalse,
      );
    });

    test('refreshes matching board payloads and delete events', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.update,
          newRecord: {'item_id': 'item-1', 'board_id': 'current-board'},
          boardId: 'current-board',
        ),
        isTrue,
      );
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.delete,
          newRecord: const {},
          boardId: 'current-board',
        ),
        isTrue,
      );
    });
  });
}
