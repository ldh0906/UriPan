Task 11 — Bottom-nav count badges (UriPan Flutter, cwd C:\UriPan).

Read first: lib/widgets/common_widgets.dart (AppBottomNav, BoardTab), lib/screens/today_board_screen.dart (_attentionItems, overdue/open task logic, notices), test/widget_test.dart.

GOAL: surface what needs attention on the bottom nav so users notice it from any tab.

IMPLEMENT:
1. common_widgets.dart — `AppBottomNav` gains an optional `Map<BoardTab, int> badges` (default const {}). For each tab with a count > 0, render a small count badge on the corner of the tab icon (use AppColors.tertiary / a clear accent; cap display at '9+'). Keep layout stable when there is no badge.
2. today_board_screen.dart — compute counts from the displayed items and pass them in:
   - BoardTab.notices -> number of required & unconfirmed notices (requiresConfirmation && !isConfirmedByMe).
   - BoardTab.tasks -> number of overdue OR today-open tasks (not done, dueAt != null, dueAt before end of today) — keep it simple and consistent with the attention/overdue logic already in the file.
   - BoardTab.today -> attentionItems.length (optional).

TESTS (keep all existing green):
- widget test: with one required-unconfirmed notice, AppBottomNav shows a '1' badge on the 공지 tab; with none, no badge.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Behavior-preserving: add OPTIONAL params, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
