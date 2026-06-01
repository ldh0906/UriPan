Task 09 — Today "놓치면 안 돼요" attention block (UriPan Flutter, cwd C:\UriPan). Depends on notice confirmation fields (already shipped).

Read first: lib/screens/today_board_screen.dart (Today tab branch + PulseCard usage), lib/widgets/board_header.dart (PulseCard), lib/widgets/board_item_card.dart, test/widget_test.dart.

GOAL: above the normal Today sections (and below or beside the pulse card), add a "needs attention" block that surfaces what the family must not miss.

IMPLEMENT (Today tab only):
1. Compute attention items from the displayed items:
   - overdue tasks: type task, not done, dueAt != null and dueAt < now.
   - unconfirmed important notices: type notice, requiresConfirmation == true, isConfirmedByMe == false.
2. Render a block titled "놓치면 안 돼요" (Korean \u escapes) listing those items (reuse BoardItemCard or a compact row). If there are none, hide the entire block.
3. Keep the existing pulse card and the 오늘 일정 / 할 일 / 공지 sections unchanged below it.

TESTS:
- widget test: with one overdue task and one unconfirmed required notice, the attention block appears and contains them; with none, the block is absent.
- Keep all existing tests green.

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
