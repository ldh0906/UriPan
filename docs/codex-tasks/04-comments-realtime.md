Task 04 — Comments: live thread subscription while the detail sheet is open (UriPan Flutter, cwd C:\UriPan). Depends on tasks 01–03.

Goal: when two members view the same item, a new (or deleted) comment appears in the open thread without a manual refresh — like a chat. Only the currently-open item's comments are subscribed; the subscription is released when the sheet closes. Demo/memory mode and all existing tests use no realtime.

Read first: lib/services/board_realtime_subscription.dart (existing channel pattern with `_client.channel(...).onPostgresChanges(... table: 'item_comments' ...)` — note item_comments has NO board_id column, so filter on column 'item_id'), lib/widgets/comment_thread.dart (task 03), lib/widgets/item_detail_sheet.dart, lib/screens/today_board_screen.dart, lib/screens/board_home_screen.dart (owns the SupabaseClient), test/widget_test.dart, docs/superpowers/specs/2026-06-02-item-comments-design.md.

IMPLEMENT:
1. Define a subscribe contract: a function type `typedef CommentSubscription = void Function() Function(String itemId, void Function() onChanged);` (calling it subscribes and returns a dispose callback). Put the typedef somewhere sensible (e.g. top of comment_thread.dart).
2. board_home_screen.dart: implement a subscribe function using `widget.client` that opens a realtime channel (e.g. 'item-comments:<itemId>') listening to PostgresChangeEvent.all on table 'item_comments' filtered by column 'item_id' == itemId, calling onChanged on any event; the returned dispose removes the channel. Pass this down as an optional `CommentSubscription? subscribeComments` through TodayBoardScreen → ItemDetailSheet → CommentThread. In demo/memory mode and tests it is null.
3. CommentThread: accept optional `CommentSubscription? subscribeComments`. On init, if non-null, subscribe(itemId, () => reload comments) and store the dispose callback; call it in dispose(). Guard reloads with mounted. If null, behave exactly as task 03 (no realtime).

TESTS (keep ALL existing green):
- Widget: pass a fake `subscribeComments` that captures the onChanged callback; after the thread mounts, invoke onChanged and assert loadComments is called again (the thread reloads). Assert the dispose callback is invoked when the widget is removed.
- Existing tests still pass with subscribeComments null (no realtime, no plugin/client touched).

## Rules
- Client+Supabase only; FCM push is Phase B (do NOT add it).
- Realtime must never throw into the UI; guard it. Always release the channel on dispose.
- Behavior-preserving: add OPTIONAL params, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, tests added, and which verify commands passed. Note that true end-to-end realtime delivery needs two real clients to confirm.
