Task 02 — Members tab shows the real member list (UriPan Flutter, cwd C:\UriPan). Depends on task 01.

Today the Members area (MembersPanel, now in lib/widgets/board_header.dart) only shows a count and an invite button. Make it a real member list with names, roles, avatars, and capacity. Client-side Dart only.

Read first: lib/widgets/board_header.dart, lib/services/board_repository.dart, lib/services/board_session_controller.dart, lib/models/board_item.dart, lib/widgets/common_widgets.dart, lib/screens/board_home_screen.dart, lib/screens/today_board_screen.dart, test/board_session_controller_test.dart, test/widget_test.dart.

BACKEND FACTS (do not change SQL): board_members(board_id, user_id, role, joined_at). profiles(id, display_name, avatar_color). board_members.user_id references auth.users; profiles.id references auth.users — no direct FK, so fetch names/colors with a second profiles query (same pattern as task 01).

IMPLEMENT:
1. lib/models/board_item.dart (or a new lib/models/board_member.dart) — add `BoardMember { String userId; String displayName; String avatarColor; String role; DateTime joinedAt; bool get isAdmin => role == 'admin'; }`.
2. board_repository.dart — add `Future<List<BoardMember>> loadMembers(String boardId)`. Supabase: select user_id, role, joined_at from board_members for the board, then fetch profiles(id, display_name, avatar_color) for those user ids and combine; order admins first then joined_at. Memory: return 1–3 believable sample members.
3. board_session_controller.dart — load members for the active board during load() and on handleBoardMembershipChanged(); expose `List<BoardMember> get members`. Guard with the existing stale-request pattern.
4. lib/widgets/common_widgets.dart — if not present, add small widgets: `MemberAvatar` (circle with initials + avatar_color), `RoleChip` (admin/member, Korean), `CapacityChip` (count/max). Reuse AppColors/DESIGN tokens.
5. lib/widgets/board_header.dart MembersPanel — render the member list (avatar + name + role chip), a capacity chip (memberCount/maxMembers), and keep the admin-only invite button. Accept the members list via a new optional param; board_home_screen passes controller.members through TodayBoardScreen (add an optional `members` param to TodayBoardScreen, do not break existing usages).

TESTS:
- controller test: loadMembers via MemoryBoardRepository populates `members`.
- widget test: MembersPanel (or Members tab) shows a member name and role.
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
