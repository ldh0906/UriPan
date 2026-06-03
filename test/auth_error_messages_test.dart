import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/services/auth_error_messages.dart';

void main() {
  test('maps invalid credentials to a friendly Korean message', () {
    expect(
      AuthErrorMessages.fromAuthMessage('Invalid login credentials'),
      '아이디 또는 비밀번호를 확인해주세요.',
    );
  });

  // Regression: signing up with an already-registered id used to fall through
  // to the generic error. With email confirmation off, Supabase returns an
  // obfuscated user (empty identities); login_screen surfaces that as
  // 'user_already_registered', and GoTrue itself says 'User already registered'.
  // Found by /qa on 2026-06-03.
  test('maps already-registered signals to the existing-id message', () {
    const expected = '이미 있는 아이디예요. 로그인해주세요.';
    expect(
      AuthErrorMessages.fromAuthMessage('User already registered'),
      expected,
    );
    expect(
      AuthErrorMessages.fromAuthMessage('user_already_registered'),
      expected,
    );
    expect(AuthErrorMessages.fromAuthMessage('User already exists'), expected);
  });

  test('falls back to a generic message for unknown errors', () {
    expect(
      AuthErrorMessages.fromAuthMessage('some unexpected failure'),
      '로그인 처리 중 문제가 생겼어요. 잠시 후 다시 시도해주세요.',
    );
  });
}
