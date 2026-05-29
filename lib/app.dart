import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/seed_data.dart';
import 'screens/auth_gate.dart';
import 'screens/today_board_screen.dart';
import 'services/app_config.dart';
import 'services/board_repository.dart';
import 'theme/app_theme.dart';

class UriPanApp extends StatelessWidget {
  const UriPanApp({super.key, this.repository, this.supabaseClient});

  final BoardRepository? repository;
  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    final client =
        supabaseClient ?? (hasSupabaseConfig ? Supabase.instance.client : null);
    final boardRepository =
        repository ??
        (client == null
            ? MemoryBoardRepository(seedBoardItems)
            : SupabaseBoardRepository(client));

    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: client == null
          ? TodayBoardScreen(repository: boardRepository)
          : AuthGate(client: client, repository: boardRepository),
    );
  }
}
