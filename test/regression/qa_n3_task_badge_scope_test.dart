// QA-N3 / 2026-06-14 P3: "할 일" 탭 배지/오버듀는 내 담당 + 미배정만 집계해야 한다.
// 제품 결정(2026-06-14): 타인 담당 할 일은 전체 목록에는 보이되 내 배지/오버듀에는
// 잡히지 않는다. 담당자 무관 전체 집계로 회귀하면 개인 기준 과대 카운트가 된다.
// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/screens/today_board_screen.dart';

const _me = 'user-me';
const _other = 'user-other';

BoardItem _task({
  required String id,
  String? assignedToId,
  DateTime? dueAt,
  bool isDone = false,
}) {
  return BoardItem(
    id: id,
    type: BoardItemType.task,
    title: id,
    detail: '',
    owner: 'owner',
    timeLabel: '',
    assignedToId: assignedToId,
    dueAt: dueAt,
    isDone: isDone,
  );
}

void main() {
  final now = DateTime(2026, 6, 14, 9, 0);
  final dueToday = DateTime(2026, 6, 14, 18, 0);
  final overdue = DateTime(2026, 6, 13, 18, 0);

  group('QA-N3 task badge/overdue scope', () {
    test('badge counts my-assigned and unassigned, excludes others', () {
      final items = [
        _task(id: 'mine', assignedToId: _me, dueAt: dueToday),
        _task(id: 'unassigned', assignedToId: null, dueAt: dueToday),
        _task(id: 'theirs', assignedToId: _other, dueAt: dueToday),
        _task(id: 'mine-done', assignedToId: _me, dueAt: dueToday, isDone: true),
      ];

      expect(taskBadgeCount(items, now: now, currentUserId: _me), 2);
    });

    test('overdue highlight follows the same scope rule', () {
      expect(
        isOverdueTask(
          _task(id: 'mine', assignedToId: _me, dueAt: overdue),
          now: now,
          currentUserId: _me,
        ),
        isTrue,
      );
      expect(
        isOverdueTask(
          _task(id: 'unassigned', assignedToId: null, dueAt: overdue),
          now: now,
          currentUserId: _me,
        ),
        isTrue,
      );
      expect(
        isOverdueTask(
          _task(id: 'theirs', assignedToId: _other, dueAt: overdue),
          now: now,
          currentUserId: _me,
        ),
        isFalse,
      );
    });

    test('scope predicate treats null assignee as in-scope', () {
      expect(isTaskInMyScope(_task(id: 'a'), currentUserId: _me), isTrue);
      expect(
        isTaskInMyScope(
          _task(id: 'b', assignedToId: _other),
          currentUserId: _me,
        ),
        isFalse,
      );
    });
  });
}
