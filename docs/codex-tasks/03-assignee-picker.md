Task 03 — Assignee picker when adding/editing a task (UriPan Flutter, cwd C:\UriPan). Depends on tasks 01 and 02.

Let a member assign a task to another member. BoardItemDraft already has `assignedTo`; the Add/Edit sheet just doesn't expose it yet. Client-side Dart only.

Read first: lib/widgets/board_action_sheets.dart, lib/services/board_session_controller.dart (members from task 02), lib/models/board_item.dart, lib/screens/board_home_screen.dart, lib/screens/today_board_screen.dart, test/widget_test.dart.

IMPLEMENT:
1. board_action_sheets.dart AddItemSheet — add an optional `final List<BoardMember> members;` (default const []). When the selected type is `task` and members is non-empty, show an assignee selector (Dropdown or choice chips) including a "담당 없음" (no assignee) option. Selecting sets the value used for BoardItemDraft.assignedTo (the member's userId). In edit mode (initialItem != null) prefill from initialItem.assignedToId.
2. Thread members through: showAddItemSheet and showEditItemSheet gain an optional `members` param; board_home_screen passes controller.members.
3. Keep create/edit for schedule/notice unchanged (no assignee UI there).

TESTS:
- widget test: AddItemSheet(initialType: task, members: [..]) shows the assignee selector; selecting a member then submitting returns a BoardItemDraft with that assignedTo. (Pump the sheet directly like existing AddItemSheet tests.)
- Keep all existing tests green (existing AddItemSheet tests pass empty members and must be unaffected).

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
