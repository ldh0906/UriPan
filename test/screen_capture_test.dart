import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/data/mock_data.dart';
import 'package:uripan/screens/add_item_selector_screen.dart';
import 'package:uripan/screens/calendar_view_screen.dart';
import 'package:uripan/screens/group_selection_screen.dart';
import 'package:uripan/screens/item_detail_edit_screen.dart';
import 'package:uripan/screens/login_screen.dart';
import 'package:uripan/screens/members_invite_screen.dart';
import 'package:uripan/screens/notices_board_screen.dart';
import 'package:uripan/screens/tasks_list_screen.dart';
import 'package:uripan/screens/today_board_screen.dart';
import 'package:uripan/screens/welcome_screen.dart';
import 'package:uripan/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture implemented screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final screenshotsDir = Directory('/tmp/uripan_screens');
    if (!screenshotsDir.existsSync()) {
      screenshotsDir.createSync(recursive: true);
    }

    final tasks = MockData.tasks.toList();
    final notices = MockData.notices.toList();

    Future<void> capture(String name, Widget screen) async {
      // ignore: avoid_print
      print('capturing $name');
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: RepaintBoundary(
            key: key,
            child: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${screenshotsDir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      // ignore: avoid_print
      print('captured $name');
    }

    await capture('01_welcome', const WelcomeScreen());
    await capture('02_login', const LoginScreen());
    await capture('03_boards', const GroupSelectionScreen());
    await capture(
      '04_today',
      TodayBoardScreen(
        members: MockData.members,
        schedules: MockData.schedules,
        tasks: tasks,
        notices: notices,
        onTaskChanged: (_, __) {},
        onNoticeConfirmed: (_) {},
      ),
    );
    await capture(
      '05_calendar',
      const CalendarViewScreen(
        members: MockData.members,
        schedules: MockData.schedules,
      ),
    );
    await capture(
      '06_tasks',
      TasksListScreen(
        tasks: tasks,
        onTaskChanged: (_, __) {},
      ),
    );
    await capture(
      '07_notices',
      NoticesBoardScreen(
        notices: notices,
        members: MockData.members,
        onNoticeConfirmed: (_) {},
      ),
    );
    await capture(
      '08_members',
      const MembersInviteScreen(members: MockData.members),
    );
    await capture('09_add_item', const AddItemSelectorScreen());
    await capture(
      '10_item_edit',
      const ItemDetailEditScreen(members: MockData.members),
    );
  });
}
