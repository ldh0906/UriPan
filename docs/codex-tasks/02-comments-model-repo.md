Task 02 — Comments: model + repository CRUD + friendly relative time (UriPan Flutter, cwd C:\UriPan). Depends on task 01.

Goal: the data layer for comments — a model, repository methods on BOTH implementations, comment-count plumbing, and a pure relative-time formatter. No UI in this task.

Read first: lib/models/board_item.dart (model patterns, copyWith on BoardItem), lib/services/board_repository.dart (abstract BoardRepository + MemoryBoardRepository + SupabaseBoardRepository; study confirmNotice/deleteItem and `_itemSelectColumns`, `_itemFromRow`, `_displayNames`/`_profiles` helpers), lib/services/friendly_date.dart (friendlyDayLabel style), docs/superpowers/specs/2026-06-02-item-comments-design.md.

IMPLEMENT:
1. lib/models/board_item.dart:
   - New class `BoardComment` with fields: String id; String itemId; String authorId; String authorName; String authorAvatarColor; String body; DateTime createdAt. Const constructor, all required. (Match the style of the other models in this file.)
   - Add `final int commentCount;` to BoardItem (default 0 in the constructor) and include it in `copyWith` (new optional `int? commentCount`). Additive only — every existing call site must keep compiling.
2. lib/services/friendly_date.dart:
   - Add `String friendlyRelativeTime(DateTime when, {DateTime? now})` returning Korean labels using \u escapes:
     - < 60s: '방금' (방금)
     - < 60m: 'N분 전' (N분 전)
     - < 24h: 'N시간 전' (N시간 전)
     - yesterday (calendar day = today-1): '어제' (어제)
     - else: 'M.D' (e.g. '6.2') from the local date
   - Pure function (no Flutter imports). Compute against `now ?? DateTime.now()`, compare in local time.
3. lib/services/board_repository.dart:
   - Abstract BoardRepository: add
     - `Future<List<BoardComment>> loadComments(String itemId) async => const [];`
     - `Future<BoardComment> addComment(String itemId, String body) { throw UnimplementedError(); }`
     - `Future<void> deleteComment(String commentId) { throw UnimplementedError(); }`
   - MemoryBoardRepository: keep an in-memory `List<BoardComment>`. addComment creates a BoardComment (id 'memory-comment-N', author from `_myProfile` id/displayName/avatarColor, createdAt now) and returns it; loadComments returns the comments for that itemId sorted by createdAt ascending; deleteComment removes by id (throw StateError if absent). Keep returned lists unmodifiable like the others.
   - SupabaseBoardRepository:
     - loadComments(itemId): select 'id, item_id, author_id, body, created_at' from 'item_comments' where item_id eq, order created_at ascending; resolve author display_name + avatar_color via a profiles lookup (reuse/extend the existing `_profiles` helper which already returns display_name + avatar_color); map rows to BoardComment (fallback name = authorId, fallback color '#647D31').
     - addComment(itemId, body): insert {'item_id': itemId, 'author_id': currentUser.id, 'body': body} into 'item_comments', select the row back, then resolve the author profile and return a BoardComment.
     - deleteComment(commentId): delete from 'item_comments' where id eq commentId.
     - Comment count: append `, item_comments(count)` to `_itemSelectColumns`, and in `_itemFromRow` parse it into `commentCount` (PostgREST returns it as a list like `[{'count': N}]`; read the first element's 'count' as int, default 0). Set `commentCount:` on the returned BoardItem.

TESTS (keep ALL existing green):
- Unit: friendlyRelativeTime for 방금 / N분 전 / N시간 전 / 어제 / M.D (pass an explicit `now`).
- Unit: MemoryBoardRepository comment CRUD — addComment then loadComments returns it; multiple comments come back sorted ascending by createdAt; deleteComment removes it; loadComments for an unrelated itemId returns empty.

## Rules
- Korean UI text uses \u escapes. Pure Dart for friendly_date (no platform/SQL).
- Behavior-preserving: additive only (new methods have safe defaults; commentCount defaults 0), keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
