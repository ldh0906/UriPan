Task 15 — Accessibility pass (UriPan Flutter, cwd C:\UriPan).

Read first: lib/widgets/common_widgets.dart (AppBottomNav InkWell tabs, AddItemFab), lib/widgets/board_item_card.dart (TagChip, card onTap), lib/screens/today_board_screen.dart (_CalendarDayCell InkWell, settings/search icon buttons), lib/widgets/item_detail_sheet.dart, test/widget_test.dart.

GOAL: make icon-only and tap-target-only controls screen-reader friendly and comfortably tappable. Keep visuals unchanged.

IMPLEMENT:
1. Add Semantics labels (or tooltips, which also expose semantics) to icon-only controls that lack them — e.g. the settings and search buttons (tasks 01/08), bottom-nav tabs (label each with its tab name + selected state), tag chips (label '태그 <name>'), and the calendar day cells (label the full date, e.g. '6월 2일 월요일').
2. Ensure interactive controls meet a ~44px minimum tap target (the existing checkbox already uses 44; apply the same care to new InkWell/IconButton controls).
3. Bottom-nav tabs: wrap each in Semantics(button: true, selected: isSelected, label: tab.label).

TESTS (keep all existing green):
- widget test: key controls expose a semantics label — e.g. `find.bySemanticsLabel` finds the bottom-nav '오늘' tab and the settings control. (Use a regex/label that matches your implementation.)

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Do not change layouts/visuals; only add semantics/labels/tap-target sizing.
- Behavior-preserving: keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
