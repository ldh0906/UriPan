# UriPan Memory

Updated: 2026-05-30

## Current State

- UriPan is a Flutter family-board app backed by Supabase when `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` are provided, with an in-memory fallback when config is missing.
- `main.dart` is now a small entrypoint/Supabase bootstrap. The previous large main file was split into app, auth, board home, board screen, realtime, sheets, state screens, and controller files.
- `BoardSessionController` owns board loading, active board selection, item reloads, action refreshes, and Realtime-triggered refreshes.
- Supabase flow includes auth, board creation, invite creation/join, item creation, task completion, RLS/RPC hardening, and Realtime publication coverage.
- Functional tabs exist for Today, Calendar, Tasks, Notices, and Members.
- Add action is in the header, not overlapping the bottom nav.
- Schedule/task creation has date/time controls.
- `BoardItem` preserves `startsAt` and `dueAt`; Today filters schedules/tasks by date.
- Item cards open a detail sheet. Tasks support complete/undo with pending UI and completed styling.
- Fallback/mock mode preserves dates and uses the resolved board id consistently.
- Repository item loading is now named `loadBoardItems` instead of `loadTodayItems`.
- `BoardSessionController` ignores stale load/refresh results when newer board or Realtime requests have started.
- Header refresh UI is visible and wired to board reload.
- Board creation and item creation show client-side errors for empty names/titles.
- Item detail supports delete with confirmation, repository deletion, controller reload, and tests.
- Items now support user-entered manual tags:
  - `BoardItem.tags` and `BoardItemDraft.tags`
  - tag input/preview chips in `AddItemSheet`
  - tag chips on cards and detail sheets
  - Supabase `board_items.tags text[]` migration

## Latest Verification

Last full local verification passed after the latest refactor and feature work:

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `git diff --check`

Flutter/Dart commands may need sandbox escalation because SDK/cache files live under the user profile.

## Key Files

- `lib/main.dart`: entrypoint and Supabase bootstrap
- `lib/app.dart`: app shell
- `lib/screens/auth_gate.dart`: auth routing
- `lib/screens/login_screen.dart`: login/signup UI
- `lib/screens/board_home_screen.dart`: board-level controller ownership and actions
- `lib/screens/today_board_screen.dart`: tabbed board UI
- `lib/services/board_session_controller.dart`: board/item state flow
- `lib/services/board_realtime_subscription.dart`: Realtime subscription wrapper
- `lib/services/board_repository.dart`: Supabase and memory repositories
- `lib/widgets/board_action_sheets.dart`: create/join/invite/add/detail sheets
- `lib/widgets/common_widgets.dart`: shared board widgets and tab nav
- `test/board_session_controller_test.dart`: controller tests
- `test/widget_test.dart`: widget tests

## Remaining Work

1. Run live Supabase two-session browser QA after the latest tab/date/detail changes.
2. Complete notice confirmation end to end:
   - model fields,
   - repository reads/RPC,
   - card/detail confirmation UI,
   - Realtime update,
   - tests.
3. Add missing `BoardItem` server metadata:
   - `boardId`,
   - `assignedTo`,
   - `createdBy`,
   - display names,
   - confirmation count,
   - current-user confirmation state.
4. Add stronger date/time policy validation for schedules and tasks.
5. Add item edit from detail.
6. QA live timezone/date persistence plus Supabase delete/tag behavior.

## Project Notes

- Do not touch `README.md` unless the user explicitly asks.
- Keep exploration output small; prefer targeted `rg` and capped reads.
- Use `apply_patch` for manual file edits.
- Do not revert user or generated changes unless explicitly requested.
- The app may have many uncommitted implementation files; check `git status --short` before changing scope.
