# UriPan Supabase Family Board Design

## Product Goal

UriPan should become a real shared family board that can be used for free on Supabase Free.
The product promise stays close to the original README: replace disappearing chat-room promises with one warm board where a family can see schedules, tasks, notices, owners, and confirmations.

The target end state is not a demo. It is a small production app for one family, with server-backed sharing, secure board membership, and a design language that matches the pre-refactor UriPan style.

## Cross-Discipline Meeting

### Product

All five family areas still matter:

- Today
- Calendar
- Tasks
- Notices
- Members

The priority is not to remove areas, but to sequence them by daily family value. Today is the home base because it answers "what should our family not miss today?" Calendar, Tasks, Notices, and Members then provide focused management views.

### Backend and Security

Supabase Free is enough for family use, but only if the schema is small and RLS is strict.

Rules:

- Use Supabase Auth for real users.
- Use only the publishable key in Flutter.
- Never place a service role or secret key in the app.
- Enable RLS on every public table.
- Authorize board data through `board_members`, not client-side checks.
- Treat invite codes as join credentials, not permanent admin authority.

### Frontend

Navigation should keep all domains but make Today the default:

- If the signed-in user belongs to exactly one board, open Today directly.
- If the user has no board, show create/join onboarding.
- If the user has multiple boards later, show board switcher before Today.

The first implementation can still support one family board while keeping the navigation ready for multiple boards.

### Design

Return to the pre-refactor style:

- Warm yellow app background.
- White soft cards with large radius and subtle shadow.
- Olive green primary actions.
- Soft pastel type accents for schedules, tasks, notices, and member chips.
- Bottom navigation plus centered add action.
- "Today pulse" summary card before lists.

The design should feel like a family situation board, not a generic productivity dashboard.

`docs/DESIGN.md` is now the source of truth for UriPan UI/UX decisions. Agents should read it before changing visual style, interaction layout, or component behavior. Its YAML front matter carries normative tokens; its prose explains how those tokens should be applied.

Current design rules from `docs/DESIGN.md`:

- Keep the emotional target "softly organized": warm and family-friendly, but still dense enough for repeated operational use.
- Preserve the warm yellow background, olive primary actions, white soft cards, and restrained pastel state colors.
- Use compact hierarchy: page headings at 24-32px, section titles at 16px, item titles at 14px, labels/chips at 12-14px.
- Keep bottom navigation persistent and keep add actions out of the bottom-nav overlap area.
- Make add/detail sheets scrollable because date, tag, and action controls can grow beyond small mobile heights.
- Treat user-entered tags as separate content from system state chips. Cards may show only a few tags; detail sheets show the full tag list.
- Avoid tag color pickers, automatic tag suggestions, and tag management screens until search/filtering is deliberately designed.

### QA

The core acceptance test is two accounts sharing one board:

1. Creator signs in.
2. Creator creates a board with max member count.
3. Creator generates an invite code.
4. Second user joins through the invite code.
5. One user creates schedule/task/notice.
6. The other user can see it.
7. Task completion and notice confirmation are reflected for both users.
8. Non-members cannot read or mutate board data.

## Scope and Priority

### Milestone 0: Stabilize Current App

Goal: make the current rebuilt app usable again before adding Supabase.

- Restore readable Korean copy.
- Restore the old README product charter.
- Fix broken Dart strings and widget tests.
- Restore the old visual tokens in `AppTheme`.
- Keep the current minimal app compiling.

This prevents backend work from landing on a broken UI base.

### Milestone 1: Design System Restoration

Goal: recover the pre-refactor design feel in the current codebase.

Implement:

- `AppColors` with the old warm yellow, olive, orange, mint, blue, and soft state colors.
- `SoftCard`.
- `MemberAvatar`.
- `SectionHeader`.
- `AddItemFab`.
- `AppBottomNav`.
- Today screen with pulse card, section headers, item cards, bottom nav, and add action.

Do not restore the old code wholesale. Rebuild the design system in smaller files that fit the new architecture.

### Milestone 2: Supabase Schema and RLS

Goal: create the smallest secure shared-board backend.

Tables:

- `profiles`
- `boards`
- `board_members`
- `board_invites`
- `board_items`
- `item_confirmations`

Optional later:

- `item_comments`
- `item_recurrence_rules`
- `attachments`
- `push_subscriptions`

Core constraints:

- `boards.created_by` is the initial admin.
- `boards.max_members` is set at board creation.
- `board_members.role` starts with `admin` and `member`.
- Only an admin can create active invite codes.
- Joining with an invite code must fail if the board is full.
- Invite codes should be revocable and expirable.

### Milestone 3: Auth and Onboarding

Goal: let family members enter the app with the fewest steps.

Recommended flow:

1. Sign in with email OTP/magic link first.
2. If no board membership exists, show two primary actions: create family board or join with code.
3. Board creation asks for board name and max members.
4. Creator becomes `admin`.
5. Admin can generate or copy invite code from Members.
6. Joining validates code, capacity, and expiry.

