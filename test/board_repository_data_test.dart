// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/services/board_repository.dart';

void main() {
  group('MemoryBoardRepository board isolation', () {
    test('loadBoardItems filters by boardId', () async {
      final repository = MemoryBoardRepository([]);
      final otherBoard = await repository.createBoard('다른 보드', 4);
      final homeItem = await repository.createItem(
        'memory-board',
        const BoardItemDraft(
          type: BoardItemType.notice,
          title: '집 공지',
          detail: '',
        ),
      );
      final otherItem = await repository.createItem(
        otherBoard.id,
        const BoardItemDraft(
          type: BoardItemType.notice,
          title: '다른 공지',
          detail: '',
        ),
      );

      expect(await repository.loadBoardItems(boardId: 'memory-board'), [
        homeItem,
      ]);
      expect(await repository.loadBoardItems(boardId: otherBoard.id), [
        otherItem,
      ]);
    });

    test('leaveBoard keeps other board members', () async {
      final repository = MemoryBoardRepository([]);
      final otherBoard = await repository.createBoard('다른 보드', 4);

      await repository.leaveBoard(otherBoard.id);

      expect(await repository.loadMembers('memory-board'), isNotEmpty);
    });

    test('active invite is scoped by board', () async {
      final repository = MemoryBoardRepository([]);
      final homeInvite = await repository.createInvite('memory-board');
      final otherBoard = await repository.createBoard('다른 보드', 4);
      final otherInvite = await repository.createInvite(otherBoard.id);

      expect(await repository.loadActiveInvite('memory-board'), homeInvite);
      expect(await repository.loadActiveInvite(otherBoard.id), otherInvite);
    });
  });

  group('SupabaseBoardRepository UTC payload', () {
    test('createItem stores local startsAt and dueAt as UTC strings', () async {
      final httpClient = _BoardRepositoryHttpClient();
      final repository = SupabaseBoardRepository(
        await _signedInClient(httpClient),
      );
      final startsAt = DateTime(2026, 6, 8, 9, 30);
      final dueAt = DateTime(2026, 6, 8, 10, 45);

      await repository.createItem(
        'board-1',
        BoardItemDraft(
          type: BoardItemType.schedule,
          title: '일정',
          detail: '',
          startsAt: startsAt,
          dueAt: dueAt,
        ),
      );

      final payload = httpClient.boardItemPayloads.single;
      expect(payload['starts_at'], startsAt.toUtc().toIso8601String());
      expect(payload['due_at'], dueAt.toUtc().toIso8601String());
    });

    test('updateItem stores local startsAt and dueAt as UTC strings', () async {
      final httpClient = _BoardRepositoryHttpClient();
      final repository = SupabaseBoardRepository(
        await _signedInClient(httpClient),
      );
      final startsAt = DateTime(2026, 6, 8, 9, 30);
      final dueAt = DateTime(2026, 6, 8, 10, 45);

      await repository.updateItem(
        'item-1',
        BoardItemDraft(
          type: BoardItemType.schedule,
          title: '수정',
          detail: '',
          startsAt: startsAt,
          dueAt: dueAt,
        ),
      );

      final payload = httpClient.boardItemPayloads.single;
      expect(payload['starts_at'], startsAt.toUtc().toIso8601String());
      expect(payload['due_at'], dueAt.toUtc().toIso8601String());
    });
  });

  group('SupabaseBoardRepository empty mutation results', () {
    test('updateMemberRole throws when no row is updated', () async {
      final repository = SupabaseBoardRepository(
        await _signedInClient(_BoardRepositoryHttpClient(emptyMutations: true)),
      );

      expect(
        () => repository.updateMemberRole('board-1', 'user-2', 'admin'),
        throwsStateError,
      );
    });

    test('removeMember throws when no row is deleted', () async {
      final repository = SupabaseBoardRepository(
        await _signedInClient(_BoardRepositoryHttpClient(emptyMutations: true)),
      );

      expect(
        () => repository.removeMember('board-1', 'user-2'),
        throwsStateError,
      );
    });

    test('deleteComment throws when no row is deleted', () async {
      final repository = SupabaseBoardRepository(
        await _signedInClient(_BoardRepositoryHttpClient(emptyMutations: true)),
      );

      expect(() => repository.deleteComment('comment-1'), throwsStateError);
    });

    test('deleteItem throws when no row is deleted', () async {
      final repository = SupabaseBoardRepository(
        await _signedInClient(_BoardRepositoryHttpClient(emptyMutations: true)),
      );

      expect(() => repository.deleteItem('item-1'), throwsStateError);
    });
  });

  group('SupabaseBoardRepository snapshot display names', () {
    test('uses live name before left-member snapshot label', () {
      expect(
        resolveBoardDisplayName(
          userId: 'user-2',
          liveNames: {'user-2': '현재 이름'},
          snapshotName: '이전 이름',
          fallback: '???',
        ),
        '현재 이름',
      );
    });

    test('uses left-member snapshot label when live name is missing', () {
      expect(
        resolveBoardDisplayName(
          userId: 'user-2',
          liveNames: const {},
          snapshotName: '탈퇴자',
          fallback: '???',
        ),
        '탈퇴자 (\uB098\uAC10)',
      );
    });

    test('ignores blank snapshots and keeps existing fallback', () {
      expect(
        resolveBoardDisplayName(
          userId: 'user-2',
          liveNames: const {},
          snapshotName: '  ',
          fallback: 'user-2',
        ),
        'user-2',
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
  final accessToken = _jwt(expiresAt);
  return jsonEncode({
    'access_token': accessToken,
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

class _BoardRepositoryHttpClient extends http.BaseClient {
  _BoardRepositoryHttpClient({this.emptyMutations = false});

  final bool emptyMutations;
  final List<Map<String, dynamic>> boardItemPayloads = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = request is http.Request
        ? request.body
        : utf8.decode(await request.finalize().toBytes());
    final path = request.url.path;

    if (path.endsWith('/rest/v1/board_items')) {
      if (request.method == 'POST' || request.method == 'PATCH') {
        final payload = Map<String, dynamic>.from(jsonDecode(body) as Map);
        boardItemPayloads.add(payload);
        return _jsonResponse(
          _boardItemRow(
            id: request.method == 'POST' ? 'item-new' : 'item-1',
            title: payload['title'] as String,
            detail: payload['detail'] as String?,
            startsAt: payload['starts_at'] as String?,
            dueAt: payload['due_at'] as String?,
          ),
          request,
        );
      }

      if (request.method == 'DELETE') {
        return _jsonResponse(
          emptyMutations ? [] : [_boardItemRow(id: 'item-1')],
          request,
        );
      }
    }

    if (path.endsWith('/rest/v1/board_members')) {
      if (request.method == 'PATCH' || request.method == 'DELETE') {
        return _jsonResponse(
          emptyMutations
              ? []
              : [
                  {'board_id': 'board-1', 'user_id': 'user-2', 'role': 'admin'},
                ],
          request,
        );
      }
      return _jsonResponse([], request);
    }

    if (path.endsWith('/rest/v1/item_comments')) {
      if (request.method == 'DELETE') {
        return _jsonResponse(
          emptyMutations
              ? []
              : [
                  {'id': 'comment-1'},
                ],
          request,
        );
      }
      return _jsonResponse([], request);
    }

    if (path.endsWith('/rest/v1/profiles')) {
      return _jsonResponse([], request);
    }

    return _jsonResponse([], request);
  }

  Map<String, dynamic> _boardItemRow({
    required String id,
    String title = '일정',
    String? detail = '',
    String? startsAt,
    String? dueAt,
  }) {
    return {
      'id': id,
      'board_id': 'board-1',
      'type': 'schedule',
      'title': title,
      'detail': detail,
      'starts_at': startsAt,
      'due_at': dueAt,
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
    };
  }

  http.StreamedResponse _jsonResponse(
    Object body, [
    http.BaseRequest? request,
  ]) {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}
