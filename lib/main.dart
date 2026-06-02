import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/app_config.dart';
import 'services/session_preferences.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (hasSupabaseConfig) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabasePublishableKey,
    );

    // Respect "stay signed in": when the user opted out, drop the persisted
    // session on cold start so they have to log in again.
    final keepSignedIn = await SessionPreferences().loadKeepSignedIn();
    if (!keepSignedIn && Supabase.instance.client.auth.currentSession != null) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
  }

  runApp(const UriPanApp());
}
