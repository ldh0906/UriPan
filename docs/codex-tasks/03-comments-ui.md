Task 03 — Comments: detail-sheet thread UI + wiring + card badge (UriPan Flutter, cwd C:\UriPan). Depends on tasks 01 + 02. Non-realtime in this task (realtime is task 04).

Goal: users can read, write, and delete comments from the item detail sheet, and see a comment-count badge on cards. Wire it through the existing callback-injection pattern with a repository fallback.

Read first: lib/widgets/item_detail_sheet.dart (current ItemDetailSheet — stateless, callback params onToggle/onConfirm/onEdit/onDelete), lib/widgets/board_item_card.dart (card chips/badges), lib/widgets/common_widgets.dart (MemberAvatar, EmptyState, InfoChip), lib/screens/today_board_screen.dart (`_showItemDetail`, `_deleteItem` confirm-dialog pattern, repository fallback in `_toggleTask`/`_confirmNotice`, the onCompleteTask/onConfirmNotice/onDeleteItem callback fields), lib/screens/board_home_screen.dart (`_runAction`, `_friendlyDatabaseError`, callbacks passed to TodayBoardScreen, `widget.client.auth.currentUser`), lib/services/board_session_controller.dart, lib/services/board_repository.dart (loadComments/addComment/deleteComment from task 02), docs/superpowers/specs/2026-06-02-item-comments-design.md.

IMPLEMENT:
1. New widget lib/widgets/comment_thread.dart — `CommentThread` (StatefulWidget):
   - Params: `required Future<List<BoardComment>> Function() loadComments`, `required Future<void> Function(String body) onAddComment`, `required Future<void> Function(BoardComment comment) onDeleteComment`, `required String? currentUserId`, `bool isAdmin = false`.
   - On init: load comments into state (guard with mounted; show a small loading state while first load runs).
   - List: each comment row = MemberAvatar(displayName: authorName, avatarColor: authorAvatarColor) + author name + body + friendlyRelativeTime(createdAt). Empty → EmptyState with '아직 코멘트가 없어요.' (아직 코멘트가 없어요.)
   - Input: a TextField (hint '코멘트 입력' / 코멘트 입력) + send IconButton. Trim; block empty; max length 1000. On send: call onAddComment(body), clear the field, then reload comments. Disable send while a send is in-flight.
   - Delete: show a delete affordance only when `currentUserId == comment.authorId || isAdmin`. On tap → confirmation dialog ('코멘트 삭제' title, body asks to delete, 취소/삭제 actions using \u escapes) → onDeleteComment(comment) → reload. Wrap add/delete in try/catch so a failure shows a friendly message inline and never throws into the UI.
   - All new Korean strings use \u escapes.
2. lib/widgets/item_detail_sheet.dart: add optional params to ItemDetailSheet — `Future<List<BoardComment>> Function()? loadComments`, `Future<void> Function(String body)? onAddComment`, `Future<void> Function(BoardComment comment)? onDeleteComment`, `String? currentUserId`, `bool isAdmin = false`. When loadComments/onAddComment/onDeleteComment are all non-null, render a `CommentThread` at the bottom of the sheet (after the existing actions). Keep ItemDetailSheet otherwise unchanged (it can stay StatelessWidget and host the stateful CommentThread).
3. lib/screens/today_board_screen.dart:
   - Add optional callback fields mirroring the existing ones: `Future<List<BoardComment>> Function(BoardItem item)? loadComments`, `Future<void> Function(BoardItem item, String body)? onAddComment`, `Future<void> Function(BoardComment comment)? onDeleteComment`.
   - In `_showItemDetail`, pass to ItemDetailSheet: loadComments (bound to that item), onAddComment (bound to that item), onDeleteComment, currentUserId: widget.currentUserId, isAdmin: widget.board?.isAdmin == true. Provide the same repository-fallback behavior used by `_toggleTask`/`_confirmNotice` (when the callbacks are null but `widget.repository` exists, call the repository directly).
4. lib/screens/board_home_screen.dart:
   - Add controller-backed handlers and pass them to TodayBoardScreen: loadComments(item) → `_controller`/repository `loadComments(item.id)`; onAddComment(item, body) → wrapped in `_runAction` → `widget.repository.addComment(item.id, body)`; onDeleteComment(comment) → wrapped in `_runAction` → `widget.repository.deleteComment(comment.id)`. Use the existing `_friendlyDatabaseError` mapping path for errors. (If BoardSessionController is the right home for these, add thin methods there mirroring its existing action methods; otherwise call the repository directly via the screen — match whatever pattern the existing comment-free actions use.)
5. lib/widgets/board_item_card.dart: when `item.commentCount > 0`, show a small badge/chip like `💬 ${item.commentCount}` (💬 N) using the existing chip styling. Do not show it when 0.

TESTS (keep ALL existing green):
- Widget: CommentThread renders provided comments (author name + body visible), shows EmptyState when empty, calls onAddComment with typed text on send, and shows the delete confirmation dialog then calls onDeleteComment (use fake callbacks recording calls; currentUserId matching the comment author so delete is visible).
- Widget: a BoardItemCard with commentCount > 0 shows the 💬 badge; commentCount 0 does not.
- Existing tests stay green (the new ItemDetailSheet params are optional; default detail-sheet usage unchanged).

## Rules
- Korean UI text uses \u escapes in new .dart strings.
- Comment delete needs a confirmation dialog AND friendly Korean error mapping.
- Scheduling/network failures must never throw into the UI; guard them.
- Behavior-preserving: add OPTIONAL params, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
