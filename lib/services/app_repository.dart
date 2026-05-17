import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';
import 'app_config.dart';

abstract class AppRepository {
  Future<AppSnapshot> load();
  Future<void> save(AppSnapshot snapshot);
  Future<void> clear();
}

class LocalAppRepository implements AppRepository {
  LocalAppRepository({SharedPreferences? preferences})
      : _preferences = preferences;

  static const _storageKey = 'uripan.app.snapshot.v2';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    final existing = _preferences;
    if (existing != null) return existing;
    final loaded = await SharedPreferences.getInstance();
    _preferences = loaded;
    return loaded;
  }

  @override
  Future<AppSnapshot> load() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return MockData.initialSnapshot;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppSnapshot.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppSnapshot.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      await prefs.remove(_storageKey);
    }

    return MockData.initialSnapshot;
  }

  @override
  Future<void> save(AppSnapshot snapshot) async {
    final prefs = await _prefs;
    await prefs.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_storageKey);
  }
}

class MemoryAppRepository implements AppRepository {
  MemoryAppRepository([AppSnapshot? initial])
      : _snapshot = initial ?? MockData.initialSnapshot;

  AppSnapshot _snapshot;

  @override
  Future<AppSnapshot> load() async => _snapshot;

  @override
  Future<void> save(AppSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    _snapshot = MockData.initialSnapshot;
  }
}

class RemoteUriPanApi {
  const RemoteUriPanApi(this.config);

  final AppConfig config;

  Future<AppSnapshot> fetchSnapshot(String sessionToken) {
    return Future.error(
      UnimplementedError(
        'Remote UriPan API is intentionally not connected. '
        'Configure AppConfig and implement this adapter when the server is ready.',
      ),
    );
  }

  Future<void> syncSnapshot(AppSnapshot snapshot) {
    return Future.error(
      UnimplementedError('Remote UriPan API is intentionally not connected.'),
    );
  }
}
