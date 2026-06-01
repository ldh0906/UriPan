Task 07 — Tasks tab filter: 미완료 / 내 할 일 / 완료 (UriPan Flutter, cwd C:\UriPan). Depends on task 01 (assignedToId).

Read first: lib/screens/today_board_screen.dart (the Tasks tab branch), lib/widgets/board_item_card.dart, lib/screens/board_home_screen.dart, test/widget_test.dart.

IMPLEMENT:
1. TodayBoardScreen — add an optional `final String? currentUserId;` param (board_home_screen passes client.auth.currentUser?.id; do not break existing usages/tests where it is null).
2. In the Tasks tab, add a SegmentedButton with three filters: 미완료 (not done), 내 할 일 (assignedToId == currentUserId), 완료 (done). Hold the selected filter in state (local to the screen). Default to 미완료.
3. Apply the filter to the tasks list shown in the Tasks tab only (do not change the Today tab tasks section).
4. If currentUserId is null, the 내 할 일 filter simply shows nothing (or hide that segment) — keep it robust.

TESTS:
- widget test: pump TodayBoardScreen with a mix of tasks (done/undone, assigned/unassigned), switch to the Tasks tab, and verify each segment filters correctly (use currentUserId to test 내 할 일).
- Keep all existing tests green (the existing Tasks-tab test expects the default to still show open tasks — adjust only if needed and keep its intent).

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Behavior-preserving: add OPTIONAL params, never remove/rename existing public APIs, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
