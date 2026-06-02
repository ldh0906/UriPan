import 'package:shared_preferences/shared_preferences.dart';

class ReminderPreferences {
  ReminderPreferences({this._preferences});

  static const _enabledKey = 'reminders.enabled';

  final SharedPreferences? _preferences;

  Future<bool> loadEnabled() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? true;
  }

  Future<void> saveEnabled(bool enabled) async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }
}
