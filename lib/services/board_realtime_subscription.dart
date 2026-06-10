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
    required void Function() onBoardChanged,
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
        // item_confirmations / item_comments carry a denormalized board_id
        // (replica identity full), so the server only delivers events for this
        // board. The payload check below is defense in depth for older rows.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_confirmations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: board.id,
          ),
          callback: (payload) {
            if (shouldRefreshItemsForItemChildChange(
              eventType: payload.eventType,
              newRecord: payload.newRecord,
              boardId: board.id,
            )) {
              onItemsChanged();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'item_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'board_id',
            value: board.id,
          ),
          callback: (payload) {
            if (shouldRefreshItemsForItemChildChange(
              eventType: payload.eventType,
              newRecord: payload.newRecord,
              boardId: board.id,
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
        // Board metadata (name, max_members) edited by another admin.
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'boards',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: board.id,
          ),
          callback: (_) => onBoardChanged(),
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
  required String boardId,
}) {
  if (eventType == PostgresChangeEvent.delete) return true;

  final recordBoardId = newRecord['board_id'];
  return recordBoardId is String && recordBoardId == boardId;
}
