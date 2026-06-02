create or replace function public.enforce_board_update_rules()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_members integer;
begin
  if new.id <> old.id then
    raise exception 'board_identity_immutable' using errcode = '23514';
  end if;

  if new.created_by <> old.created_by then
    if current_setting('app.allow_board_creator_transfer', true) <> 'true' then
      raise exception 'board_identity_immutable' using errcode = '23514';
    end if;

    if not exists (
      select 1
      from public.board_members
      where board_id = old.id
        and user_id = new.created_by
        and role = 'admin'
    ) then
      raise exception 'board_creator_must_be_admin' using errcode = '23514';
    end if;
  end if;

  select count(*)
  into current_members
  from public.board_members
  where board_id = old.id;

  if new.max_members < current_members then
    raise exception 'max_members_below_current_count' using errcode = '23514';
  end if;

  return new;
end;
$$;

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

create or replace function public.leave_board(target_board_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  leaving_user uuid := auth.uid();
  leaving_role text;
  board_creator uuid;
  replacement_creator uuid;
begin
  if leaving_user is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select role
  into leaving_role
  from public.board_members
  where board_id = target_board_id
    and user_id = leaving_user;

  if leaving_role is null then
    raise exception 'membership_required' using errcode = '42501';
  end if;

  select user_id
  into replacement_creator
  from public.board_members
  where board_id = target_board_id
    and user_id <> leaving_user
    and role = 'admin'
  order by joined_at
  limit 1;

  if replacement_creator is null then
    select user_id
    into replacement_creator
    from public.board_members
    where board_id = target_board_id
      and user_id <> leaving_user
    order by joined_at
    limit 1;
  end if;

  if replacement_creator is null then
    delete from public.boards
    where id = target_board_id;
    return;
  end if;

  if leaving_role = 'admin' then
    update public.board_members
    set role = 'admin'
    where board_id = target_board_id
      and user_id = replacement_creator;
  end if;

  select created_by
  into board_creator
  from public.boards
  where id = target_board_id;

  if board_creator = leaving_user then
    perform set_config('app.allow_board_creator_transfer', 'true', true);

    update public.boards
    set created_by = replacement_creator
    where id = target_board_id;
  end if;

  delete from public.board_members
  where board_id = target_board_id
    and user_id = leaving_user;
end;
$$;

revoke all on function public.leave_board(uuid) from public, anon;
grant execute on function public.leave_board(uuid) to authenticated;
