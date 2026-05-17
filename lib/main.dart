import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'models/mock_models.dart';
import 'screens/add_item_selector_screen.dart';
import 'screens/calendar_view_screen.dart';
import 'screens/group_selection_screen.dart';
import 'screens/item_detail_edit_screen.dart';
import 'screens/login_screen.dart';
import 'screens/members_invite_screen.dart';
import 'screens/notices_board_screen.dart';
import 'screens/tasks_list_screen.dart';
import 'screens/today_board_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const UriPanApp());
}

class UriPanApp extends StatefulWidget {
  const UriPanApp({super.key});

  @override
  State<UriPanApp> createState() => _UriPanAppState();
}

class _UriPanAppState extends State<UriPanApp> {
  late final List<FamilyMember> members = MockData.members;
  late final List<ScheduleItemData> schedules = MockData.schedules;
  late final List<TaskItemData> tasks = MockData.tasks;
  late final List<NoticeItemData> notices = MockData.notices;

  void toggleTask(TaskItemData task, bool? value) {
    setState(() {
      final index = tasks.indexWhere((item) => item.id == task.id);
      if (index >= 0) {
        tasks[index] = tasks[index].copyWith(isDone: value ?? false);
      }
    });
  }

  void toggleNoticeConfirmation(NoticeItemData notice) {
    setState(() {
      final index = notices.indexWhere((item) => item.id == notice.id);
      if (index >= 0) {
        final current = notices[index];
        final nextConfirmed = !current.confirmedByMe;
        final nextCount = nextConfirmed
            ? current.confirmedCount + 1
            : (current.confirmedCount - 1).clamp(0, members.length);
        notices[index] = current.copyWith(
          confirmedByMe: nextConfirmed,
          confirmedCount: nextCount,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UriPan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: WelcomeScreen.routeName,
      routes: {
        WelcomeScreen.routeName: (_) => const WelcomeScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        GroupSelectionScreen.routeName: (_) => const GroupSelectionScreen(),
        TodayBoardScreen.routeName: (_) => TodayBoardScreen(
              members: members,
              schedules: schedules,
              tasks: tasks,
              notices: notices,
              onTaskChanged: toggleTask,
              onNoticeConfirmed: toggleNoticeConfirmation,
            ),
        CalendarViewScreen.routeName: (_) => CalendarViewScreen(
              members: members,
              schedules: schedules,
            ),
        TasksListScreen.routeName: (_) => TasksListScreen(
              tasks: tasks,
              onTaskChanged: toggleTask,
            ),
        NoticesBoardScreen.routeName: (_) => NoticesBoardScreen(
              notices: notices,
              members: members,
              onNoticeConfirmed: toggleNoticeConfirmation,
            ),
        MembersInviteScreen.routeName: (_) => MembersInviteScreen(
              members: members,
            ),
        AddItemSelectorScreen.routeName: (_) => const AddItemSelectorScreen(),
        ItemDetailEditScreen.routeName: (_) => ItemDetailEditScreen(
              members: members,
            ),
      },
    );
  }
}
