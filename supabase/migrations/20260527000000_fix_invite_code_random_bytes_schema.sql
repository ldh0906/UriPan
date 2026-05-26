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

  if ttl <= interval '0 seconds' or ttl > interval '7 days' then
    raise exception 'invalid_invite_ttl' using errcode = '22023';
  end if;

  if not public.is_board_admin(target_board_id, auth.uid()) then
    raise exception 'admin_required' using errcode = '42501';
  end if;

  update public.board_invites
  set revoked_at = now()
  where board_id = target_board_id
    and revoked_at is null;

  loop
    generated_code := upper(substr(encode(extensions.gen_random_bytes(5), 'hex'), 1, 4))
      || '-'
      || upper(substr(encode(extensions.gen_random_bytes(5), 'hex'), 1, 4));

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
