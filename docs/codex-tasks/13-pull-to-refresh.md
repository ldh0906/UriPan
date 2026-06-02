Task 13 — Pull-to-refresh (UriPan Flutter, cwd C:\UriPan).

Read first: lib/screens/today_board_screen.dart (build -> CustomScrollView, _refresh, _isRefreshing, widget.onRefresh), lib/screens/board_home_screen.dart (onRefresh: _refresh), test/widget_test.dart.

GOAL: add a familiar pull-to-refresh gesture without removing the existing refresh button.

IMPLEMENT:
1. today_board_screen.dart — wrap the CustomScrollView in a RefreshIndicator whose onRefresh calls the same `_refresh()` path (which already guards on widget.onRefresh == null and the _isRefreshing flag). When `widget.onRefresh == null`, do not attach a refresh action (return Future.value or keep the indicator inert) so memory/demo mode and existing tests are unaffected.
2. Ensure the scroll view always allows overscroll so the gesture works even when content is short (e.g. `physics: const AlwaysScrollableScrollPhysics()` on the CustomScrollView).
3. Keep the header refresh IconButton and its '새로고침' tooltip.

TESTS (keep all existing green):
- widget test: with onRefresh set, a RefreshIndicator is present; triggering it (tester.fling / drag down + pumpAndSettle, or RefreshIndicator show) invokes the onRefresh callback. Keep the existing 'Refresh button calls the board refresh callback' test passing.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Behavior-preserving: keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, tests added, and which verify commands passed.
