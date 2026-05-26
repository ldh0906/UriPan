-- UriPan family board backend schema.
-- Target: Supabase Postgres 17.

create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

create extension if not exists pgcrypto;

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 60),
  avatar_color text not null default '#647D31',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.boards (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 80),
  created_by uuid not null references auth.users(id) on delete restrict,
  max_members integer not null check (max_members between 2 and 20),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.board_members (
  board_id uuid not null references public.boards(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('admin', 'member')),
  joined_at timestamptz not null default now(),
  primary key (board_id, user_id)
);

create table public.board_invites (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  code text not null unique check (code ~ '^[A-Z0-9]{4}-[A-Z0-9]{4}$'),
  created_by uuid not null references auth.users(id) on delete restrict,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  check (expires_at > created_at)
);

create table public.board_items (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  type text not null check (type in ('schedule', 'task', 'notice')),
  title text not null check (char_length(title) between 1 and 120),
  detail text,
  starts_at timestamptz,
  due_at timestamptz,
  assigned_to uuid references auth.users(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete restrict,
  requires_confirmation boolean not null default false,
  is_done boolean not null default false,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (type <> 'schedule' or starts_at is not null),
  check (type <> 'task' or due_at is not null),
  check (type <> 'notice' or is_done = false),
  check (requires_confirmation = false or type = 'notice')
);

create table public.item_confirmations (
  item_id uuid not null references public.board_items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  confirmed_at timestamptz not null default now(),
  primary key (item_id, user_id)
);

create index boards_created_by_idx on public.boards(created_by);
create index board_members_user_id_idx on public.board_members(user_id);
create index board_invites_board_id_idx on public.board_invites(board_id);
create unique index board_invites_one_unrevoked_per_board_idx
  on public.board_invites(board_id)
  where revoked_at is null;
create index board_items_board_type_idx on public.board_items(board_id, type);
create index board_items_due_at_idx on public.board_items(due_at) where due_at is not null;
create index board_items_starts_at_idx on public.board_items(starts_at) where starts_at is not null;
create index item_confirmations_user_id_idx on public.item_confirmations(user_id);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function app_private.set_updated_at();

create trigger boards_set_updated_at
before update on public.boards
for each row execute function app_private.set_updated_at();

create trigger board_items_set_updated_at
before update on public.board_items
for each row execute function app_private.set_updated_at();

create or replace function public.enforce_board_update_rules()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_members integer;
begin
  if new.id <> old.id or new.created_by <> old.created_by then
    raise exception 'board_identity_immutable' using errcode = '23514';
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

create trigger boards_update_rules
before update on public.boards
for each row execute function public.enforce_board_update_rules();

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

create trigger board_members_admin_rules_update
before update on public.board_members
for each row execute function public.enforce_board_member_admin_rules();

create trigger board_members_admin_rules_delete
before delete on public.board_members
for each row execute function public.enforce_board_member_admin_rules();

create or replace function public.enforce_board_item_update_rules()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.id <> old.id
    or new.board_id <> old.board_id
    or new.type <> old.type
    or new.created_by <> old.created_by then
    raise exception 'board_item_identity_immutable' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger board_items_update_rules
before update on public.board_items
for each row execute function public.enforce_board_item_update_rules();

create or replace function public.enforce_notice_confirmation_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.board_items bi
    where bi.id = new.item_id
      and bi.type = 'notice'
  ) then
    raise exception 'notice_confirmation_required' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger item_confirmations_notice_only
before insert or update on public.item_confirmations
for each row execute function public.enforce_notice_confirmation_item();

create or replace function public.create_family_board(
  board_name text,
  member_limit integer
)
returns public.boards
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_board public.boards;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  insert into public.boards (name, created_by, max_members)
  values (trim(board_name), auth.uid(), member_limit)
  returning * into created_board;

  return created_board;
end;
$$;

create or replace function public.is_board_member(check_board_id uuid, check_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.board_members bm
    where bm.board_id = check_board_id
      and bm.user_id = check_user_id
  );
$$;

create or replace function public.is_board_admin(check_board_id uuid, check_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.board_members bm
    where bm.board_id = check_board_id
      and bm.user_id = check_user_id
      and bm.role = 'admin'
  );
$$;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  fallback_name text;
begin
  fallback_name := coalesce(
    nullif(new.raw_user_meta_data ->> 'display_name', ''),
    nullif(split_part(new.email, '@', 1), ''),
    'UriPan Member'
  );

  insert into public.profiles (id, display_name)
  values (new.id, fallback_name)
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();

