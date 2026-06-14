-- v1.4 Track A4: recurring series deletion RPC.
--
-- 반복 시리즈 삭제 정책: 오늘(KST) 이전 occurrence 는 standalone 기록으로 보존하고,
-- 오늘(KST) 이후 occurrence 만 삭제한 뒤 반복 규칙을 삭제한다.
-- 남은 과거 occurrence 는 A1 FK on delete set null 로 recurrence_id 가 null 이 된다.
-- 이 동작은 A3 가드가 recurrence_id / occurrence_local_date 를 null 로 비우는 update 를
-- 허용하도록 정교화되어 있어야 authenticated 컨텍스트에서도 통과한다.

create or replace function public.delete_recurring_series(
  p_recurrence_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.board_item_recurrences;
  today_kst date := (now() at time zone 'Asia/Seoul')::date;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select *
  into r
  from public.board_item_recurrences
  where id = p_recurrence_id
  for update;

  if r.id is null then
    raise exception 'recurrence_not_found' using errcode = 'P0002';
  end if;

  if not (r.created_by = auth.uid() or public.is_board_admin(r.board_id)) then
    raise exception 'owner_or_admin_required' using errcode = '42501';
  end if;

  delete from public.board_items
  where recurrence_id = p_recurrence_id
    and occurrence_local_date >= today_kst;

  delete from public.board_item_recurrences
  where id = p_recurrence_id;
end;
$$;

revoke all on function public.delete_recurring_series(uuid) from public, anon, authenticated;
grant execute on function public.delete_recurring_series(uuid) to authenticated;