Email/password can be added later if magic link friction is too high.

### Milestone 4: Shared Board Features

Goal: implement the family domains using Supabase data.

Build order:

1. Today read model.
2. Tasks create/update/complete.
3. Notices create/read/confirm.
4. Schedules create/read/update.
5. Calendar view.
6. Members view and invite management.

Reasoning:

- Tasks and notices prove shared interaction fastest.
- Schedule and calendar become more useful once the data model is stable.
- Member/admin flows should be secure before exposing more settings.

### Milestone 5: Realtime and Polish

Goal: make it feel shared without overengineering.

Realtime priority:

1. `board_items` changes for the active board.
2. `item_confirmations` changes.
3. `board_members` changes.

Add:

- Empty states.
- Loading states.
- Error states.
- Pull to refresh.
- Basic offline message.
- Korean family-friendly copy.

## Proposed Database Shape

### `profiles`

- `id uuid primary key references auth.users(id) on delete cascade`
- `display_name text not null`
- `avatar_color text`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Users can read profiles for users sharing a board. Users can update only their own profile.

### `boards`

- `id uuid primary key default gen_random_uuid()`
- `name text not null`
- `created_by uuid not null references auth.users(id)`
- `max_members int not null check (max_members between 2 and 20)`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Members can read boards they belong to. Only admins can update board settings.

### `board_members`

- `board_id uuid references boards(id) on delete cascade`
- `user_id uuid references auth.users(id) on delete cascade`
- `role text not null check (role in ('admin', 'member'))`
- `joined_at timestamptz not null default now()`
- `primary key (board_id, user_id)`

Membership is the authorization backbone. A user can read membership rows for boards they belong to. Admin-only mutations are required for role changes and removals.

### `board_invites`

- `id uuid primary key default gen_random_uuid()`
- `board_id uuid not null references boards(id) on delete cascade`
- `code text not null unique`
- `created_by uuid not null references auth.users(id)`
- `expires_at timestamptz not null`
- `revoked_at timestamptz`
- `created_at timestamptz not null default now()`

Only board admins can create, read, revoke, and regenerate invite codes. Join should happen through a database function so capacity checks are atomic.

### `board_items`

- `id uuid primary key default gen_random_uuid()`
- `board_id uuid not null references boards(id) on delete cascade`
- `type text not null check (type in ('schedule', 'task', 'notice'))`
- `title text not null`
- `detail text`
- `starts_at timestamptz`
- `due_at timestamptz`
- `assigned_to uuid references auth.users(id)`
- `created_by uuid not null references auth.users(id)`
- `is_done boolean not null default false`
- `is_pinned boolean not null default false`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Members can read items in their boards. Members can create items. Creator or admin can edit/delete. Task completion can be updated by assignee or admin; family-friendly mode may allow any member to complete a task if we decide that is better.

### `item_confirmations`

- `item_id uuid references board_items(id) on delete cascade`
- `user_id uuid references auth.users(id) on delete cascade`
- `confirmed_at timestamptz not null default now()`
- `primary key (item_id, user_id)`

Members can confirm notices in their boards. Users can remove only their own confirmation if the product supports undo.

## Invite Code Policy

Invite code behavior:

- Only the board admin can generate invite codes.
- The initial board creator is automatically admin.
- Board creation requires `max_members`.
- Joining checks `active invite + capacity + authenticated user`.
- If member count is already `max_members`, joining fails.
- Invite code is revocable.
- Invite code expires by default after 7 days.
- Only one active invite per board is recommended for simplicity.

Implementation detail:

- Use a Postgres function such as `join_board_with_invite(invite_code text)` to perform lookup, capacity check, and insert in one transaction.
- The function should run with carefully scoped privileges and explicit checks. Avoid placing broad `security definer` functions in an exposed schema unless the function is audited and search path is fixed.

## UI Information Architecture

The app keeps five areas, but they should not carry equal weight. Today is the family situation board. The other tabs are management surfaces.

Priority by daily family value:

1. Today: what the family must not miss.
2. Tasks: who promised to do what.
3. Notices: what everyone needs to see or confirm.
4. Calendar: date-based planning and browsing.
5. Members: family setup, invite, roles, and capacity.

Use family language instead of workspace/project language. The default assumption is one family board.

### Today

Default landing screen for a member with one board.

Contains:

- Board name and date.
- Members button.
- Human Today pulse card, not just counts.
- Needs attention: overdue tasks and unconfirmed important notices.
- Next schedules.
- Open tasks.
- Notices.
- Bottom navigation.
- Center add button.

Promotion rules:

- Important unconfirmed notices appear before ordinary notices.
- Overdue or due-today tasks appear before lower-priority tasks.
- The next schedule appears before later schedules.
- Today should summarize and link out, not become a full dashboard.

### Calendar

Focused schedule view.

Contains:

- Week-first strip before any dense month view.
- Schedule list for selected date.
- Add schedule action.

### Tasks

Focused task board.

