-- QA-A2: members who left a board show up as UUID/'???' because their profile
-- row is no longer visible under profiles RLS. Snapshot the display name at
-- write time (board nickname first, then global display name) so authored
-- content keeps a human name after the author leaves.
--
-- Policy: snapshots preserve the name *as of writing*; later profile renames
-- do not rewrite history. Live members keep being rendered from the current
-- profile/nickname on the client; snapshots are only the fallback.

-- 1. Snapshot columns.
alter table public.board_items
  add column if not exists created_by_name_snapshot text,
  add column if not exists assigned_to_name_snapshot text;

alter table public.item_comments
  add column if not exists author_name_snapshot text;

-- 2. Resolver: board nickname wins, then profile display name.
create or replace function public.board_display_name(
  target_board_id uuid,
  target_user_id uuid
)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select nullif(btrim(bm.nickname), '')
      from public.board_members bm
      where bm.board_id = target_board_id
        and bm.user_id = target_user_id
    ),
    (
      select p.display_name
      from public.profiles p
      where p.id = target_user_id
    )
  );
$$;

-- 3. Triggers. Snapshots are server-owned: client-sent values are overwritten.
create or replace function public.set_board_item_name_snapshots()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.created_by_name_snapshot :=
      public.board_display_name(new.board_id, new.created_by);
    new.assigned_to_name_snapshot := case
      when new.assigned_to is null then null
      else public.board_display_name(new.board_id, new.assigned_to)
    end;
    return new;
  end if;

  -- UPDATE: creation snapshot is frozen; assignee snapshot follows assigned_to.
  new.created_by_name_snapshot := old.created_by_name_snapshot;
  if new.assigned_to is distinct from old.assigned_to then
    new.assigned_to_name_snapshot := case
      when new.assigned_to is null then null
      else public.board_display_name(new.board_id, new.assigned_to)
    end;
  else
    new.assigned_to_name_snapshot := old.assigned_to_name_snapshot;
  end if;
  return new;
end;
$$;

drop trigger if exists board_items_name_snapshots on public.board_items;
create trigger board_items_name_snapshots
before insert or update on public.board_items
for each row execute function public.set_board_item_name_snapshots();

create or replace function public.set_item_comment_name_snapshot()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  parent_board_id uuid;
begin
  if tg_op = 'UPDATE' then
    new.author_name_snapshot := old.author_name_snapshot;
    return new;
  end if;

  select board_id
  into parent_board_id
  from public.board_items
  where id = new.item_id;

  new.author_name_snapshot :=
    public.board_display_name(parent_board_id, new.author_id);
  return new;
end;
$$;

drop trigger if exists item_comments_name_snapshot on public.item_comments;
create trigger item_comments_name_snapshot
before insert or update on public.item_comments
for each row execute function public.set_item_comment_name_snapshot();

-- 4. Backfill with today's best-known names. Members who already left and
-- whose profile is gone stay null (nothing left to recover).
update public.board_items bi
set created_by_name_snapshot = public.board_display_name(bi.board_id, bi.created_by)
where bi.created_by_name_snapshot is null;

update public.board_items bi
set assigned_to_name_snapshot = public.board_display_name(bi.board_id, bi.assigned_to)
where bi.assigned_to is not null
  and bi.assigned_to_name_snapshot is null;

update public.item_comments ic
set author_name_snapshot = public.board_display_name(ic.board_id, ic.author_id)
where ic.author_name_snapshot is null;

revoke all on function public.board_display_name(uuid, uuid) from public, anon, authenticated;
revoke all on function public.set_board_item_name_snapshots() from public, anon, authenticated;
revoke all on function public.set_item_comment_name_snapshot() from public, anon, authenticated;
