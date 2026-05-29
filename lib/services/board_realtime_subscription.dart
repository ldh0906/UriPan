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
          callback: (_) => onItemsChanged(),
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
