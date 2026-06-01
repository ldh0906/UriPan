Task 10 — Notices: important & unconfirmed first (UriPan Flutter, cwd C:\UriPan). Depends on notice confirmation fields (already shipped).

Read first: lib/screens/today_board_screen.dart (Notices tab branch + Today notices section), lib/widgets/board_item_card.dart, test/widget_test.dart.

GOAL: notices that still need attention should sort to the top, with clear status.

IMPLEMENT:
1. When building the notices list (both the Notices tab and the Today notices section), sort so that notices with requiresConfirmation == true && isConfirmedByMe == false come first, then pinned, then the rest (keep a stable order within groups, e.g. by created order already provided). Do not mutate the source list in place — sort a copy.
2. Make sure the confirmation status is visible on notice cards (the status chip from the notice-confirmation feature should already render; if a required-but-unconfirmed notice has no visible indicator, add a small "확인 필요" marker — Korean \u escapes).
3. Notices must keep "확인/읽음" language, never "완료".

TESTS:
- widget test: given a normal notice and a required-unconfirmed notice (listed in that order in the source), the Notices tab shows the required-unconfirmed one first.
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
