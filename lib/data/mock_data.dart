import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../theme/app_theme.dart';

class MockData {
  static const user = UserProfile(
    name: '김지훈',
    email: 'jihoon.kim@example.com',
    initials: '지훈',
    color: AppColors.primary,
  );

  static final initialSnapshot = AppSnapshot(
    user: user,
    isAuthenticated: false,
    activeInviteCode: 'URIPAN-2024',
    boards: boardWorkspaces,
  );

  static const members = <FamilyMember>[
    FamilyMember(
        name: '김서윤', initials: '서윤', role: '관리자', color: AppColors.primary),
    FamilyMember(
        name: '이준호', initials: '준호', role: '멤버', color: AppColors.tertiary),
    FamilyMember(
        name: '박민수', initials: '민수', role: '멤버', color: AppColors.success),
    FamilyMember(
        name: '최은지', initials: '은지', role: '멤버', color: AppColors.info),
  ];

  static const boards = <BoardData>[
    BoardData(
      name: '우리 집',
      role: '관리자',
      members: '4',
      schedules: '오후 7시 저녁 약속',
      tasks: '남은 할 일 3개',
      notices: '새 공지 1개',
    ),
    BoardData(
      name: '알고리즘 스터디',
      role: '멤버',
      members: '6',
      schedules: '오후 8시 Zoom',
      tasks: '퀴즈 준비 마감',
      notices: '새 공지 없음',
    ),
    BoardData(
      name: '302호',
      role: '멤버',
      members: '3',
      schedules: '내일 월세 납부',
      tasks: '청소하는 날',
      notices: '새 공지 2개',
    ),
  ];

  static final boardWorkspaces = <BoardWorkspace>[
    BoardWorkspace(
      board: boards[0],
      inviteCode: 'URIPAN-2024',
      members: members,
      schedules: schedules,
      tasks: tasks,
      notices: notices,
    ).withSyncedSummary(),
    BoardWorkspace(
      board: boards[1],
      inviteCode: 'ALGO-2024',
      members: const [
        FamilyMember(
          name: '송하나',
          initials: '하나',
          role: '관리자',
          color: AppColors.primary,
        ),
        FamilyMember(
          name: '강도윤',
          initials: '도윤',
          role: '멤버',
          color: AppColors.info,
        ),
        FamilyMember(
          name: '조미나',
          initials: '미나',
          role: '읽기 전용',
          color: AppColors.tertiary,
        ),
      ],
      schedules: const [
        ScheduleItemData(
          id: 'algo-schedule-1',
          title: '모의 면접 라운드',
          initials: '하나',
          date: '2026년 5월 17일',
          start: '오후 8:00',
          end: '오후 9:00',
          color: AppColors.info,
        ),
      ],
      tasks: const [
        TaskItemData(
          id: 'algo-task-1',
          title: '그래프 최단경로 문제 풀기',
          assignee: '도윤',
          initials: '도윤',
          dueDate: '2026년 5월 18일',
          color: AppColors.info,
          isDone: false,
          memo: '리뷰할 예외 케이스 메모를 가져오기.',
        ),
      ],
      notices: const [
        NoticeItemData(
          id: 'algo-notice-1',
          title: '이번 주 집중 범위',
          preview: '다익스트라, 벨만-포드, 유니온 파인드를 복습합니다.',
          date: '2026년 5월 17일',
          isImportant: true,
          confirmedByMe: false,
          confirmedCount: 1,
          confirmedInitials: ['HS'],
        ),
      ],
    ).withSyncedSummary(),
    BoardWorkspace(
      board: boards[2],
      inviteCode: 'ROOM-302',
      members: const [
        FamilyMember(
          name: '한아름',
          initials: '아름',
          role: '관리자',
          color: AppColors.primary,
        ),
        FamilyMember(
          name: '김보라',
          initials: '보라',
          role: '멤버',
          color: AppColors.success,
        ),
        FamilyMember(
          name: '한지수',
          initials: '지수',
          role: '멤버',
          color: AppColors.warning,
        ),
      ],
      schedules: const [
        ScheduleItemData(
          id: 'room-schedule-1',
          title: '공과금 분담 확인',
          initials: '아름',
          date: '2026년 5월 20일',
          start: '오후 7:30',
          end: '오후 8:00',
          color: AppColors.primary,
        ),
      ],
      tasks: const [
        TaskItemData(
          id: 'room-task-1',
          title: '공용 냉장고 정리',
          assignee: '보라',
          initials: '보라',
          dueDate: '2026년 5월 19일',
          color: AppColors.success,
          isDone: false,
        ),
      ],
      notices: const [
        NoticeItemData(
          id: 'room-notice-1',
          title: '조용한 시간 안내',
          preview: '밤 11시 이후에는 세탁기와 음악 소리를 줄여주세요.',
          date: '2026년 5월 16일',
          isImportant: false,
          confirmedByMe: true,
          confirmedCount: 2,
          confirmedInitials: ['AR', 'BK'],
        ),
      ],
    ).withSyncedSummary(),
  ];

