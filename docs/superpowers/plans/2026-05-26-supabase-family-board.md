# UriPan Supabase Family Board Implementation Plan

> Source spec: `docs/superpowers/specs/2026-05-26-supabase-family-board-design.md`

## Goal

Build UriPan into a real shared family board on Supabase Free while restoring the warm pre-refactor design style.

## Priority Rationale

The technical meeting ranked work by dependency and family value:

1. Stabilize current app so new work has a healthy base.
2. Harden the old design system into reusable navigation, card, state, permission, invite, and capacity primitives.
3. Scaffold all five tabs lightly so navigation and add-flow problems surface early.
4. Add Supabase schema and RLS before client integration.
5. Build auth/onboarding so real family members can join.
6. Implement shared Today, Tasks, Notices, Calendar, and Members flows.
7. Add Realtime only after core CRUD and security policies work.

## Phase 0: Stabilize Current App

**Files likely touched**

- `README.md`
- `lib/main.dart`
- `lib/screens/today_board_screen.dart`
- `lib/data/seed_data.dart`
- `lib/widgets/section_panel.dart`
- `lib/theme/app_theme.dart`
- `test/widget_test.dart`

**Tasks**

- Restore readable Korean strings.
- Restore the product README from pre-rebuild history, then add current setup notes.
- Fix broken string literals.
- Ensure the minimal Today board renders.
- Run format, analyze, and widget tests.

**Verification**

- `dart format lib test`
- `flutter analyze`
- `flutter test`

## Phase 1: Restore Pre-Refactor Design System

**Files likely touched**

- `lib/theme/app_theme.dart`
- `lib/widgets/common_widgets.dart`
- `lib/widgets/board_cards.dart`
- `lib/screens/today_board_screen.dart`

**Tasks**

- Recreate `AppColors`.
- Add `SoftCard`.
- Add `MemberAvatar`.
- Add `SectionHeader`.
- Add `AddItemFab`.
- Add `AppBottomNav`.
- Replace simple section panels with warm card-based Today layout.
- Use Korean family-board copy.
- Promote Today-private cards into reusable board card components.
- Make `AppBottomNav` accept a selected tab and routing callbacks.
- Make `AddItemFab` open a type picker with schedule/task/notice choices.
- Add shared loading, empty, error, no-access, and offline states.
- Add member role and capacity chips.
- Add admin-only invite panel primitives.

**Verification**

- Widget test asserts Today sections and add action.
- Screenshot/manual check confirms warm yellow background, olive action color, large soft cards, bottom navigation.
- Narrow-screen check confirms five bottom nav labels do not overflow.
- Add-flow test confirms the FAB exposes schedule/task/notice choices.

## Phase 1.5: Scaffold the Five Family Areas

**Files likely touched**

- `lib/screens/board_shell_screen.dart`
- `lib/screens/calendar_view_screen.dart`
- `lib/screens/tasks_list_screen.dart`
- `lib/screens/notices_board_screen.dart`
- `lib/screens/members_screen.dart`
- `lib/widgets/common_widgets.dart`
- `lib/widgets/board_item_card.dart`

**Tasks**

- Create a reusable `BoardScaffold`.
- Keep Today as the only data-rich screen for now.
- Add thin Calendar, Tasks, Notices, and Members screens using shared empty states.
- Wire bottom navigation selected state.
- Make contextual add defaults:
  - Today: all item types.
  - Calendar: schedule.
  - Tasks: task.
  - Notices: notice.
  - Members: no item default.
- Add Members placeholder with max-member/capacity visual pattern.
- Add admin-only invite placeholder states without live Supabase data.

**Verification**

- Widget tests cover all five tabs rendering.
- Bottom nav selected state changes.
- FAB bottom sheet choices match current tab.
- Members screen shows capacity and admin-only invite area in mock data.

## Phase 2: Add Supabase Project Configuration

**Files likely touched**

- `pubspec.yaml`
- `.env.example`
- `lib/services/app_config.dart`
- `lib/services/supabase_client_provider.dart`

**Tasks**

- Add `supabase_flutter`.
- Keep `shared_preferences` only if needed for local cached UI/session preferences.
- Add `.env.example` keys:
  - `SUPABASE_URL`
  - `SUPABASE_PUBLISHABLE_KEY`
