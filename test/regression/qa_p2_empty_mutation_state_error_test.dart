// 2026-06-08 P2: Empty Supabase mutation results must surface as StateError instead of silent success.
// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/services/board_repository.dart';

void main() {
  test('empty update/delete mutation responses throw StateError', () async {
    final repository = SupabaseBoardRepository(
      await _signedInClient(_EmptyMutationClient()),
    );

    await expectLater(
      repository.updateMemberRole('board-1', 'missing-user', 'admin'),
      throwsStateError,
    );
    await expectLater(
      repository.removeMember('board-1', 'missing-user'),
      throwsStateError,
    );
    await expectLater(
      repository.deleteComment('missing-comment'),
      throwsStateError,
    );
    await expectLater(repository.deleteItem('missing-item'), throwsStateError);
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

class _EmptyMutationClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('[]')),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }
}