  static const schedules = <ScheduleItemData>[
    ScheduleItemData(
      id: 'schedule-1',
      title: '장보기',
      initials: '지훈',
      date: '2026년 5월 17일',
      start: '오전 10:00',
      end: '오전 11:00',
      color: AppColors.primary,
    ),
    ScheduleItemData(
      id: 'schedule-2',
      title: '스터디 모임',
      initials: '서윤',
      date: '2026년 5월 17일',
      start: '오후 2:00',
      end: '오후 4:00',
      color: AppColors.tertiary,
    ),
    ScheduleItemData(
      id: 'schedule-3',
      title: '할머니와 저녁 식사',
      initials: '준호',
      date: '2026년 5월 16일',
      start: '오후 6:30',
      end: '오후 8:00',
      color: AppColors.success,
    ),
  ];

  static const tasks = <TaskItemData>[
    TaskItemData(
      id: 'task-1',
      title: '쓰레기 버리기',
      assignee: '지훈',
      initials: '지훈',
      dueDate: '오늘 오후 5:30',
      color: AppColors.primary,
      isDone: true,
    ),
    TaskItemData(
      id: 'task-2',
      title: '설거지하기',
      assignee: '서윤',
      initials: '서윤',
      dueDate: '오늘 오후 6:00',
      color: AppColors.tertiary,
      isDone: false,
    ),
    TaskItemData(
      id: 'task-3',
      title: '전기요금 납부',
      assignee: '준호',
      initials: '준호',
      dueDate: '5월 24일',
      color: AppColors.success,
      isDone: false,
      memo: '납부 전에 온라인 계정 확인',
    ),
    TaskItemData(
      id: 'task-4',
      title: '화분 물 주기',
      assignee: '서윤',
      initials: '서윤',
      dueDate: '어제',
      color: AppColors.tertiary,
      isDone: false,
    ),
    TaskItemData(
      id: 'task-5',
      title: '저녁 재료 사오기',
      assignee: '은지',
      initials: '은지',
      dueDate: '오늘 오후 6:00',
      color: AppColors.info,
      isDone: false,
      memo: '우유, 달걀, 파스타',
    ),
    TaskItemData(
      id: 'task-6',
      title: '수도꼭지 누수 고치기',
      assignee: '민수',
      initials: '민수',
      dueDate: '오늘 오후 8:00',
      color: AppColors.secondary,
      isDone: false,
    ),
  ];

  static const notices = <NoticeItemData>[
    NoticeItemData(
      id: 'notice-1',
      title: '주말 여행',
      preview: '이번 토요일 호숫가 숙소에 갈 때 수영복 챙기는 것 잊지 마세요!',
      date: '5월 17일 오전 10:15',
      isImportant: true,
      confirmedByMe: false,
      confirmedCount: 3,
      confirmedInitials: ['AR', 'BK', 'JS'],
    ),
    NoticeItemData(
      id: 'notice-2',
      title: '인터넷 점검',
      preview: '화요일 새벽 2시부터 4시 사이에 잠깐 인터넷이 끊길 수 있다고 합니다.',
      date: '5월 15일 오후 2:30',
      isImportant: false,
      confirmedByMe: true,
      confirmedCount: 1,
      confirmedInitials: ['BK'],
    ),
    NoticeItemData(
      id: 'notice-3',
      title: '월세와 공과금 마감',
      preview: '이번 금요일이 월세와 전기요금 납부일입니다. 목요일 저녁까지 각자 부담금을 대표 계좌로 보내주세요.',
      date: '5월 17일 오전 10:15',
      isImportant: true,
      confirmedByMe: true,
      confirmedCount: 3,
      confirmedInitials: ['AR', 'BK', 'JS'],
    ),
    NoticeItemData(
      id: 'notice-4',
      title: '주말 손님',
      preview: '이번 주말 금요일 밤부터 일요일 오후까지 동생이 방문합니다. 거실 소파를 사용할 예정이에요.',
      date: '5월 14일 오전 9:00',
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
