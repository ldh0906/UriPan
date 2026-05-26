import 'package:flutter/material.dart';

import 'data/seed_data.dart';
import 'screens/today_board_screen.dart';
import 'services/board_repository.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UriPanApp());
}

class UriPanApp extends StatelessWidget {
  const UriPanApp({super.key, this.repository});

  final BoardRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: TodayBoardScreen(
        repository: repository ?? MemoryBoardRepository(seedBoardItems),
      ),
    );
  }
}
