-- QA-C2 (full): denormalize board_id onto item_comments / item_confirmations.
-- Enables realtime filters per board, simplifies RLS from exists-subqueries to
-- is_board_member(board_id), and becomes the standard pattern for future child
-- tables (occurrences, notification events).
--
-- Order matters for live data: nullable add -> backfill -> not null -> trigger.
-- Old clients insert without board_id; the before-trigger fills it, so the
-- rollout is backward compatible.

-- 1. Add columns (nullable first so existing rows do not fail).
alter table public.item_comments
  add column if not exists board_id uuid references public.boards(id) on delete cascade;

alter table public.item_confirmations
  add column if not exists board_id uuid references public.boards(id) on delete cascade;

-- 2. Backfill from the parent item.
update public.item_comments ic
set board_id = bi.board_id
from public.board_items bi
where bi.id = ic.item_id
  and ic.board_id is null;

update public.item_confirmations icf
set board_id = bi.board_id
from public.board_items bi
where bi.id = icf.item_id
  and icf.board_id is null;

-- 3. Enforce not null now that every row is filled.
alter table public.item_comments alter column board_id set not null;
alter table public.item_confirmations alter column board_id set not null;

-- 4. Trigger: board_id always mirrors the parent item, regardless of what the
-- client sends (old clients send nothing, malicious clients cannot spoof).
create or replace function public.set_item_child_board_id()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  parent_board_id uuid;
begin
  select board_id
  into parent_board_id
  from public.board_items
  where id = new.item_id;

  if parent_board_id is null then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;

  new.board_id := parent_board_id;
  return new;
end;
$$;

drop trigger if exists item_comments_set_board_id on public.item_comments;
create trigger item_comments_set_board_id
before insert or update on public.item_comments
for each row execute function public.set_item_child_board_id();

drop trigger if exists item_confirmations_set_board_id on public.item_confirmations;
create trigger item_confirmations_set_board_id
before insert or update on public.item_confirmations
for each row execute function public.set_item_child_board_id();

-- 5. RLS: replace exists-subquery policies with direct membership checks.
drop policy if exists "item_comments_select_members" on public.item_comments;
create policy "item_comments_select_members"
on public.item_comments
for select
to authenticated
using (public.is_board_member(board_id));

drop policy if exists "item_comments_insert_own_members" on public.item_comments;
create policy "item_comments_insert_own_members"
on public.item_comments
for insert
to authenticated
with check (
  author_id = auth.uid()
  and public.is_board_member(board_id)
);

drop policy if exists "item_comments_delete_own_or_admin" on public.item_comments;
create policy "item_comments_delete_own_or_admin"
on public.item_comments
for delete
to authenticated
using (
  author_id = auth.uid()
  or public.is_board_admin(board_id)
);

drop policy if exists "item_confirmations_select_members" on public.item_confirmations;
create policy "item_confirmations_select_members"
on public.item_confirmations
for select
to authenticated
using (public.is_board_member(board_id));

-- Notice-only rule stays in the item_confirmations_notice_only trigger.
drop policy if exists "item_confirmations_insert_own_for_notice_members" on public.item_confirmations;
create policy "item_confirmations_insert_own_for_notice_members"
on public.item_confirmations
for insert
to authenticated
with check (
  user_id = auth.uid()
  and public.is_board_member(board_id)
);

-- 6. Indexes for board-scoped access paths.
create index if not exists item_comments_board_item_created_idx
  on public.item_comments(board_id, item_id, created_at);
create index if not exists item_confirmations_board_item_idx
  on public.item_confirmations(board_id, item_id);

-- 7. Realtime: filtered DELETE events are only delivered when the filter
-- column is present in the old record, which requires replica identity full.
alter table public.item_comments replica identity full;
alter table public.item_confirmations replica identity full;

revoke all on function public.set_item_child_board_id() from public, anon, authenticated;
