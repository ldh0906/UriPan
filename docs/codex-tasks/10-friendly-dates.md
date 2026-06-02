Task 10 — Friendly date labels: 오늘 / 내일 / N일 지남 / 요일 (UriPan Flutter, cwd C:\UriPan).

Read first: lib/widgets/board_item_card.dart (the InfoChip(label: item.timeLabel) row), lib/widgets/item_detail_sheet.dart (_dateLabel), lib/models/board_item.dart (startsAt, dueAt, type, isForDate), test/widget_test.dart.

GOAL: friendlier day context without breaking the stored timeLabel. Do the work as a DERIVED display from startsAt/dueAt — do NOT change the `timeLabel` field or the repo `_timeLabel` builders (existing tests pass explicit timeLabel values).

IMPLEMENT:
1. New pure file lib/services/friendly_date.dart — `String? friendlyDayLabel(DateTime? when, {DateTime? now})` returning, for the date part only:
   - same day -> '오늘'
   - next day -> '내일'
   - previous day -> '어제'
   - within the next 6 days -> the Korean weekday ('월'..'일') or '이번 주 <요일>' (your call, keep it short)
   - past -> 'N일 지남'
   - otherwise -> 'M월 D일'
   Return null when `when` is null. Add a relative helper if useful (e.g. overdue days). Keep it dependency-free (no intl).
2. board_item_card.dart — for schedule/task cards, show the friendly label next to (or instead of) the raw time chip: e.g. an extra small InfoChip with `friendlyDayLabel(item.startsAt ?? item.dueAt)` when non-null. Keep the existing time chip too if it adds value (HH:mm for schedules). Do not crash when both are null (notices).
3. item_detail_sheet.dart — prepend the friendly label to the date row (e.g. '오늘 · 2026.06.02 18:00').

TESTS (keep all existing green):
- unit tests for friendlyDayLabel: today/tomorrow/yesterday/'N일 지남' with a fixed `now`.
- widget test (optional): a task due today shows '오늘'.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Do NOT change the stored timeLabel or repo _timeLabel; derive labels for display only.
- Behavior-preserving: keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
