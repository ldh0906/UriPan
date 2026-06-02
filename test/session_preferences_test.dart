import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uripan/services/session_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keep signed in defaults to true', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = SessionPreferences(
      preferences: await SharedPreferences.getInstance(),
    );

    expect(await preferences.loadKeepSignedIn(), isTrue);
  });

  test('saves and reloads keep signed in preference', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = SessionPreferences(
      preferences: await SharedPreferences.getInstance(),
    );

    await preferences.saveKeepSignedIn(false);
    expect(await preferences.loadKeepSignedIn(), isFalse);

    await preferences.saveKeepSignedIn(true);
    expect(await preferences.loadKeepSignedIn(), isTrue);
  });
}
