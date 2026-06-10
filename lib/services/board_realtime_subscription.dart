import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/board_item.dart';

class BoardRealtimeSubscription {
  BoardRealtimeSubscription(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _channel;
  String? _subscribedBoardId;

  void sync({
    required BoardSummary? board,
    required void Function() onItemsChanged,
    required void Function() onMembershipChanged,
    required bool Function(String itemId) isCurrentBoardItem,
  }) {
    if (board == null) {
      clear();
      return;
    }

    if (_subscribedBoardId == board.id) return;

    clear();

    _subscribedBoardId = board.id;
    _channel = _client
        .channel('board:${board.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: board.id,
          ),
          callback: (_) => onItemsChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_confirmations',
          callback: (payload) {
            if (shouldRefreshItemsForItemChildChange(
              eventType: payload.eventType,
              newRecord: payload.newRecord,
              isCurrentBoardItem: isCurrentBoardItem,
            )) {
              onItemsChanged();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_comments',
          callback: (payload) {
            if (shouldRefreshItemsForItemChildChange(
              eventType: payload.eventType,
              newRecord: payload.newRecord,
              isCurrentBoardItem: isCurrentBoardItem,
            )) {
              onItemsChanged();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'board_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: board.id,
          ),
          callback: (_) => onMembershipChanged(),
        )
        .subscribe();
  }

  void clear() {
    final channel = _channel;
    if (channel != null) {
      _client.removeChannel(channel);
    }
    _channel = null;
    _subscribedBoardId = null;
  }
}

bool shouldRefreshItemsForItemChildChange({
  required PostgresChangeEvent eventType,
  required Map<String, dynamic> newRecord,
  required bool Function(String itemId) isCurrentBoardItem,
}) {
  if (eventType == PostgresChangeEvent.delete) return true;

  final itemId = newRecord['item_id'];
  return itemId is String && isCurrentBoardItem(itemId);
}
