Task 02 — Switch between boards (UriPan Flutter, cwd C:\UriPan). Depends on task 01.

PROBLEM: the controller already loads ALL of a user's boards, but there is no UI to switch the active one. A user in 2+ boards is stuck on whichever one was auto-selected.

Read first: lib/services/board_session_controller.dart (load/preferredBoardId, `boards`, `_selectBoard`), lib/screens/board_home_screen.dart, lib/widgets/board_settings_sheet.dart (from task 01), lib/models/board_item.dart (BoardSummary), lib/widgets/common_widgets.dart (RoleChip, CapacityChip), test/board_session_controller_test.dart.

BACKEND FACTS (do not change SQL): `controller.boards` holds every board the user belongs to. `load(preferredBoardId: id)` re-selects the active board and reloads its items/members/invite.

IMPLEMENT:
1. board_session_controller.dart — `Future<void> switchBoard(String boardId)`: no-op if `boardId == activeBoard?.id`; otherwise `await load(preferredBoardId: boardId)`. (Do not add a persistence dependency — in-memory switching only.)
2. board_settings_sheet.dart — add an optional board list section: pass `List<BoardSummary> boards`, the active board id, and `ValueChanged<String> onSelectBoard`. Render the section ONLY when `boards.length > 1`. Each row: board name + RoleChip + CapacityChip, the active one visibly marked; tapping a non-active row calls onSelectBoard and closes the sheet.
3. board_home_screen.dart — pass the controller's boards + active id into the settings sheet and wire `onSelectBoard: (id) => _runAction(() => _controller.switchBoard(id))`.

TESTS (keep all existing green):
- controller test (memory or fake): with two boards, `switchBoard(otherId)` makes that board active and reloads its items; switching to the already-active id does not reload.
- widget test: pump the settings sheet with two boards, assert both names render, tap the non-active one, assert onSelectBoard fired with its id.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Behavior-preserving: add OPTIONAL params, never break existing usages/tests.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
