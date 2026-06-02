import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/seed_data.dart';
import 'screens/auth_gate.dart';
import 'screens/today_board_screen.dart';
import 'services/app_config.dart';
import 'services/board_repository.dart';
import 'services/notifications/local_notification_scheduler.dart';
import 'services/notifications/reminder_scheduler.dart';
import 'theme/app_theme.dart';

class UriPanApp extends StatelessWidget {
  const UriPanApp({
    super.key,
    this.repository,
    this.supabaseClient,
    this.scheduler,
  });

  final BoardRepository? repository;
  final SupabaseClient? supabaseClient;
  final ReminderScheduler? scheduler;

  @override
  Widget build(BuildContext context) {
    final client =
        supabaseClient ?? (hasSupabaseConfig ? Supabase.instance.client : null);
    final boardRepository =
        repository ??
        (client == null
            ? MemoryBoardRepository(seedBoardItems)
            : SupabaseBoardRepository(client));
    final reminderScheduler =
        scheduler ??
        (client == null
            ? const NoopReminderScheduler()
            : LocalNotificationScheduler());

    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: client == null
          ? TodayBoardScreen(repository: boardRepository)
          : AuthGate(
              client: client,
              repository: boardRepository,
              scheduler: reminderScheduler,
            ),
    );
  }
}
