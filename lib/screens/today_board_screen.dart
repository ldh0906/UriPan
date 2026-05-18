import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/calendar_view_screen.dart';
import '../screens/group_selection_screen.dart';
import '../screens/item_detail_edit_screen.dart';
import '../screens/notices_board_screen.dart';
import '../screens/tasks_list_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TodayBoardScreen extends StatelessWidget {
  const TodayBoardScreen({
    super.key,
    required this.boardName,
    required this.members,
    required this.schedules,
    required this.tasks,
    required this.notices,
    required this.onTaskChanged,
    required this.onNoticeConfirmed,
  });

  static const routeName = '/today';

  final String boardName;
  final List<FamilyMember> members;
  final List<ScheduleItemData> schedules;
  final List<TaskItemData> tasks;
  final List<NoticeItemData> notices;
  final void Function(TaskItemData task, bool? value) onTaskChanged;
  final void Function(NoticeItemData notice) onNoticeConfirmed;

  @override
  Widget build(BuildContext context) {
    final remainingTasks = tasks.where((task) => !task.isDone).length;
    final today = DateTime.now();

    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 0),
      floatingActionButton: const AddItemFab(label: '항목 추가'),
      safeBottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PagePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(boardName,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 3),
                            Text(
                              _formatToday(today),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.mutedText),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: '보드 변경',
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          GroupSelectionScreen.routeName,
                        ),
                        icon: const Icon(Icons.dashboard_customize_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SoftCard(
                    color: AppColors.primarySoft,
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(Icons.monitor_heart_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('오늘의 현황',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 3),
                              Text(
                                '일정 ${schedules.length}개, 남은 할 일 $remainingTasks개',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.mutedText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionHeader(
                      title: '일정', routeName: CalendarViewScreen.routeName),
                  const SizedBox(height: 10),
                  ...schedules.take(3).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ScheduleCard(
                            item: item,
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              ItemDetailEditScreen.routeName,
                              arguments:
                                  BoardItemEditArguments.fromSchedule(item),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: 10),
                  const SectionHeader(
                      title: '할 일', routeName: TasksListScreen.routeName),
                  const SizedBox(height: 10),
                  ...tasks.take(4).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TaskCard(
                            item: item,
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              ItemDetailEditScreen.routeName,
                              arguments: BoardItemEditArguments.fromTask(item),
                            ),
                            onChanged: (value) => onTaskChanged(item, value),
                          ),
                        ),
                      ),
                  const SizedBox(height: 10),
                  const SectionHeader(
                      title: '공지', routeName: NoticesBoardScreen.routeName),
                  const SizedBox(height: 10),
                  ...notices.take(2).map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NoticeCard(
                            item: item,
                            memberCount: members.length,
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              ItemDetailEditScreen.routeName,
                              arguments:
                                  BoardItemEditArguments.fromNotice(item),
                            ),
                            onConfirm: () => onNoticeConfirmed(item),
                          ),
                        ),
                      ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatToday(DateTime date) {
    const weekdays = [
      '월요일',
      '화요일',
      '수요일',
      '목요일',
      '금요일',
      '토요일',
      '일요일',
    ];
    const months = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];
    return '${months[date.month - 1]} ${date.day}일 ${weekdays[date.weekday - 1]}';
  }
}
