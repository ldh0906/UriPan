-- Manual RLS verification queries for UriPan.
-- Replace UUID placeholders with test users and board ids.
-- Run in Supabase SQL editor or through MCP after creating test users.

-- 1. As creator user:
-- select auth.uid();
-- select * from public.create_family_board('우리집', 4);
-- Expected: board row returned and matching board_members admin row created.

-- 2. As creator/admin:
-- select * from public.create_board_invite('<BOARD_ID>'::uuid);
-- Expected: one active invite row. Re-running creates a new invite and revokes the old one.

-- 3. As non-admin member:
-- select * from public.create_board_invite('<BOARD_ID>'::uuid);
-- Expected: admin_required error.

-- 4. As invited authenticated user:
-- select * from public.join_board_with_invite('<CODE>');
-- Expected: board_members row with role member.

-- 5. As non-member:
-- select * from public.boards where id = '<BOARD_ID>'::uuid;
-- select * from public.board_items where board_id = '<BOARD_ID>'::uuid;
-- Expected: zero rows.

-- 6. Capacity check:
-- Fill board_members to boards.max_members, then as a new user:
-- select * from public.join_board_with_invite('<CODE>');
-- Expected: board_full error.

-- 7. Notice confirmation:
-- insert into public.item_confirmations (item_id, user_id)
-- values ('<NOTICE_ITEM_ID>'::uuid, auth.uid());
-- Expected: succeeds for notice item in user's board, fails for non-notice or non-member item.

-- 8. Task completion:
-- select * from public.complete_task('<TASK_ITEM_ID>'::uuid, true);
-- Expected: succeeds for task item in user's board without allowing broad item edits.
