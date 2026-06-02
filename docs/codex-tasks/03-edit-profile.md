Task 03 — Edit my profile: display name + avatar color (UriPan Flutter, cwd C:\UriPan). Depends on task 01.

Read first: lib/services/board_repository.dart, lib/services/board_session_controller.dart, lib/screens/board_home_screen.dart, lib/widgets/board_settings_sheet.dart (task 01), lib/widgets/common_widgets.dart (MemberAvatar, _avatarColorFromHex), lib/models/board_item.dart, test/board_session_controller_test.dart, test/widget_test.dart.

BACKEND FACTS (do not change SQL): table `public.profiles(id, display_name (1..60), avatar_color text hex)`. RLS already allows `profiles_update_own` and selecting your own profile. No SQL changes.

IMPLEMENT:
1. lib/models/board_item.dart — add a small `UserProfile { final String id; final String displayName; final String avatarColor; }` (const constructor). (Same file is fine, mirroring BoardInvite/BoardMember.)
2. board_repository.dart:
   - abstract: `Future<UserProfile?> loadMyProfile() async => null;` and `Future<UserProfile> updateMyProfile({String? displayName, String? avatarColor}) { throw UnimplementedError(); }`.
   - SupabaseBoardRepository: loadMyProfile selects id, display_name, avatar_color from profiles where id == currentUser.id (limit 1, null if none). updateMyProfile updates only the provided fields where id == currentUser.id and returns the refreshed UserProfile.
   - MemoryBoardRepository: keep a stored `UserProfile` (default id 'memory-user-1', name '지우', color '#647D31'); loadMyProfile returns it; updateMyProfile mutates and returns it.
3. board_session_controller.dart — expose `UserProfile? get myProfile`; load it inside `load()` (alongside boards/items); add `Future<void> updateMyProfile({String? displayName, String? avatarColor})` via `_runAction` that updates the repo then stores the result and notifies.
4. UI — a profile edit sheet reachable from the settings sheet (task 01). Add an optional "내 정보" / profile row to BoardSettingsSheet that calls an `onEditProfile` callback. The edit sheet: a display-name TextField (trim; inline Korean error if empty or >60 chars), an avatar color picker from a small fixed palette (reuse the hex style, e.g. ['#647D31','#E7A14B','#4B7BE7','#C2497A','#3FA796','#8A6FE0']) with the current one selected, and a save button → controller.updateMyProfile. A live MemberAvatar preview is a nice touch.

TESTS (keep all existing green):
- controller test (memory): updateMyProfile changes displayName and avatarColor; loadMyProfile reflects it after load().
- widget test: the profile edit sheet shows the current name and, on save with a new name, calls the update callback / pops a result.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Behavior-preserving: add OPTIONAL params, never remove/rename existing public APIs, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
