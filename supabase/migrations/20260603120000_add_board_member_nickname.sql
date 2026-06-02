-- Per-board nickname: a member can set a display name scoped to one board.
-- Global identity (profiles.display_name) stays fixed; nickname overrides it
-- within a single board. Stored on the membership row.

alter table public.board_members
  add column nickname text
  check (nickname is null or char_length(nickname) between 1 and 40);

-- Writes go through this RPC, not a direct UPDATE policy: granting members
-- UPDATE on their own board_members row would also let them flip their own
-- role to 'admin' (the admin-rules trigger does not block self-promotion).
-- A SECURITY DEFINER function touches only the nickname column for the caller.
create or replace function public.set_board_nickname(
  target_board_id uuid,
  new_nickname text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  trimmed text := nullif(btrim(new_nickname), '');
begin
  if caller is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  if trimmed is not null and char_length(trimmed) > 40 then
    raise exception 'nickname_too_long' using errcode = '23514';
  end if;

  update public.board_members
  set nickname = trimmed
  where board_id = target_board_id
    and user_id = caller;

  if not found then
    raise exception 'membership_required' using errcode = '42501';
  end if;
end;
$$;

revoke all on function public.set_board_nickname(uuid, text) from public, anon;
grant execute on function public.set_board_nickname(uuid, text) to authenticated;
