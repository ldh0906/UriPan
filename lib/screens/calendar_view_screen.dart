import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';
import '../screens/item_detail_edit_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({
    super.key,
    required this.boardName,
    required this.members,
    required this.schedules,
    required this.onScheduleDeleted,
  });

  static const routeName = '/calendar';

  final String boardName;
  final List<FamilyMember> members;
  final List<ScheduleItemData> schedules;
  final ValueChanged<ScheduleItemData> onScheduleDeleted;

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  late DateTime focusedMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    focusedMonth = DateTime(today.year, today.month);
    selectedDate = DateTime(today.year, today.month, today.day);
  }

  @override
  Widget build(BuildContext context) {
    final monthCells = _buildMonthCells(focusedMonth);
    final selectedLabel =
        '${_weekdayName(selectedDate.weekday)}, ${_monthName(selectedDate.month)} ${selectedDate.day}';
    final selectedDateKey = _formatDate(selectedDate);
    final selectedSchedules = widget.schedules
        .where((schedule) => schedule.date == selectedDateKey)
        .toList();

    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 1),
      floatingActionButton: const AddItemFab(
        label: 'Add Schedule',
        itemType: BoardItemType.schedule,
      ),
      safeBottom: false,
      child: SingleChildScrollView(
        child: PagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_monthName(focusedMonth.month)} ${focusedMonth.year}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          widget.boardName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SoftCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                          .map(
                            (day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(color: AppColors.mutedText),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: monthCells.length,
                      itemBuilder: (context, index) {
                        final date = monthCells[index];
                        if (date == null) {
                          return const CalendarDayCell.empty();
                        }

                        final day = date.day;
                        return CalendarDayCell(
                          day: day,
                          isSelected: _isSameDate(date, selectedDate),
                          isToday: _isSameDate(date, DateTime.now()),
                          marker: _markerFor(date),
                          onTap: () => setState(() => selectedDate = date),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${selectedSchedules.length} Events',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (selectedSchedules.isEmpty)
                const EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No schedules',
                  message: 'Schedules for the selected date will appear here.',
                )
              else
                ...selectedSchedules.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) {
                        widget.onScheduleDeleted(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.title} deleted.')),
                        );
                      },
                      child: ScheduleCard(
                        item: item,
                        onTap: () => Navigator.pushNamed(
                          context,
                          ItemDetailEditScreen.routeName,
                          arguments: BoardItemEditArguments.fromSchedule(item),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
      selectedDate = DateTime(focusedMonth.year, focusedMonth.month, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
      selectedDate = DateTime(focusedMonth.year, focusedMonth.month, 1);
    });
  }

  List<DateTime?> _buildMonthCells(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    const daysPerWeek = 7;
    final leadingBlanks = firstDay.weekday % daysPerWeek;
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(month.year, month.month, day),
    ];

    while (cells.length % daysPerWeek != 0 || cells.length < 42) {
      cells.add(null);
    }

    return cells;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _formatDate(DateTime date) {
    return '${_monthName(date.month).substring(0, 3)} ${date.day}, ${date.year}';
  }

  Color? _markerFor(DateTime date) {
    final hasSchedule = widget.schedules.any(
      (schedule) => schedule.date == _formatDate(date),
    );
    if (hasSchedule) {
      return AppColors.primary;
    }

    if (date.month == 10 && date.year == 2023) {
      return MockData.calendarHighlights[date.day];
    }

    return null;
  }
}

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.marker,
    this.onTap,
  }) : isEmpty = false;

  const CalendarDayCell.empty({super.key})
      : day = 0,
        isSelected = false,
        isToday = false,
        marker = null,
        onTap = null,
        isEmpty = true;

  final int day;
  final bool isSelected;
  final bool isToday;
  final Color? marker;
  final VoidCallback? onTap;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primarySoft
                  : AppColors.surfaceVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : AppColors.text,
                  ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: marker ?? Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
