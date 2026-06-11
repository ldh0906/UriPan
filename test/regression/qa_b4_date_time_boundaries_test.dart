// QA-B4 / 2026-06-08 P1: UTC and month-end boundaries must not shift visible dates.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/screens/today_board_screen.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/friendly_date.dart';

void main() {
  group('QA-B4 date/time regression pack', () {
    test(
      'stores schedule boundaries as UTC strings before Supabase round-trip',
      () async {
      final httpClient = _RecordingBoardItemClient();
      final repository = SupabaseBoardRepository(
        await _signedInClient(httpClient),
      );
      final startsAt = DateTime(2026, 1, 31, 23, 50);
      final dueAt = DateTime(2026, 2, 1, 0, 10);

      await repository.createItem(
        'board-1',
        BoardItemDraft(
          type: BoardItemType.schedule,
          title: 'Late schedule',
          detail: '',
          startsAt: startsAt,
          dueAt: dueAt,
        ),
      );

        expect(
          httpClient.payloads.single['starts_at'],
          startsAt.toUtc().toIso8601String(),
        );
        expect(
          httpClient.payloads.single['due_at'],
          dueAt.toUtc().toIso8601String(),
        );
      },
    );

    test('keeps month navigation on the target month at month end', () {
      expect(
        moveCalendarMonth(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        moveCalendarMonth(DateTime(2024, 3, 31), -1),
        DateTime(2024, 2, 29),
      );
    });

    test('normalizes UTC instants before finding Sunday calendar week start', () {
      final local = DateTime.utc(2026, 6, 6, 15, 30).toLocal();
      final expected = DateTime(local.year, local.month, local.day)
          .subtract(Duration(days: local.weekday % 7));

      expect(startOfCalendarWeek(DateTime.utc(2026, 6, 6, 15, 30)), expected);
    });

    test('labels small future clock skew without a negative relative time', () {
      final now = DateTime(2026, 6, 2, 15, 30);

      expect(
        friendlyRelativeTime(now.add(const Duration(seconds: 45)), now: now),
        '방금',
      );
    });
  });
}

Future<SupabaseClient> _signedInClient(http.Client httpClient) async {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'test-anon-key',
    httpClient: httpClient,
  );
  client.auth.stopAutoRefresh();
  await client.auth.recoverSession(_sessionJson());
  return client;
}

String _sessionJson() {
  final expiresAt = DateTime.now().add(const Duration(hours: 1));
  return jsonEncode({
    'access_token': _jwt(expiresAt),
    'expires_in': expiresAt.difference(DateTime.now()).inSeconds,
    'expiresAt': expiresAt.millisecondsSinceEpoch ~/ 1000,
    'refresh_token': 'refresh-token',
    'token_type': 'bearer',
    'user': {
      'id': 'user-1',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'user@example.com',
      'app_metadata': {'provider': 'email'},
      'user_metadata': {},
      'created_at': '2026-06-08T00:00:00.000Z',
      'updated_at': '2026-06-08T00:00:00.000Z',
    },
  });
}

String _jwt(DateTime expiresAt) {
  String encode(Map<String, Object?> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return [
    encode({'alg': 'HS256', 'typ': 'JWT'}),
    encode({
      'aud': 'authenticated',
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
      'sub': 'user-1',
      'email': 'user@example.com',
      'role': 'authenticated',
    }),
    'signature',
  ].join('.');
}

class _RecordingBoardItemClient extends http.BaseClient {
  final payloads = <Map<String, dynamic>>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request
        ? request.body
        : utf8.decode(await request.finalize().toBytes());

    if (request.url.path.endsWith('/rest/v1/board_items') &&
        request.method == 'POST') {
      final payload = Map<String, dynamic>.from(jsonDecode(body) as Map);
      payloads.add(payload);
      return _jsonResponse(
        {
          'id': 'item-1',
          'board_id': 'board-1',
          'type': 'schedule',
          'title': payload['title'],
          'detail': payload['detail'],
          'starts_at': payload['starts_at'],
          'due_at': payload['due_at'],
          'is_done': false,
          'is_pinned': false,
          'requires_confirmation': false,
          'tags': <String>[],
          'created_by': 'user-1',
          'assigned_to': null,
          'item_confirmations': <Map<String, dynamic>>[],
          'item_comments': [
            {'count': 0},
          ],
        },
        request,
      );
    }

    if (request.url.path.endsWith('/rest/v1/profiles')) {
      return _jsonResponse([], request);
    }

    return _jsonResponse([], request);
  }

  http.StreamedResponse _jsonResponse(Object body, http.BaseRequest request) {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(jsonEncode(body))),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}
