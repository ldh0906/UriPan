Task 06 — Date/time input validation for schedules and tasks (UriPan Flutter, cwd C:\UriPan).

Read first: lib/widgets/board_action_sheets.dart, test/widget_test.dart.

GOAL: tighten the Add/Edit sheet so users can't create nonsensical dates, with clear inline Korean errors. Keep it minimal and testable.

IMPLEMENT (in AddItemSheet._submit and build):
1. Title required — already exists; keep it.
2. For a NEW schedule or task (initialItem == null), if the chosen date+time is before now, show an inline error meaning "지난 시간은 선택할 수 없어요" and do not submit. (Editing an existing item is allowed to keep a past date, so only enforce this in create mode.)
3. Show the validation error near the date/time row (add an error Text under _DateTimePickerRow when set), and clear it when the user picks a new date/time.
4. Do not change schedule/notice behavior otherwise.

TESTS:
- widget test: in create mode, picking/submitting a past datetime for a task shows the error and does not pop; a valid future datetime submits a BoardItemDraft.
- Keep all existing tests green (existing schedule/task add tests use default now()-based dates — make sure they still pass; if "now" becomes borderline, allow the current minute, i.e. reject only strictly-before-today or before now minus a small grace as you prefer, but keep existing tests green).

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Behavior-preserving: keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
