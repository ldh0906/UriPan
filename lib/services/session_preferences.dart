import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user wants to stay signed in across app restarts.
///
/// Supabase keeps the auth session by default, so when this is `false` the app
/// clears the persisted session on each cold start (see `main.dart`), forcing a
/// fresh login. Default is `true` (stay signed in).
class SessionPreferences {
  SessionPreferences({this._preferences});

  static const _keepSignedInKey = 'session.keepSignedIn';

  final SharedPreferences? _preferences;

  Future<bool> loadKeepSignedIn() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    return preferences.getBool(_keepSignedInKey) ?? true;
  }

  Future<void> saveKeepSignedIn(bool keepSignedIn) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setBool(_keepSignedInKey, keepSignedIn);
  }
}
