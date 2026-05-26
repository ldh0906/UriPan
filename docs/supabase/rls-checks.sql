-- Manual RLS/RPC verification checks for UriPan.
--
-- Run these from the Supabase SQL editor or another SQL client that can switch
-- authenticated test users. Replace placeholders before running.
--
-- Required actors:
--   <ADMIN_USER_ID>      board creator/admin
--   <MEMBER_USER_ID>     joined board member, not admin
--   <OTHER_USER_ID>      authenticated user who is not on the board
--   <EXTRA_USER_ID>      authenticated user used for capacity tests
--
-- Required rows:
--   <BOARD_ID>           board created by <ADMIN_USER_ID>
--   <INVITE_CODE>        active invite created by <ADMIN_USER_ID>
--   <TASK_ITEM_ID>       task item on <BOARD_ID>
--   <NOTICE_ITEM_ID>     notice item on <BOARD_ID>
--   <SCHEDULE_ITEM_ID>   schedule item on <BOARD_ID>
--
-- In SQL editor, use "Run as" / impersonation where available. If using a
-- local Supabase stack, set request.jwt.claim.sub and request.jwt.claim.role
-- for each actor before running a block.

-- ---------------------------------------------------------------------------
-- 1. Anonymous users cannot read app data or execute app RPCs.
-- ---------------------------------------------------------------------------
-- As anon:
select * from public.boards where id = '<BOARD_ID>'::uuid;
select * from public.board_members where board_id = '<BOARD_ID>'::uuid;
select * from public.board_invites where board_id = '<BOARD_ID>'::uuid;
select * from public.board_items where board_id = '<BOARD_ID>'::uuid;
select *
from public.item_confirmations
where item_id = '<NOTICE_ITEM_ID>'::uuid;

select * from public.create_family_board('Anon board', 4);
select * from public.create_board_invite('<BOARD_ID>'::uuid);
select * from public.join_board_with_invite('<INVITE_CODE>');
select * from public.complete_task('<TASK_ITEM_ID>'::uuid, true);

-- Expected:
--   Table reads return zero rows or permission denied.
--   RPC calls fail with permission denied or authentication_required.

-- ---------------------------------------------------------------------------
-- 2. Admin can create a board and receives admin membership.
-- ---------------------------------------------------------------------------
-- As <ADMIN_USER_ID>:
select auth.uid();
select * from public.create_family_board('UriPan QA', 4);

select bm.*
from public.board_members bm
where bm.board_id = '<BOARD_ID>'::uuid
  and bm.user_id = auth.uid()
  and bm.role = 'admin';

-- Expected:
--   create_family_board returns a board row.
--   board_members has exactly one admin row for the creator.

-- ---------------------------------------------------------------------------
-- 3. Board-scoped reads are isolated by membership.
-- ---------------------------------------------------------------------------
-- As <ADMIN_USER_ID> or <MEMBER_USER_ID>:
select * from public.boards where id = '<BOARD_ID>'::uuid;
select * from public.board_members where board_id = '<BOARD_ID>'::uuid;
select * from public.board_items where board_id = '<BOARD_ID>'::uuid;
select *
from public.item_confirmations
where item_id = '<NOTICE_ITEM_ID>'::uuid;

-- Expected:
--   Board members can read board, member, item, and confirmation rows.

-- As <OTHER_USER_ID>:
select * from public.boards where id = '<BOARD_ID>'::uuid;
select * from public.board_members where board_id = '<BOARD_ID>'::uuid;
select * from public.board_invites where board_id = '<BOARD_ID>'::uuid;
select * from public.board_items where board_id = '<BOARD_ID>'::uuid;
select *
from public.item_confirmations
where item_id = '<NOTICE_ITEM_ID>'::uuid;
select *
from public.profiles
where id in ('<ADMIN_USER_ID>'::uuid, '<MEMBER_USER_ID>'::uuid);

-- Expected:
--   Non-member gets zero rows for all board-scoped data.
--   Non-member cannot read profiles for users who do not share a board.

-- ---------------------------------------------------------------------------
-- 4. Invite management is admin-only and RPC-controlled.
-- ---------------------------------------------------------------------------
-- As <ADMIN_USER_ID>:
select * from public.create_board_invite('<BOARD_ID>'::uuid);

select count(*) as active_invites
from public.board_invites
where board_id = '<BOARD_ID>'::uuid
  and revoked_at is null;

-- Expected:
--   create_board_invite returns one invite.
--   active_invites = 1. Re-running create_board_invite revokes old active code.

-- As <MEMBER_USER_ID>:
select * from public.create_board_invite('<BOARD_ID>'::uuid);

-- Expected:
--   Fails with admin_required.

-- As <MEMBER_USER_ID>:
insert into public.board_invites (board_id, code, created_by, expires_at)
values (
  '<BOARD_ID>'::uuid,
  'FAIL-0001',
  auth.uid(),
  now() + interval '7 days'
);

update public.board_invites
set revoked_at = now()
where board_id = '<BOARD_ID>'::uuid;

