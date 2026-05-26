import '../models/board_item.dart';

const seedBoardItems = <BoardItem>[
  BoardItem(
    id: 'schedule-breakfast',
    type: BoardItemType.schedule,
    title: '아침 병원 예약',
    detail: '접수 10분 전 도착, 보험증 챙기기',
    owner: '엄마',
    timeLabel: '09:30',
  ),
  BoardItem(
    id: 'schedule-dinner',
    type: BoardItemType.schedule,
    title: '저녁 식사 준비',
    detail: '냉장고 반찬 확인 후 장보기',
    owner: '아빠',
    timeLabel: '18:00',
  ),
  BoardItem(
    id: 'task-trash',
    type: BoardItemType.task,
    title: '분리수거 내놓기',
    detail: '플라스틱과 종이 따로 묶기',
    owner: '민수',
    timeLabel: '오늘',
  ),
  BoardItem(
    id: 'task-form',
    type: BoardItemType.task,
    title: '학교 동의서 확인',
    detail: '사진 촬영 동의 항목 체크',
    owner: '지은',
    timeLabel: '마감 D-1',
  ),
  BoardItem(
    id: 'notice-visit',
    type: BoardItemType.notice,
    title: '주말 손님 방문',
    detail: '토요일 오후 3시에 외삼촌 가족 방문',
    owner: '엄마',
    timeLabel: '고정',
    isPinned: true,
  ),
  BoardItem(
    id: 'notice-parking',
    type: BoardItemType.notice,
    title: '주차장 공사',
    detail: '금요일 오전에는 지하 2층 이용 불가',
    owner: '관리실',
    timeLabel: '읽기',
  ),
];
