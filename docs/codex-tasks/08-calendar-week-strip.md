Task 08 — Calendar week strip + selected-date schedules (UriPan Flutter, cwd C:\UriPan).

Read first: lib/screens/today_board_screen.dart (the Calendar tab branch), lib/widgets/board_item_card.dart, lib/models/board_item.dart (isForDate), test/widget_test.dart.

GOAL: replace the flat schedule list in the Calendar tab with a week strip + the selected day's schedules. Keep it simple — no month grid.

IMPLEMENT (Calendar tab only):
1. A horizontal week strip of 7 day cells (Mon–Sun or Sun–Sat, your call) for the week containing a `selectedDate` held in screen state (default today). Tapping a day selects it; selected day is visually highlighted (use AppColors/DESIGN tokens).
2. Prev/next week controls (arrows) that shift the visible week.
3. Below the strip, show the schedules whose date matches selectedDate (reuse BoardItem.isForDate or compare startsAt date). Empty state: "이 날 일정이 없어요" (Korean \u escapes).
4. Keep the contextual add default for Calendar (schedule) intact.

TESTS:
- widget test: with schedules on two different days, switch to Calendar, confirm the default (today) shows today's schedule; tapping another day shows that day's schedule and hides the other.
- Keep all existing tests green (the existing Calendar test expects all schedules to be reachable — update its expectation thoughtfully if your design changes it, but prefer keeping a path that shows the schedule).

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Behavior-preserving: add OPTIONAL params, never remove/rename existing public APIs, keep ALL existing tests green (adjust the one Calendar test only if your new UX requires it, keeping its intent).

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
