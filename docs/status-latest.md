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
- Repository item loading is now named `loadBoardItems` instead of the misleading `loadTodayItems`.
- `BoardSessionController` ignores stale load/refresh results when newer board or Realtime requests have started.
- Header refresh UI is visible and wired.
- Empty board names and empty item titles show client-side validation errors.
- Item detail supports delete with confirmation, repository deletion, controller reload, and tests.
- Manual item tags are implemented with add-sheet input chips, card/detail display, model/repository persistence, and a Supabase `text[]` migration.
- Added `docs/DESIGN.md` using the `@google/design.md` structure: token front matter plus UI/UX rationale for UriPan's warm family-board design system.

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

## Recently completed (2026-06-01)

- `today_board_screen.dart` split into the shell plus `board_item_card.dart`, `item_detail_sheet.dart`, and `board_header.dart` (behavior-preserving refactor; commit `6547cfd`).
- Notice confirmation end to end on the existing backend (commit `8881d98`): `BoardItem` confirmation fields + `copyWith`, repository `confirmNotice` and confirmation reads, controller `confirmNotice`, detail-sheet confirm/undo, card status chip, AddItemSheet "requires confirmation" toggle. 20 tests pass, analyze clean.

## Open product/engineering gaps

- `BoardItem` still needs server metadata for board id, assignee, creator, and real display names (owner is hardcoded to '우리').
- Item detail still lacks edit.
- Date/time policy validation and live timezone/date/tag persistence QA need more work.

## Next recommended work

1. Add item edit actions (title/detail/date/tags from the detail sheet).
2. Fill remaining `BoardItem` server metadata (assignee, creator, display names).
3. Tighten schedule/task date-time policy validation.
4. Keep new UI work aligned with `docs/DESIGN.md`.
5. Run two-session Supabase browser QA for Realtime sync, delete, tags, and date/time behavior.
