Task 14 — Empty / loading state polish (UriPan Flutter, cwd C:\UriPan).

Read first: lib/widgets/board_item_card.dart (BoardItemSection empty branch + emptyText), lib/widgets/common_widgets.dart (SoftCard), lib/screens/board_home_screen.dart (FutureBuilder waiting -> bare CircularProgressIndicator), lib/widgets/board_state_screens.dart, test/widget_test.dart.

GOAL: replace bare empty/loading visuals with consistent, friendly ones. Keep current empty MESSAGES (do not regress the exact strings existing tests assert, e.g. '남은 할 일이 없어요.', '읽을 공지가 없어요.', '이날 일정이 없어요.', '내 할 일이 없어요.', '완료한 할 일이 없어요.').

IMPLEMENT:
1. lib/widgets/common_widgets.dart — a reusable `EmptyState` widget: a muted icon + a title line (the message). Accept an `icon` and `message`.
2. board_item_card.dart — the BoardItemSection empty branch renders `EmptyState` using the section's `icon` and the existing `emptyText ?? '아직 항목이 없어요.'`. The displayed text must remain exactly the same string so existing finders pass.
3. board_home_screen.dart — replace the first-load `CircularProgressIndicator` with a lightweight skeleton (a few SoftCard placeholders) OR keep a centered spinner but inside the board chrome. Keep it simple; do not add packages.

TESTS (keep all existing green):
- widget test: an empty BoardItemSection renders an EmptyState whose text equals the provided emptyText.
- Re-run existing empty-state finders to confirm the strings still match.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Do not change existing empty-state strings (tests depend on them).
- Behavior-preserving: keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
