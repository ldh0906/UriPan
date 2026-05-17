import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/mock_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CalendarViewScreen extends StatelessWidget {
  const CalendarViewScreen({
    super.key,
    required this.members,
    required this.schedules,
  });

  static const routeName = '/calendar';

  final List<FamilyMember> members;
  final List<ScheduleItemData> schedules;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      bottomNavigation: const AppBottomNav(currentIndex: 1),
      floatingActionButton: const AddItemFab(label: 'Add Schedule'),
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
                        Text('October 2023', style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                          'Family Home Board',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                        ),
                      ],
                    ),
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
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.mutedText),
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
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 35,
                      itemBuilder: (context, index) {
                        final day = index + 1;
                        return CalendarDayCell(
                          day: day,
                          isSelected: day == 24,
                          isToday: day == 23,
                          marker: MockData.calendarHighlights[day],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Tuesday, Oct 24', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('3 Events', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...schedules.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ScheduleCard(item: item),
                ),
              ),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    this.isSelected = false,
    this.isToday = false,
    this.marker,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final Color? marker;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : isToday ? AppColors.primarySoft : AppColors.surfaceVariant.withValues(alpha: 0.35),
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
    );
  }
}
