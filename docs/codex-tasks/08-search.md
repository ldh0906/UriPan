Task 08 — Search items by title / memo / tag (UriPan Flutter, cwd C:\UriPan).

Read first: lib/screens/today_board_screen.dart, lib/widgets/board_header.dart, lib/widgets/board_item_card.dart (BoardItemSection), lib/models/board_item.dart, test/widget_test.dart.

GOAL: let users find an item across all types without scrolling tabs.

IMPLEMENT:
1. A pure, testable matcher — `bool boardItemMatchesQuery(BoardItem item, String query)` (put it near the model, e.g. a top-level function in lib/models/board_item.dart or lib/services/board_search.dart). Case-insensitive, trims the query, matches if the query is contained in title, detail, owner, assigneeName, or any tag. Empty/whitespace query returns true.
2. today_board_screen.dart — add a search affordance: a search IconButton in the header (Icons.search_rounded, tooltip '검색') that toggles a search TextField shown directly under the header. Hold `_searchQuery` in state with a clear (X) button.
3. When `_searchQuery` is non-empty, REPLACE the current tab body with a single flat result section (reuse BoardItemSection, title '검색 결과') listing every displayed item matching the query (all types), tappable to open detail. Empty state: '검색 결과가 없어요.'. When the query is empty, the normal tabs render unchanged.

TESTS (keep all existing green):
- unit tests for boardItemMatchesQuery (title hit, tag hit, miss, empty query == true).
- widget test: type a query that matches one item's title -> only that item shows under '검색 결과'; a non-matching item is hidden.

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
