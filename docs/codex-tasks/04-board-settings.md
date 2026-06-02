Task 04 — Board settings: rename + max members (admin) (UriPan Flutter, cwd C:\UriPan). Depends on task 01.

Read first: lib/services/board_repository.dart, lib/services/board_session_controller.dart, lib/screens/board_home_screen.dart (_friendlyDatabaseError, _runAction), lib/widgets/board_settings_sheet.dart (task 01), lib/models/board_item.dart (BoardSummary), test/board_session_controller_test.dart.

BACKEND FACTS (do not change SQL): RLS `boards_update_admins` lets an admin UPDATE name / max_members. Triggers: `max_members_below_current_count` (cannot set the limit below the current member count) and `board_identity_immutable`. name is 1..80, max_members 2..20.

IMPLEMENT:
1. board_repository.dart:
   - abstract: `Future<BoardSummary> updateBoard(String boardId, {String? name, int? maxMembers}) { throw UnimplementedError(); }`.
   - Supabase: update only the provided fields on boards where id == boardId, return a refreshed BoardSummary (re-select with board_members(user_id) to recompute memberCount, role stays the caller's current role — reuse the existing loadBoards mapping shape).
   - Memory: replace the matching board in `_boards` with an updated copy (keep role/memberCount).
2. board_session_controller.dart — `Future<void> updateBoard({String? name, int? maxMembers})` on the active board via `_runAction`, then `await load(preferredBoardId: activeBoard!.id)` so the new name/limit propagate.
3. UI — an admin-only "보드 설정" entry in the settings sheet that opens an edit sheet: name TextField (1..80, inline Korean error) and a max-members stepper/slider (min = current memberCount, max 20). Non-admins do not see it.
4. board_home_screen.dart `_friendlyDatabaseError` — add `max_members_below_current_count` -> '정원을 현재 인원보다 적게 둘 수 없어요.' (정원을 현재 인원보다 적게 둘 수 없어요.)

TESTS (keep all existing green):
- controller test (memory): updateBoard changes name and maxMembers on the active board.
- widget test: the board settings edit sheet shows the current name and saves a new one (callback / pop result).

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
