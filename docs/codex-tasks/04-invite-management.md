Task 04 — Invite management: copy / regenerate / revoke (UriPan Flutter, cwd C:\UriPan). Depends on task 02.

Today admins can only CREATE an invite (a dialog shows the code once). Add a proper invite panel in Members. Client-side Dart only.

Read first: lib/services/board_repository.dart, lib/services/board_session_controller.dart, lib/screens/board_home_screen.dart, lib/widgets/board_header.dart, lib/models/board_item.dart, test/board_session_controller_test.dart, test/widget_test.dart.

BACKEND FACTS (do not change SQL): RPCs exist — create_board_invite (creating a new one revokes the previous active invite), revoke_board_invite(target_invite_id). board_invites is admin-selectable: columns id, code, expires_at, revoked_at. One active (unrevoked) invite per board.

IMPLEMENT:
1. board_repository.dart:
   - `Future<BoardInvite?> loadActiveInvite(String boardId)` — Supabase: select id, code, expires_at from board_invites where board_id = boardId and revoked_at is null and expires_at > now(), newest first, limit 1 (return null if none). Memory: return a stored invite or null.
   - `Future<void> revokeInvite(String inviteId)` — Supabase RPC revoke_board_invite. Memory: clear stored invite.
   - createInvite already exists (use it for regenerate).
2. board_session_controller.dart — expose `BoardInvite? get activeInvite`; load it on load() when the active board is admin; `regenerateInvite()` (calls createInvite) and `revokeInvite()` updating state.
3. lib/widgets/board_header.dart (or a new InviteCodePanel widget) — admin-only panel in Members showing: current code (SelectableText) + expiry, a Copy button (Clipboard.setData), Regenerate, and Revoke. States: no active invite ("초대코드 없음" + 만들기), code present, full board (disable regenerate when memberCount >= maxMembers, with a hint). Non-admins see nothing invite-related.
4. board_home_screen.dart — wire regenerate/revoke through _runAction with the existing friendly error mapping.

TESTS:
- controller test (memory): regenerateInvite sets activeInvite; revokeInvite clears it.
- widget test: the invite panel shows a code and a copy affordance for an admin board.
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
