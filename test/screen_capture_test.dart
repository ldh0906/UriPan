import 'package:flutter/material.dart';
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
  const shouldCapture =
      bool.fromEnvironment('URIPAN_CAPTURE_SCREENS', defaultValue: false);

  Future<void> capture(
    WidgetTester tester,
    String name,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('screen_captures/$name.png'),
    );
  }

  testWidgets('capture 01 welcome', (tester) async {
    await capture(tester, '01_welcome', const WelcomeScreen());
  }, skip: !shouldCapture);

  testWidgets('capture 02 login', (tester) async {
    await capture(tester, '02_login', const LoginScreen());
  }, skip: !shouldCapture);

  testWidgets('capture 03 boards', (tester) async {
    await capture(
      tester,
      '03_boards',
      GroupSelectionScreen(
        boards: MockData.boards,
        onCreateBoard: (_) {},
        onJoinBoard: (_) {},
        onSelectBoard: (_) {},
      ),
    );
  }, skip: !shouldCapture);

  testWidgets('capture 04 today', (tester) async {
    final tasks = MockData.tasks.toList();
    final notices = MockData.notices.toList();
    await capture(
      tester,
      '04_today',
      TodayBoardScreen(
        boardName: MockData.boards.first.name,
        members: MockData.members,
        schedules: MockData.schedules,
        tasks: tasks,
        notices: notices,
        onTaskChanged: (_, __) {},
        onNoticeConfirmed: (_) {},
      ),
    );
  }, skip: !shouldCapture);

  testWidgets('capture 05 calendar', (tester) async {
    await capture(
      tester,
      '05_calendar',
      CalendarViewScreen(
        boardName: MockData.boards.first.name,
        members: MockData.members,
        schedules: MockData.schedules,
        onScheduleDeleted: (_) {},
      ),
    );
  }, skip: !shouldCapture);

  testWidgets('capture 06 tasks', (tester) async {
    final tasks = MockData.tasks.toList();
    await capture(
      tester,
      '06_tasks',
      TasksListScreen(
        boardName: MockData.boards.first.name,
        tasks: tasks,
        onTaskChanged: (_, __) {},
        onTaskDeleted: (_) {},
      ),
    );
  }, skip: !shouldCapture);

  testWidgets('capture 07 notices', (tester) async {
    final notices = MockData.notices.toList();
    await capture(
      tester,
      '07_notices',
      NoticesBoardScreen(
        boardName: MockData.boards.first.name,
        notices: notices,
        members: MockData.members,
        onNoticeConfirmed: (_) {},
        onNoticeDeleted: (_) {},
      ),
    );
  }, skip: !shouldCapture);

  testWidgets('capture 08 members', (tester) async {
    await capture(
      tester,
      '08_members',
      MembersInviteScreen(
        boardName: MockData.boards.first.name,
        members: MockData.members,
        onMemberRoleChanged: (_, __) {},
        onMemberRemoved: (_) {},
        onLeaveBoard: () {},
      ),
    );
  }, skip: !shouldCapture);

  testWidgets('capture 09 add item', (tester) async {
    await capture(tester, '09_add_item', const AddItemSelectorScreen());
  }, skip: !shouldCapture);

  testWidgets('capture 10 item edit', (tester) async {
    await capture(
      tester,
      '10_item_edit',
      ItemDetailEditScreen(
        members: MockData.members,
        onSave: (_) {},
      ),
    );
  }, skip: !shouldCapture);
}