delete from public.board_invites
where board_id = '<BOARD_ID>'::uuid;

-- Expected:
--   Direct insert/update/delete is denied by RLS or returns no affected rows.

-- As <ADMIN_USER_ID>:
select public.revoke_board_invite('<INVITE_ID>'::uuid);

-- Expected:
--   Admin can revoke. revoked_at is set.

-- As <MEMBER_USER_ID>:
select public.revoke_board_invite('<INVITE_ID>'::uuid);

-- Expected:
--   Fails with admin_required.

-- ---------------------------------------------------------------------------
-- 5. Invite joins accept only active, unexpired codes.
-- ---------------------------------------------------------------------------
-- As <OTHER_USER_ID>:
select * from public.join_board_with_invite('<INVITE_CODE>');

-- Expected:
--   Returns board_members row with role = member.

-- As the same user again:
select * from public.join_board_with_invite('<INVITE_CODE>');

-- Expected:
--   Fails with already_joined.

-- As <EXTRA_USER_ID>, using a revoked invite code:
select * from public.join_board_with_invite('<REVOKED_INVITE_CODE>');

-- Expected:
--   Fails with revoked_invite and member count is unchanged.

-- As <EXTRA_USER_ID>, using an expired invite code:
select * from public.join_board_with_invite('<EXPIRED_INVITE_CODE>');

-- Expected:
--   Fails with expired_invite and member count is unchanged.

-- As <EXTRA_USER_ID>, using a nonsense code:
select * from public.join_board_with_invite('NOPE-0000');

-- Expected:
--   Fails with invalid_invite.

-- ---------------------------------------------------------------------------
-- 6. Board capacity cannot be bypassed.
-- ---------------------------------------------------------------------------
-- Setup:
--   Create a board with max_members = 2.
--   Join one non-admin user through invite so the board is full.
--
-- As another authenticated user:
select * from public.join_board_with_invite('<FULL_BOARD_INVITE_CODE>');

-- Expected:
--   Fails with board_full and board_members count is unchanged.

-- As <ADMIN_USER_ID>, on a board with more than 2 current members:
update public.boards
set max_members = 2
where id = '<BOARD_ID>'::uuid;

-- Expected:
--   Fails with max_members_below_current_count.

-- ---------------------------------------------------------------------------
-- 7. Item creation and mutation stay inside the family boundary.
-- ---------------------------------------------------------------------------
-- As <MEMBER_USER_ID>:
insert into public.board_items (
  board_id,
  type,
  title,
  due_at,
  created_by
) values (
  '<BOARD_ID>'::uuid,
  'task',
  'QA task',
  now(),
  auth.uid()
);

-- Expected:
--   Member can create an item on their board.

-- As <OTHER_USER_ID>:
insert into public.board_items (
  board_id,
  type,
  title,
  due_at,
  created_by
) values (
  '<BOARD_ID>'::uuid,
  'task',
  'Cross-family task',
  now(),
  auth.uid()
);

-- Expected:
--   Fails RLS because the user is not a board member.

-- As <MEMBER_USER_ID>, for an item they did not create:
update public.board_items
set title = 'Should not edit broad item fields'
where id = '<TASK_ITEM_ID>'::uuid;

-- Expected:
--   Direct broad item update is denied or affects zero rows unless this user is
--   the creator/admin. Task completion must go through complete_task.

-- ---------------------------------------------------------------------------
-- 8. Task completion follows the current v1 product rule.
-- ---------------------------------------------------------------------------
-- Current rule: any board member can complete a task.
--
-- As <MEMBER_USER_ID>:
select * from public.complete_task('<TASK_ITEM_ID>'::uuid, true);

-- Expected:
--   Succeeds for task items on the user's board.

-- As <OTHER_USER_ID>:
select * from public.complete_task('<TASK_ITEM_ID>'::uuid, true);

-- Expected:
--   Fails with task_not_found_or_no_access.

-- As <MEMBER_USER_ID>, against a non-task item:
select * from public.complete_task('<SCHEDULE_ITEM_ID>'::uuid, true);

-- Expected:
--   Fails with task_not_found_or_no_access.

-- ---------------------------------------------------------------------------
-- 9. Notice confirmations are own-user and notice-only.
-- ---------------------------------------------------------------------------
-- As <MEMBER_USER_ID>:
insert into public.item_confirmations (item_id, user_id)
values ('<NOTICE_ITEM_ID>'::uuid, auth.uid());

-- Expected:
--   Succeeds for a notice in the user's board.

-- As <MEMBER_USER_ID>:
insert into public.item_confirmations (item_id, user_id)
values ('<TASK_ITEM_ID>'::uuid, auth.uid());

-- Expected:
--   Fails with notice_confirmation_required.

-- As <OTHER_USER_ID>:
insert into public.item_confirmations (item_id, user_id)
values ('<NOTICE_ITEM_ID>'::uuid, auth.uid());

-- Expected:
--   Fails RLS because the user is not a board member.