create or replace function public.handle_new_board_admin()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.board_members (board_id, user_id, role)
  values (new.id, new.created_by, 'admin')
  on conflict (board_id, user_id) do nothing;

  return new;
end;
$$;

create trigger boards_insert_creator_admin
after insert on public.boards
for each row execute function public.handle_new_board_admin();

create or replace function public.create_board_invite(
  target_board_id uuid,
  ttl interval default interval '7 days'
)
returns public.board_invites
language plpgsql
security definer
set search_path = ''
as $$
declare
  generated_code text;
  created_invite public.board_invites;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  if not public.is_board_admin(target_board_id, auth.uid()) then
    raise exception 'admin_required' using errcode = '42501';
  end if;

  update public.board_invites
  set revoked_at = now()
  where board_id = target_board_id
    and revoked_at is null;

  loop
    generated_code := upper(substr(encode(public.gen_random_bytes(5), 'hex'), 1, 4))
      || '-'
      || upper(substr(encode(public.gen_random_bytes(5), 'hex'), 1, 4));

    begin
      insert into public.board_invites (
        board_id,
        code,
        created_by,
        expires_at
      )
      values (
        target_board_id,
        generated_code,
        auth.uid(),
        now() + ttl
      )
      returning * into created_invite;

      return created_invite;
    exception
      when unique_violation then
        -- Try another code.
    end;
  end loop;
end;
$$;

create or replace function public.revoke_board_invite(target_invite_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  invite_board_id uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select board_id into invite_board_id
  from public.board_invites
  where id = target_invite_id;

  if invite_board_id is null then
    raise exception 'invite_not_found' using errcode = 'P0002';
  end if;

  if not public.is_board_admin(invite_board_id, auth.uid()) then
    raise exception 'admin_required' using errcode = '42501';
  end if;

  update public.board_invites
  set revoked_at = coalesce(revoked_at, now())
  where id = target_invite_id;
end;
$$;

create or replace function public.join_board_with_invite(invite_code text)
returns public.board_members
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_code text;
  invite_record public.board_invites;
  board_limit integer;
  current_members integer;
  joined_member public.board_members;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  normalized_code := upper(trim(invite_code));

  select *
  into invite_record
  from public.board_invites
  where code = normalized_code
  for update;

  if invite_record.id is null then
    raise exception 'invalid_invite' using errcode = 'P0002';
  end if;

  if invite_record.revoked_at is not null then
    raise exception 'revoked_invite' using errcode = 'P0001';
  end if;

  if invite_record.expires_at <= now() then
    raise exception 'expired_invite' using errcode = 'P0001';
  end if;

  perform 1
  from public.boards
  where id = invite_record.board_id
  for update;

  select max_members
  into board_limit
  from public.boards
  where id = invite_record.board_id;

  if exists (
    select 1
    from public.board_members
    where board_id = invite_record.board_id
      and user_id = auth.uid()
  ) then
    raise exception 'already_joined' using errcode = '23505';
  end if;

  select count(*)
  into current_members
  from public.board_members
  where board_id = invite_record.board_id;

  if current_members >= board_limit then
    raise exception 'board_full' using errcode = 'P0001';
  end if;

  insert into public.board_members (board_id, user_id, role)
  values (invite_record.board_id, auth.uid(), 'member')
  returning * into joined_member;

  return joined_member;
end;
$$;

create or replace function public.complete_task(
  target_item_id uuid,
  completed boolean default true
)
returns public.board_items
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_item public.board_items;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  update public.board_items bi
  set is_done = completed,
      updated_at = now()
  where bi.id = target_item_id
    and bi.type = 'task'
    and public.is_board_member(bi.board_id, auth.uid())
  returning * into updated_item;

  if updated_item.id is null then
    raise exception 'task_not_found_or_no_access' using errcode = 'P0002';
  end if;

  return updated_item;
end;
$$;

alter table public.profiles enable row level security;
alter table public.boards enable row level security;
alter table public.board_members enable row level security;
alter table public.board_invites enable row level security;
alter table public.board_items enable row level security;
alter table public.item_confirmations enable row level security;

alter publication supabase_realtime add table public.board_members;
alter publication supabase_realtime add table public.board_items;
alter publication supabase_realtime add table public.item_confirmations;

create policy "profiles_select_shared_board_members"
on public.profiles
for select
to authenticated
using (
  id = auth.uid()
  or exists (
    select 1
    from public.board_members me
    join public.board_members other
      on other.board_id = me.board_id
    where me.user_id = auth.uid()
      and other.user_id = profiles.id
  )
);

create policy "profiles_update_own"
on public.profiles
for update
to authenticated
using (id = auth.uid())
with check (id = auth.uid());

create policy "profiles_insert_own"
on public.profiles
for insert
to authenticated
with check (id = auth.uid());

create policy "boards_select_members"
on public.boards
for select
to authenticated
using (public.is_board_member(id));

create policy "boards_update_admins"
on public.boards
for update
to authenticated
using (public.is_board_admin(id))
with check (public.is_board_admin(id));

create policy "board_members_select_members"
on public.board_members
for select
to authenticated
using (public.is_board_member(board_id));

create policy "board_members_update_admins"
on public.board_members
for update
to authenticated
using (public.is_board_admin(board_id))
with check (public.is_board_admin(board_id));

create policy "board_members_delete_admin_or_self"
on public.board_members
for delete
to authenticated
using (
  public.is_board_admin(board_id)
  or user_id = auth.uid()
);

create policy "board_invites_select_admins"
on public.board_invites
for select
to authenticated
using (public.is_board_admin(board_id));

create policy "board_items_select_members"
on public.board_items
for select
to authenticated
using (public.is_board_member(board_id));

create policy "board_items_insert_members"
on public.board_items
for insert
to authenticated
with check (
  public.is_board_member(board_id)
  and created_by = auth.uid()
  and (
    assigned_to is null
    or public.is_board_member(board_id, assigned_to)
  )
);

create policy "board_items_update_creator_assignee_or_admin"
on public.board_items
for update
to authenticated
using (
  public.is_board_admin(board_id)
  or created_by = auth.uid()
)
with check (
  public.is_board_member(board_id)
  and (
    assigned_to is null
    or public.is_board_member(board_id, assigned_to)
  )
);

create policy "board_items_delete_creator_or_admin"
on public.board_items
for delete
to authenticated
using (
  public.is_board_admin(board_id)
  or created_by = auth.uid()
);

create policy "item_confirmations_select_members"
on public.item_confirmations
for select
to authenticated
using (
  exists (
    select 1
    from public.board_items bi
    where bi.id = item_confirmations.item_id
      and public.is_board_member(bi.board_id)
  )
);

create policy "item_confirmations_insert_own_for_notice_members"
on public.item_confirmations
for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (
    select 1
    from public.board_items bi
    where bi.id = item_confirmations.item_id
      and bi.type = 'notice'
      and public.is_board_member(bi.board_id)
  )
);

