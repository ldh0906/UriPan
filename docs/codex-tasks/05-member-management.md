Task 05 — Member management: promote / demote / remove (admin) (UriPan Flutter, cwd C:\UriPan).

Read first: lib/services/board_repository.dart, lib/services/board_session_controller.dart, lib/screens/board_home_screen.dart (_friendlyDatabaseError, _runAction, _leaveBoard wiring), lib/widgets/board_header.dart (MembersPanel, _MemberRow), lib/screens/today_board_screen.dart, lib/models/board_item.dart (BoardMember), test/board_session_controller_test.dart.

BACKEND FACTS (do not change SQL): RLS `board_members_update_admins` (admin may change a member's role), `board_members_delete_admin_or_self` (admin may remove anyone, a user may remove themselves). Triggers raise: `creator_admin_required` (the board creator cannot be demoted/removed), `last_admin_required` (cannot remove/demote the last admin), `membership_identity_immutable`. Role is 'admin' | 'member'.

IMPLEMENT:
1. board_repository.dart:
   - abstract: `Future<void> updateMemberRole(String boardId, String userId, String role) { throw UnimplementedError(); }` and `Future<void> removeMember(String boardId, String userId) { throw UnimplementedError(); }`.
   - Supabase: update board_members.role where board_id & user_id; delete board_members where board_id & user_id.
   - Memory: mutate `_members` (change role / removeWhere).
2. board_session_controller.dart — `Future<void> updateMemberRole(String userId, String role)` and `Future<void> removeMember(String userId)` on the active board via `_runAction`, then reload members (`await load(preferredBoardId: activeBoard!.id)` or refresh members).
3. UI — in MembersPanel `_MemberRow`, when the current viewer is an admin show a trailing overflow menu (PopupMenuButton) per member: '관리자로' (promote, if member), '멤버로' (demote, if admin), '내보내기' (remove). Each destructive action shows a confirm dialog first. Do not show the menu for the current user themselves (they use 보드 나가기). Wire callbacks up through MembersPanel -> TodayBoardScreen (new optional callbacks) -> board_home_screen. You will need to pass the current user id and isAdmin into MembersPanel (TodayBoardScreen already has currentUserId; board.isAdmin is available).
4. board_home_screen.dart `_friendlyDatabaseError` — ensure `creator_admin_required` -> '보드를 만든 사람은 바꿀 수 없어요.' and `last_admin_required` -> '마지막 관리자는 바꿀 수 없어요.' are present (some already exist for leave — reuse / keep wording consistent).

TESTS (keep all existing green):
- controller test (memory): updateMemberRole changes a member's role; removeMember drops them from members.
- widget test: an admin viewer sees the per-member action menu; a non-admin viewer does not.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Destructive actions need a confirmation dialog AND the friendly Korean error mapping above.
- Behavior-preserving: add OPTIONAL params, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
