import '../models/board_item.dart';

final _today = DateTime.now();
DateTime _todayAt(int hour, int minute) =>
    DateTime(_today.year, _today.month, _today.day, hour, minute);
DateTime _tomorrowAt(int hour, int minute) =>
    DateTime(_today.year, _today.month, _today.day + 1, hour, minute);

final seedBoardItems = <BoardItem>[
  BoardItem(
    id: 'schedule-breakfast',
    type: BoardItemType.schedule,
    title: '\uC544\uCE68 \uBCD1\uC6D0 \uC608\uC57D',
    detail:
        '\uC811\uC218 10\uBD84 \uC804 \uB3C4\uCC29, \uBCF4\uD5D8\uC99D \uCC59\uAE30\uAE30',
    owner: '\uC5C4\uB9C8',
    timeLabel: '09:30',
    startsAt: _todayAt(9, 30),
    tags: ['\uBCD1\uC6D0', '\uC900\uBE44\uBB3C'],
  ),
  BoardItem(
    id: 'schedule-dinner',
    type: BoardItemType.schedule,
    title: '\uC800\uB141 \uC2DD\uC0AC \uC900\uBE44',
    detail:
        '\uB0C9\uC7A5\uACE0 \uBC18\uCC2C \uD655\uC778 \uD6C4 \uC7A5\uBCF4\uAE30',
    owner: '\uC544\uBE60',
    timeLabel: '18:00',
    startsAt: _tomorrowAt(18, 0),
  ),
  BoardItem(
    id: 'task-trash',
    type: BoardItemType.task,
    title: '\uBD84\uB9AC\uC218\uAC70 \uB0B4\uB193\uAE30',
    detail:
        '\uD50C\uB77C\uC2A4\uD2F1\uACFC \uC885\uC774 \uB530\uB85C \uBB36\uAE30',
    owner: '\uBBFC\uC218',
    timeLabel: '\uC624\uB298',
    dueAt: _todayAt(21, 0),
    tags: ['\uC9D1\uC548\uC77C'],
  ),
  BoardItem(
    id: 'task-form',
    type: BoardItemType.task,
    title: '\uD559\uAD50 \uB3D9\uC758\uC11C \uD655\uC778',
    detail: '\uC0AC\uC9C4 \uCD2C\uC601 \uB3D9\uC758 \uD56D\uBAA9 \uCCB4\uD06C',
    owner: '\uC9C0\uC6B0',
    timeLabel: '\uB9C8\uAC10 D-1',
    dueAt: _tomorrowAt(18, 0),
  ),
  BoardItem(
    id: 'notice-visit',
    type: BoardItemType.notice,
    title: '\uC8FC\uB9D0 \uC190\uB2D8 \uBC29\uBB38',
    detail:
        '\uD1A0\uC694\uC77C \uC624\uD6C4 3\uC2DC\uC5D0 \uC678\uC0BC\uCD0C \uAC00\uC871 \uBC29\uBB38',
    owner: '\uC5C4\uB9C8',
    timeLabel: '\uACE0\uC815',
    isPinned: true,
    tags: ['\uC8FC\uB9D0', '\uAC00\uC871'],
  ),
  BoardItem(
    id: 'notice-parking',
    type: BoardItemType.notice,
    title: '\uC8FC\uCC28\uC7A5 \uACF5\uC0AC',
    detail:
        '\uAE08\uC694\uC77C \uC624\uC804\uC5D0\uB294 \uC9C0\uD558 2\uCE35 \uC774\uC6A9 \uBD88\uAC00',
    owner: '\uAD00\uB9AC\uC2E4',
    timeLabel: '\uC77D\uAE30',
  ),
];
