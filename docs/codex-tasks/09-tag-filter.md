Task 09 — Tap a tag to filter (UriPan Flutter, cwd C:\UriPan).

Read first: lib/screens/today_board_screen.dart, lib/widgets/board_item_card.dart (TagChip, BoardItemSection, BoardItemCard), lib/models/board_item.dart, test/widget_test.dart.

GOAL: tapping a tag chip filters the current tab to items carrying that tag, with a clear way to reset.

IMPLEMENT:
1. lib/widgets/board_item_card.dart — give `TagChip` an optional `VoidCallback? onTap` (wrap in InkWell when set; keep visuals). Pass an onTap from BoardItemCard's tag chips up via an optional `ValueChanged<String>? onTagTap` on BoardItemCard and BoardItemSection.
2. today_board_screen.dart — hold `String? _activeTag` in state. Pass `onTagTap: (tag) => setState(() => _activeTag = tag)` into the sections. When `_activeTag != null`, filter the items shown in the CURRENT tab to those whose tags contain it.
3. Show an active-filter indicator (e.g. an InputChip '#<tag>' with a delete X) above the sections when `_activeTag != null`; deleting it clears the filter.
4. Keep it independent of search (task 08): if both exist, tag filter applies within the current tab; do not over-engineer the interaction.

TESTS (keep all existing green):
- widget test: with two tasks where only one has tag 'School', tapping that tag chip filters to the tagged item; clearing the filter chip restores both.

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
