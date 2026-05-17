import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';

class MockData {
  static const members = <FamilyMember>[
    FamilyMember(name: 'Seoyun Kim', initials: 'SY', role: 'Admin', color: AppColors.primary),
    FamilyMember(name: 'Junho Lee', initials: 'JH', role: 'Member', color: AppColors.tertiary),
    FamilyMember(name: 'Minsoo Park', initials: 'MS', role: 'Member', color: AppColors.success),
    FamilyMember(name: 'Eunji Choi', initials: 'EJ', role: 'Member', color: AppColors.info),
  ];

  static const boards = <BoardData>[
    BoardData(
      name: 'Sweet Home',
      role: 'Admin',
      members: '4',
      schedules: 'Dinner at 7 PM',
      tasks: '3 Tasks remaining',
      notices: '1 New notice',
    ),
    BoardData(
      name: 'Algorithms Study',
      role: 'Member',
      members: '6',
      schedules: 'Zoom at 8 PM',
      tasks: 'Quiz prep due',
      notices: 'No new notices',
    ),
    BoardData(
      name: 'Room 302',
      role: 'Member',
      members: '3',
      schedules: 'Rent due tomorrow',
      tasks: 'Cleaning day',
      notices: '2 New notices',
    ),
  ];

  static const schedules = <ScheduleItemData>[
    ScheduleItemData(
      id: 'schedule-1',
      title: 'Grocery Shopping',
      initials: 'MK',
      start: '10:00 AM',
      end: '11:00 AM',
      color: AppColors.primary,
    ),
    ScheduleItemData(
      id: 'schedule-2',
      title: 'Study Group Session',
      initials: 'AS',
      start: '02:00 PM',
      end: '04:00 PM',
      color: AppColors.tertiary,
    ),
    ScheduleItemData(
      id: 'schedule-3',
      title: 'Dinner with Grandma',
      initials: 'JD',
      start: '06:30 PM',
      end: '08:00 PM',
      color: AppColors.success,
    ),
  ];

  static const tasks = <TaskItemData>[
    TaskItemData(
      id: 'task-1',
      title: 'Take out the trash',
      assignee: 'Mark',
      initials: 'MK',
      dueDate: 'Today, 5:30 PM',
      color: AppColors.primary,
      isDone: true,
    ),
    TaskItemData(
      id: 'task-2',
      title: 'Wash the dishes',
      assignee: 'Alice',
      initials: 'AS',
      dueDate: 'Today, 6:00 PM',
      color: AppColors.tertiary,
      isDone: false,
    ),
    TaskItemData(
      id: 'task-3',
      title: 'Pay electricity bill',
      assignee: 'John',
      initials: 'JD',
      dueDate: 'Oct 24',
      color: AppColors.success,
      isDone: false,
      memo: 'Check online account before paying',
    ),
    TaskItemData(
      id: 'task-4',
      title: 'Water the plants',
      assignee: 'Alice',
      initials: 'AS',
      dueDate: 'Yesterday',
      color: AppColors.tertiary,
      isDone: false,
    ),
    TaskItemData(
      id: 'task-5',
      title: 'Buy groceries for dinner',
      assignee: 'JS',
      initials: 'JS',
      dueDate: 'Today, 6:00 PM',
      color: AppColors.info,
      isDone: false,
      memo: 'Milk, Eggs, Pasta',
    ),
    TaskItemData(
      id: 'task-6',
      title: 'Fix the leaky faucet',
      assignee: 'AR',
      initials: 'AR',
      dueDate: 'Today, 8:00 PM',
      color: AppColors.secondary,
      isDone: false,
    ),
  ];

  static const notices = <NoticeItemData>[
    NoticeItemData(
      id: 'notice-1',
      title: 'Weekend Trip',
      preview: "Don't forget to pack your swimsuits for the lake house trip this Saturday!",
      date: 'Oct 24, 10:15 AM',
      isImportant: true,
      confirmedByMe: false,
      confirmedCount: 3,
      confirmedInitials: ['AR', 'BK', 'JS'],
    ),
    NoticeItemData(
      id: 'notice-2',
      title: 'Internet Maintenance',
      preview: 'Service provider mentioned brief outages between 2 AM and 4 AM on Tuesday.',
      date: 'Oct 22, 02:30 PM',
      isImportant: false,
      confirmedByMe: true,
      confirmedCount: 1,
      confirmedInitials: ['BK'],
    ),
    NoticeItemData(
      id: 'notice-3',
      title: 'Rent & Utilities Due',
      preview:
          'Hi everyone, just a reminder that the rent and electricity bill are due this Friday. Please transfer your share to the main account by Thursday evening.',
      date: 'Oct 24, 10:15 AM',
      isImportant: true,
      confirmedByMe: true,
      confirmedCount: 3,
      confirmedInitials: ['AR', 'BK', 'JS'],
    ),
    NoticeItemData(
      id: 'notice-4',
      title: 'Weekend Guest',
      preview:
          "My brother is visiting this weekend from Friday night to Sunday afternoon. He'll be sleeping on the couch. Hope that's okay with everyone!",
      date: 'Oct 20, 09:00 AM',
      isImportant: false,
      confirmedByMe: true,
      confirmedCount: 2,
      confirmedInitials: ['AR', 'JS'],
    ),
  ];

  static const calendarHighlights = <int, Color>{
    3: AppColors.success,
    5: AppColors.primary,
    9: AppColors.info,
    12: AppColors.tertiary,
    19: AppColors.success,
    23: AppColors.primary,
    24: AppColors.tertiary,
    28: AppColors.info,
  };
}
