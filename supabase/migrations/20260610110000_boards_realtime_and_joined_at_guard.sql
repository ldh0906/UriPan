-- QA-C3: propagate board metadata changes (name, max_members) to other
-- members in realtime, and harden board_members against joined_at tampering
-- (joined_at decides the replacement creator in leave_board, so an admin
-- editing it could steer creator succession).

-- 1. Publish boards updates. Idempotent: skip when already in the publication.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'boards'
  ) then
    alter publication supabase_realtime add table public.boards;
  end if;
end;
$$;

-- 2. joined_at joins the immutable membership identity fields.
-- Same function as 20260603000000, plus the joined_at check.
create or replace function public.enforce_board_member_admin_rules()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  board_creator uuid;
  other_admin_count integer;
begin
  select created_by
  into board_creator
  from public.boards
  where id = old.board_id;

  if board_creator is null then
    if tg_op = 'DELETE' then
      return old;
    end if;

    return new;
  end if;

  if tg_op = 'UPDATE' and (
    new.board_id <> old.board_id
    or new.user_id <> old.user_id
    or new.joined_at <> old.joined_at
  ) then
    raise exception 'membership_identity_immutable' using errcode = '23514';
  end if;

  if old.user_id = board_creator and (
    tg_op = 'DELETE'
    or new.role <> 'admin'
    or new.board_id <> old.board_id
    or new.user_id <> old.user_id
  ) then
    raise exception 'creator_admin_required' using errcode = '23514';
  end if;

  if old.role = 'admin' and (
    tg_op = 'DELETE'
    or new.role <> 'admin'
  ) then
    select count(*)
    into other_admin_count
    from public.board_members
    where board_id = old.board_id
      and role = 'admin'
      and user_id <> old.user_id;

    if other_admin_count = 0 then
      raise exception 'last_admin_required' using errcode = '23514';
    end if;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;

  return new;
end;
$$;
