Task 01 — Settings sheet + sign out from inside a board (UriPan Flutter, cwd C:\UriPan).

PROBLEM: once you are in a board you cannot sign out — sign-out only exists on NoBoardScreen / BoardLoadErrorScreen. There is no settings entry point. This task adds one and is the foundation for tasks 02/03/04.

Read first: lib/screens/board_home_screen.dart, lib/widgets/board_header.dart, lib/screens/today_board_screen.dart, lib/screens/auth_gate.dart, lib/widgets/common_widgets.dart, test/widget_test.dart.

BACKEND FACTS (do not change SQL): sign out = `client.auth.signOut()`. AuthGate is a StreamBuilder on `onAuthStateChange`; after signOut it returns to LoginScreen automatically.

IMPLEMENT:
1. New file lib/widgets/board_settings_sheet.dart — `BoardSettingsSheet`, a modal bottom-sheet body. For THIS task it shows: the active board name + the current user's display name (pass them in), and a "로그아웃" (로그아웃) row that calls an `onSignOut` callback. Add a `showBoardSettingsSheet(context, {required String boardName, String? userName, required VoidCallback onSignOut})` helper using showModalBottomSheet (showDragHandle: true). Keep it minimal — do NOT add dead buttons for features that land in later tasks.
2. lib/widgets/board_header.dart — add an optional `VoidCallback? onOpenSettings`; when non-null render a settings IconButton (Icons.settings_outlined, tooltip '설정') in the header trailing controls. Keep the existing refresh / invite / add controls and their tooltips working.
3. lib/screens/today_board_screen.dart — add optional `final VoidCallback? onOpenSettings;` and forward it to BoardHeader.
4. lib/screens/board_home_screen.dart — pass `onOpenSettings: _openSettings`; `_openSettings()` opens the sheet with the active board name and `client.auth.currentUser?.userMetadata?['display_name']` or the matching member display name (use the current user's BoardMember displayName if available, else null), and `onSignOut: () { Navigator.pop(context); widget.client.auth.signOut(); }`.

TESTS (add to test/widget_test.dart; keep all existing green):
- widget test: pump TodayBoardScreen with `onOpenSettings` set, tap the settings control (by tooltip '설정'), and assert the callback fired.
- widget test: pump `BoardSettingsSheet` (or showBoardSettingsSheet) directly, assert it shows '로그아웃', tap it, assert onSignOut fired.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Behavior-preserving: add OPTIONAL params, never remove/rename existing public APIs, keep ALL existing tests green.
- Watch header layout — do not break the existing '새로고침' tooltip or '추가' button that existing tests rely on.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
