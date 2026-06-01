Task 05 — A member can leave the board (UriPan Flutter, cwd C:\UriPan). Depends on task 02.

Read first: lib/services/board_repository.dart, lib/services/board_session_controller.dart, lib/screens/board_home_screen.dart, lib/widgets/board_header.dart, test/board_session_controller_test.dart.

BACKEND FACTS (do not change SQL): board_members delete policy allows a user to delete their OWN membership. A DB trigger raises `creator_admin_required` / `last_admin_required` if the board creator or the last admin tries to leave.

IMPLEMENT:
1. board_repository.dart — `Future<void> leaveBoard(String boardId)`. Supabase: delete from board_members where board_id = boardId and user_id = currentUser.id. Memory: remove the active board / membership.
2. board_session_controller.dart — `Future<void> leaveBoard()` that calls the repo then reloads (active board becomes the next board or null).
3. lib/widgets/board_header.dart MembersPanel — add a "보드 나가기" button (Korean, \u escapes) with a confirmation dialog. Wire via a new optional callback through TodayBoardScreen to board_home_screen.
4. board_home_screen.dart — `_leaveBoard()` wrapped in _runAction; extend the friendly error map so `creator_admin_required` and `last_admin_required` show clear Korean messages (e.g. "관리자는 보드를 나갈 수 없어요").

TESTS:
- controller test (memory): leaveBoard removes the membership / clears the active board.
- Keep all existing tests green.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Behavior-preserving: add OPTIONAL params, never remove/rename existing public APIs, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
