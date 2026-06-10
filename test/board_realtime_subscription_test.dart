import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/services/board_realtime_subscription.dart';

void main() {
  group('shouldRefreshItemsForItemChildChange', () {
    test('refreshes inserts and updates only for current board items', () {
      final currentItemIds = {'item-1'};

      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.insert,
          newRecord: {'item_id': 'item-1'},
          isCurrentBoardItem: currentItemIds.contains,
        ),
        isTrue,
      );
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.update,
          newRecord: {'item_id': 'item-2'},
          isCurrentBoardItem: currentItemIds.contains,
        ),
        isFalse,
      );
    });

    test('skips insert and update payloads without item id', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.insert,
          newRecord: {'id': 'confirmation-1'},
          isCurrentBoardItem: (_) => true,
        ),
        isFalse,
      );
    });

    test('refreshes deletes because old payload may omit item id', () {
      expect(
        shouldRefreshItemsForItemChildChange(
          eventType: PostgresChangeEvent.delete,
          newRecord: const {},
          isCurrentBoardItem: (_) => false,
        ),
        isTrue,
      );
    });
  });
}
