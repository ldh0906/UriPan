Task 01 — Real author & assignee display names on board items (UriPan Flutter, cwd C:\UriPan).

Today SupabaseBoardRepository._itemFromRow hardcodes `owner: '우리'`. Replace that with the real creator's display name, and surface the assignee's name. Client-side Dart only.

Read first: lib/services/board_repository.dart, lib/models/board_item.dart, lib/widgets/item_detail_sheet.dart, lib/widgets/board_item_card.dart, test/widget_test.dart, test/board_session_controller_test.dart.

BACKEND FACTS (do not change SQL): board_items.created_by and board_items.assigned_to reference auth.users(id). public.profiles has (id -> auth.users(id), display_name, avatar_color). There is NO direct foreign key from board_items to profiles, so PostgREST cannot auto-embed profiles into a board_items select. You must fetch names with a SECOND query against profiles using the user ids.

IMPLEMENT:
1. lib/models/board_item.dart — add fields `createdById` (String?), `assignedToId` (String?), `assigneeName` (String?). Keep `owner` (it becomes the creator's display name). Add them to the constructor with defaults and to `copyWith`.
2. lib/services/board_repository.dart (SupabaseBoardRepository):
   - Add `created_by, assigned_to` to every board_items select (loadBoardItems, createItem, updateItem) and ensure complete_task/confirm flows still map.
   - Add a private helper `Future<Map<String,String>> _displayNames(Set<String> userIds)` that returns {} for empty input, else `from('profiles').select('id, display_name').inFilter('id', userIds.toList())` mapped to id->display_name.
   - In loadBoardItems: after fetching rows, gather all non-null created_by + assigned_to ids, call _displayNames once, then build each BoardItem with owner = names[created_by] ?? '우리', assigneeName = assigned_to == null ? null : names[assigned_to].
   - For single-row paths (createItem/updateItem), look up the needed 1–2 names with the same helper.
   - _itemFromRow should accept the names map (or take owner/assigneeName as params) instead of hardcoding '우리'.
3. MemoryBoardRepository — keep owner meaningful (e.g. '우리'); carry draft.assignedTo into createItem as assignedToId (assigneeName may stay null in memory). updateItem keeps the fields via copyWith.
4. lib/widgets/item_detail_sheet.dart — if assigneeName != null, show an assignee chip/line meaning "담당: <name>" (Korean as \u escapes). Card already shows owner; leave it.

TESTS (you may edit test/):
- A board_session_controller_test using MemoryBoardRepository: an item created with draft.assignedTo set keeps assignedToId after reload.
- A widget_test: pump TodayBoardScreen with a BoardItem that has assigneeName set, open its detail sheet, assert the assignee text appears.
- Keep all existing tests green.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Behavior-preserving: add OPTIONAL params, never remove/rename existing public APIs, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`  (fix lints; add super.key to any new public widget)
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`  (all green; do not delete existing tests)

## Report
Files changed with line counts, Korean strings introduced (as \u escapes), tests added, and which verify commands passed.
