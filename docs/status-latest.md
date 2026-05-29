# UriPan latest status

Updated: 2026-05-30

## Current state

- Flutter SDK is installed at `C:\Users\a3030\development\flutter`.
- The app has been refactored away from a large `main.dart`; app bootstrap, auth gate, login, board home, board screen, action sheets, state screens, Realtime subscription, and board session control now live in focused files.
- `BoardSessionController` is the central state flow for boards, active board, items, action refreshes, and Realtime-triggered reloads.
- Supabase mode uses repository-backed item creation, task completion, board loading, invites, and Realtime refreshes.
- The no-Supabase fallback remains useful for local UI testing and now preserves schedule/task date fields.
- Bottom tabs are functional for Today, Calendar, Tasks, Notices, and Members.
- Schedule/task add flows include date/time controls.
- Item cards open detail sheets; task details and cards support complete/undo with pending UI.
- The add button was moved out of the bottom-nav overlap area.

## Latest verification

The latest full local verification passed after the current refactor and UI/data-flow work:

- `dart format lib test`
- `flutter analyze`
- `flutter test`
- `git diff --check`

## Live Supabase status

- Previous live REST smoke passed for signup, board creation, admin invite creation, invite join, item creation, task completion, non-member board isolation, and non-admin invite denial.
- Live Supabase migrations and hardening already applied include trigger-function privilege locking and Realtime publication coverage for board membership, items, and confirmations.
- Live two-session browser QA still needs to be rerun after the latest tab/date/detail changes.

## Open product/engineering gaps

- Notice confirmation is not yet complete in the UI or model/repository read path.
- `BoardItem` still needs server metadata for board id, assignee, creator, display names, confirmation count, and current-user confirmation state.
- `loadTodayItems` should be renamed or split because all tabs currently depend on it for the full board item list.
- Manual refresh exists as a callback but has no visible UI.
- Async and Realtime refreshes need stale-result protection.
- Item detail still lacks edit/delete.
- Form validation and live timezone/date persistence QA need more work.

## Next recommended work

1. Clean the item-loading repository contract and controller stale-result handling.
2. Implement notice confirmation end to end.
3. Add refresh UI, stronger form validation, and edit/delete item actions.
4. Run two-session Supabase browser QA for Realtime sync and date/time behavior.