create policy "item_confirmations_delete_own"
on public.item_confirmations
for delete
to authenticated
using (user_id = auth.uid());

revoke all on function public.is_board_member(uuid, uuid) from public, anon, authenticated;
revoke all on function public.is_board_admin(uuid, uuid) from public, anon, authenticated;
revoke all on function public.enforce_board_update_rules() from public, anon, authenticated;
revoke all on function public.enforce_board_member_admin_rules() from public, anon, authenticated;
revoke all on function public.enforce_board_item_update_rules() from public, anon, authenticated;
revoke all on function public.enforce_notice_confirmation_item() from public, anon, authenticated;
revoke all on function public.handle_new_user_profile() from public, anon, authenticated;
revoke all on function public.handle_new_board_admin() from public, anon, authenticated;
revoke all on function public.create_family_board(text, integer) from public, anon, authenticated;
revoke all on function public.create_board_invite(uuid, interval) from public, anon, authenticated;
revoke all on function public.revoke_board_invite(uuid) from public, anon, authenticated;
revoke all on function public.join_board_with_invite(text) from public, anon, authenticated;
revoke all on function public.complete_task(uuid, boolean) from public, anon, authenticated;

grant execute on function public.is_board_member(uuid, uuid) to authenticated;
grant execute on function public.is_board_admin(uuid, uuid) to authenticated;
grant execute on function public.create_family_board(text, integer) to authenticated;
grant execute on function public.create_board_invite(uuid, interval) to authenticated;
grant execute on function public.revoke_board_invite(uuid) to authenticated;
grant execute on function public.join_board_with_invite(text) to authenticated;
grant execute on function public.complete_task(uuid, boolean) to authenticated;

grant usage on schema public to authenticated;
revoke all on public.profiles from anon;
revoke all on public.boards from anon;
revoke all on public.board_members from anon;
revoke all on public.board_invites from anon;
revoke all on public.board_items from anon;
revoke all on public.item_confirmations from anon;
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.boards to authenticated;
grant select, insert, update, delete on public.board_members to authenticated;
grant select, insert, update, delete on public.board_invites to authenticated;
grant select, insert, update, delete on public.board_items to authenticated;
grant select, insert, update, delete on public.item_confirmations to authenticated;