- Initialize Supabase behind a small provider.
- Keep a local/mock repository path for tests.

**Verification**

- App still runs without secret keys in source.
- Tests use mock repository, not live Supabase.

## Phase 3: Create Supabase Schema and RLS

**Files likely touched**

- `supabase/migrations/*_family_board_schema.sql`
- `supabase/seed.sql` if useful
- `docs/supabase/rls-checks.sql`

**Tasks**

- Create tables:
  - `profiles`
  - `boards`
  - `board_members`
  - `board_invites`
  - `board_items`
  - `item_confirmations`
- Enable RLS on all public tables.
- Add membership helper SQL functions if needed.
- Add admin helper checks.
- Add `join_board_with_invite(invite_code text)` with atomic capacity validation.
- Add policies:
  - members can read their boards
  - members can read board items
  - members can create items in their boards
  - admins can manage invites
  - join function enforces invite and max members

**Verification**

- SQL policy checks cover member and non-member cases.
- Non-member read returns no rows.
- Full board invite join fails.
- Admin invite creation succeeds.
- Member invite creation fails.

## Phase 4: Auth and Onboarding

**Files likely touched**

- `lib/screens/welcome_screen.dart`
- `lib/screens/auth_screen.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/screens/group_selection_screen.dart`
- `lib/services/auth_repository.dart`
- `lib/services/board_repository.dart`

**Tasks**

- Add auth state routing.
- Implement sign-in with email OTP/magic link first.
- Add create-board flow with required max member count.
- Creator becomes admin.
- Add join-board flow with invite code.
- If one board exists, route directly to Today.
- If no boards exist, route to onboarding.
- Show specific join failure states:
  - invalid invite
  - expired invite
  - revoked invite
  - full board
  - already joined
  - no access

**Verification**

- Widget tests for logged-out, no-board, create-board, join-board states using fake repositories.
- Manual Supabase smoke test with two accounts once credentials exist.

## Phase 5: Shared Board Domains

**Files likely touched**

- `lib/models/*`
- `lib/services/board_repository.dart`
- `lib/screens/today_board_screen.dart`
- `lib/screens/calendar_view_screen.dart`
- `lib/screens/tasks_list_screen.dart`
- `lib/screens/notices_board_screen.dart`
- `lib/screens/members_screen.dart`
- `lib/screens/item_detail_edit_screen.dart`

**Tasks**

- Implement Today read model.
- Implement Tasks create/update/complete.
- Implement Notices create/read/confirm.
- Implement Schedules create/read/update.
- Implement Calendar selected-date view.
- Implement Members list with admin-only invite controls.
- Preserve bottom navigation across main screens.
- Move minimal Members before broad Calendar polish because invite, max members, role, and RLS feedback depend on it.

**Verification**

- Tests for creating task, completing task, confirming notice, viewing members, and capacity display.
- Manual two-user test verifies shared state.

## Phase 6: Realtime and Real-Use Polish

**Files likely touched**

- `lib/services/realtime_board_subscription.dart`
- `lib/services/board_repository.dart`
- main screens for loading/error states

**Tasks**

- Subscribe to `board_items` for active board.
- Subscribe to `item_confirmations` for active board.
- Optionally subscribe to `board_members`.
- Add pull to refresh.
- Add loading, empty, and error states.
- Add friendly Korean error messages.

**Verification**

- Two devices/accounts see item and confirmation updates.
- App still works if Realtime is temporarily unavailable through manual refresh.

## Phase 7: Hardening Before Family Use

**Tasks**

- Run RLS review against every table.
- Confirm no secret key appears in source, logs, docs, or app config.
- Confirm Supabase Free usage stays tiny.
- Confirm invite expiration/revocation.
- Confirm account logout and session persistence.
- Confirm Korean copy across all main flows.

**Verification**

- `rg "service_role|sb_secret|SUPABASE_SECRET|anonKey"` shows no leaked secret usage.
- RLS SQL checks pass.
- Flutter analyze and tests pass.

## Initial Implementation Order

Start with Phase 0 and Phase 1 in the current branch.

Reason:

- The current rebuilt app has broken Korean and likely broken Dart strings.
- Supabase work should not be layered on an unstable UI.
- Restoring the old design system first gives every later screen the right product feel.

After that, create the Supabase schema locally/in migration files before wiring live credentials.