Contains:

- Segmented filter: open, mine, done.
- Task cards with assignee and due date.
- Complete checkbox.

Task cards must emphasize owner, due timing, and done state. Categories and complex labels are deferred.

### Notices

Focused notice board.

Contains:

- Important notices first.
- Confirmation status.
- Confirm button.

Notices must not look like tasks. Their primary interaction is "confirmed/read", not "done".

### Members

Board admin and family member view.

Contains:

- Member list.
- Role chips.
- Max member count.
- Invite code controls for admin only.
- Leave board action.

Members is not a settings page. It should reinforce who is in the family board, while keeping admin controls quiet and explicit.

## Add Flow

The centered add action opens a bottom sheet with three choices:

- Schedule: `일정 추가`
- Task: `할 일 추가`
- Notice: `공지 올리기`

Context defaults:

- Today shows all three choices equally.
- Calendar defaults to schedule.
- Tasks defaults to task.
- Notices defaults to notice.
- Members does not default to item creation.

Avoid one overloaded item form too early. Each type should have a short focused form with shared visual structure.

## Shared UI Components

Before adding full feature screens, harden these reusable primitives:

- `BoardScaffold`: safe area, bottom navigation, centered add action, loading/error shell.
- `BoardItemCard`: shared card base for schedule/task/notice variants.
- `MemberAvatar`: initials and color.
- `RoleChip`: admin/member display.
- `CapacityChip`: current member count over max members.
- `InviteCodePanel`: copy, regenerate, revoke, expired, full-board states.
- `EmptyState`: friendly blank states.
- `LoadingState`: honest loading state.
- `ErrorState`: friendly retry/no-access state.
- `PermissionGate`: renders admin-only actions only when the server-loaded role permits them.

UI should reflect server authorization rather than pretending client checks are security. For example, non-admin users should not receive invite code data and should not see invite controls.

## Interaction States

Design these states before full implementation:

- Loading board.
- Empty board.
- Offline or refresh failed.
- No board membership.
- RLS/no-access denial.
- Invalid invite code.
- Expired or revoked invite code.
- Full board.
- Already joined.
- Confirmation pending.
- Task completed.
- Realtime unavailable with manual refresh fallback.

Use specific Korean messages. An empty board should not be used as the fallback for permission errors because that looks like data loss.

## Accessibility and Mobile Constraints

- Minimum touch targets should stay at least 44px.
- Bottom nav labels must fit on narrow mobile screens.
- Important actions need semantic labels.
- Cards should preserve readable hierarchy with larger text settings.
- The centered FAB must not cover the last list item.
- Use screen-reader-friendly labels for confirmation and completion states.

## Design System Direction

Use the pre-refactor screenshots as the visual target.

Tokens:

- Background: `#FFF2BB`
- Primary: `#647D31`
- Secondary: `#E7A14B`
- Tertiary: `#D79059`
- Text: `#13243B`
- Muted text: `#64748B`
- Surface: `#FFFFFF`
- Surface variant: `#F2E8D9`
- Primary soft: `#EFF6D6`
- Warning soft: `#FFF0D8`
- Info soft: `#EAF2FF`
- Success soft: `#E8F8F0`

Component rules:

- Main content uses 20px horizontal padding.
- Cards use 24px radius and subtle shadow.
- Buttons use 18px radius.
- Bottom nav stays fixed and touch-friendly.
- Avoid generic dense admin-dashboard styling.
- Korean copy should sound like a family board, not enterprise software.
- Avoid making every section identical. Urgent notices and overdue tasks need stronger hierarchy than ordinary items.
- Avoid Material-default styling drift. Generic seeded colors, uniform cards, and default copy can erase UriPan's identity.

## Technical References

- Supabase Flutter quickstart recommends `supabase_flutter` and client-side publishable keys.
- Supabase docs say RLS should be enabled on tables in exposed schemas.
- Supabase RLS docs warn not to use user-editable metadata for authorization.
- Supabase Realtime authorization docs show membership-table checks for room/channel access.
- Supabase community Flutter chat example demonstrates Flutter + Supabase Realtime and has an auth/RLS branch for room-style access.

## Acceptance Criteria

- Current app builds and tests pass after Korean/design restoration.
- Supabase schema migration is committed.
- RLS is enabled on every public table.
- A non-member cannot read a board, item, member row, invite, or confirmation.
- A board creator becomes admin automatically.
- Only admin can create/revoke invite code.
- Board creation requires max members.
- Invite join fails when the board is full.
- Two authenticated users can share one board.
- Today, Calendar, Tasks, Notices, and Members exist.
- Old warm visual style is visible in screenshots.

## Open Decisions

- Magic link only vs email/password plus magic link.
- Whether any family member can complete any task, or only assignee/admin.
- Maximum member default: recommended 6, user-selectable 2 to 20.
- Whether invite codes should be human-readable short codes or longer random tokens.
- Whether multiple active invites per board are needed. Recommendation: one active invite per board for now.
