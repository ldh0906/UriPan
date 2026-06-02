Task 12 — Quick-complete overdue tasks + flag overdue in Tasks (UriPan Flutter, cwd C:\UriPan).

Read first: lib/screens/today_board_screen.dart (the '놓치면 안 돼요' attention BoardItemSection, _toggleTask, _filteredTasks), lib/widgets/board_item_card.dart (BoardItemCard showCheckbox, BoardItemSection), lib/models/board_item.dart (dueAt, isDone), test/widget_test.dart.

GOAL: (a) let users tick off an overdue task straight from the attention block; (b) make overdue tasks visually obvious in the Tasks tab.

IMPLEMENT:
1. board_item_card.dart — make the checkbox render only when `showCheckbox && item.type == BoardItemType.task` (so a section can mix tasks + notices safely and only tasks get a checkbox). This lets the attention block enable checkboxes without affecting its notices.
2. today_board_screen.dart — on the attention BoardItemSection, set `showCheckbox: true` and `onToggle: _toggleTask`. Notices in that block stay tap-to-open (no checkbox, per step 1).
3. board_item_card.dart — add an optional `bool isOverdue` (default false). When true, show a small '지남' marker chip (use AppColors.tertiary / warningSoft) on the card.
4. today_board_screen.dart — in the Tasks tab list, compute overdue (`!isDone && dueAt != null && dueAt.isBefore(DateTime.now())`) per card and pass `isOverdue` so overdue tasks are flagged. (Attention block tasks are already overdue by definition — flagging them there too is fine.)

TESTS (keep all existing green):
- widget test: in the attention block, an overdue task shows a checkbox and ticking it calls onCompleteTask with isDone true.
- widget test: an overdue task in the Tasks tab shows the '지남' marker.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Behavior-preserving: add OPTIONAL params, keep ALL existing tests green (the existing Today-tab tests must still pass — note step 1 changes when the checkbox appears, so double-check the '할 일' Today section, which only has tasks, is unaffected).

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
