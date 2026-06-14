-- v1.4 Track A2: recurring schedules/tasks RPCs.
--
-- 회의(2026-06-14) 확정 모델: A1 스키마 위에 RPC만 얹는다.
--   * board_item_recurrences 는 반복 규칙(local wall-clock)을 저장한다.
--   * board_items occurrence 행은 rolling materialize 하며 starts_at/due_at 만 UTC timestamptz 로 저장한다.
--   * 수정은 시리즈 전체만 지원하고, 오늘(KST) 이전 occurrence 는 삭제하지 않는다.
--   * notice 타입은 반복 제외. v1.4 MVP 는 daily/weekly/monthly, interval_count=1 고정.

create or replace function public.ensure_recurrence_occurrences(
  p_recurrence_id uuid,
  p_through date
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.board_item_recurrences;
  template_item public.board_items;
  today_kst date := (now() at time zone 'Asia/Seoul')::date;
  range_start date;
  range_end date;
  inserted_count integer := 0;
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

  if not public.is_board_member(r.board_id, auth.uid()) then
    raise exception 'membership_required' using errcode = '42501';
  end if;

  if p_through is null then
    raise exception 'through_required' using errcode = '23502';
  end if;

  if p_through < today_kst then
    return 0;
  end if;

  select *
  into template_item
  from public.board_items
  where id = r.parent_item_id;

  if template_item.id is null then
    raise exception 'parent_item_not_found' using errcode = 'P0002';
  end if;

  range_start := greatest(
    r.starts_on,
    coalesce(r.materialized_through + 1, r.starts_on),
    today_kst
  );
  range_end := least(r.ends_on, p_through);

  if range_start > range_end then
    update public.board_item_recurrences bir
    set materialized_through = greatest(coalesce(bir.materialized_through, r.starts_on - 1), range_end)
    where bir.id = r.id;

    return 0;
  end if;

  -- 2026-06-14 기준 태그 스키마 확인:
  -- 지정된 20260530000000_add_board_item_tags.sql 은 별도 board_item_tags 테이블이 아니라
  -- public.board_items.tags text[] 컬럼을 추가한다. 따라서 occurrence 는 seed/template 의 tags 배열을 복사한다.
  with occurrence_dates as (
    select gs.generated_at::date as occurrence_local_date
    from pg_catalog.generate_series(
      range_start::timestamp,
      range_end::timestamp,
      interval '1 day'
    ) as gs(generated_at)
    where r.frequency = 'daily'

    union all

    select gs.generated_at::date as occurrence_local_date
    from pg_catalog.generate_series(
      range_start::timestamp,
      range_end::timestamp,
      interval '1 day'
    ) as gs(generated_at)
    where r.frequency = 'weekly'
      and extract(isodow from gs.generated_at)::smallint = r.by_weekday
      and ((gs.generated_at::date - r.starts_on) % 7) = 0

    union all

    select least(
      months.month_start::date + (r.by_month_day::integer - 1),
      (date_trunc('month', months.month_start) + interval '1 month' - interval '1 day')::date
    ) as occurrence_local_date
    from pg_catalog.generate_series(
      date_trunc('month', range_start)::timestamp,
      date_trunc('month', range_end)::timestamp,
      interval '1 month'
    ) as months(month_start)
    where r.frequency = 'monthly'
  ),
  bounded_dates as (
    select distinct occurrence_local_date
    from occurrence_dates
    where occurrence_local_date between range_start and range_end
  ),
  inserted as (
    insert into public.board_items (
      board_id,
      type,
      title,
      detail,
      starts_at,
      due_at,
      assigned_to,
      created_by,
      requires_confirmation,
      is_done,
      is_pinned,
      recurrence_id,
      occurrence_local_date,
      tags
    )
    select
      r.board_id,
      template_item.type,
      template_item.title,
      template_item.detail,
      case
        when template_item.type = 'schedule'
          then (bd.occurrence_local_date + r.local_time) at time zone r.timezone
        else null
      end,
      case
        when template_item.type = 'schedule'
          then ((bd.occurrence_local_date + r.local_time) at time zone r.timezone)
            + (template_item.due_at - template_item.starts_at)
        when template_item.type = 'task'
          then (bd.occurrence_local_date + r.local_time) at time zone r.timezone
        else null
      end,
      template_item.assigned_to,
      template_item.created_by,
      false,
      false,
      template_item.is_pinned,
      r.id,
      bd.occurrence_local_date,
      template_item.tags
    from bounded_dates bd
    on conflict (recurrence_id, occurrence_local_date)
      where recurrence_id is not null
    do nothing
    returning 1
  )
  select count(*) into inserted_count from inserted;

  update public.board_item_recurrences bir
  set materialized_through = greatest(coalesce(bir.materialized_through, r.starts_on - 1), range_end)
  where bir.id = r.id;

  return inserted_count;
end;
$$;

create or replace function public.create_recurring_board_item(
  p_board_id uuid,
  p_type text,
  p_title text,
  p_detail text default null,
  p_assigned_to uuid default null,
  p_local_time time default null,
  p_frequency text default null,
  p_starts_on date default null,
  p_ends_on date default null,
  p_duration interval default null
)
returns public.board_item_recurrences
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_seed public.board_items;
  created_recurrence public.board_item_recurrences;
  occurrence_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  if not public.is_board_member(p_board_id, auth.uid()) then
    raise exception 'membership_required' using errcode = '42501';
  end if;

  if p_type not in ('schedule', 'task') then
    raise exception 'recurring_type_not_supported' using errcode = '23514';
  end if;

  if p_frequency not in ('daily', 'weekly', 'monthly') then
    raise exception 'invalid_frequency' using errcode = '23514';
  end if;

  if p_title is null or char_length(trim(p_title)) = 0 then
    raise exception 'title_required' using errcode = '23502';
  end if;

  if p_local_time is null or p_starts_on is null or p_ends_on is null then
    raise exception 'recurrence_window_required' using errcode = '23502';
  end if;

  if p_ends_on < p_starts_on then
    raise exception 'invalid_recurrence_window' using errcode = '23514';
  end if;

  if p_duration is not null and p_duration < interval '0 seconds' then
    raise exception 'invalid_duration' using errcode = '22023';
  end if;

  if p_assigned_to is not null and not public.is_board_member(p_board_id, p_assigned_to) then
    raise exception 'assignee_must_be_board_member' using errcode = '23514';
  end if;

  occurrence_at := (p_starts_on + p_local_time) at time zone 'Asia/Seoul';

  insert into public.board_items (
    board_id,
    type,
    title,
    detail,
    starts_at,
    due_at,
    assigned_to,
    created_by,
    requires_confirmation,
    is_done,
    is_pinned,
    occurrence_local_date
  )
  values (
    p_board_id,
    p_type,
    trim(p_title),
    p_detail,
    case when p_type = 'schedule' then occurrence_at else null end,
    case
      when p_type = 'schedule' and p_duration is not null then occurrence_at + p_duration
      when p_type = 'task' then occurrence_at
      else null
    end,
    p_assigned_to,
    auth.uid(),
    false,
    false,
    false,
    p_starts_on
  )
  returning * into created_seed;

  insert into public.board_item_recurrences (
    board_id,
    parent_item_id,
    created_by,
    frequency,
    interval_count,
    timezone,
    starts_on,
    ends_on,
    local_time,
    by_weekday,
    by_month_day,
    month_day_policy,
    materialized_through
  )
  values (
    p_board_id,
    created_seed.id,
    auth.uid(),
    p_frequency,
    1,
    'Asia/Seoul',
    p_starts_on,
    p_ends_on,
    p_local_time,
    case when p_frequency = 'weekly' then extract(isodow from p_starts_on)::smallint else null end,
    case when p_frequency = 'monthly' then extract(day from p_starts_on)::smallint else null end,
    'clamp_to_last_day',
    null
  )
  returning * into created_recurrence;

  update public.board_items
  set recurrence_id = created_recurrence.id
  where id = created_seed.id;

  perform public.ensure_recurrence_occurrences(created_recurrence.id, least(p_ends_on, p_starts_on + 90));

  select *
  into created_recurrence
  from public.board_item_recurrences
  where id = created_recurrence.id;

  return created_recurrence;
end;
$$;

create or replace function public.update_recurring_board_item(
  p_recurrence_id uuid,
  p_title text default null,
  p_detail text default null,
  p_clear_detail boolean default false,
  p_assigned_to uuid default null,
  p_clear_assigned_to boolean default false,
  p_local_time time default null,
  p_ends_on date default null,
  p_duration interval default null
)
returns public.board_item_recurrences
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.board_item_recurrences;
  updated_recurrence public.board_item_recurrences;
  template_item public.board_items;
  today_kst date := (now() at time zone 'Asia/Seoul')::date;
  new_local_time time;
  new_ends_on date;
  template_duration interval;
  parent_occurrence_at timestamptz;
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

  if not (r.created_by = auth.uid() or public.is_board_admin(r.board_id, auth.uid())) then
    raise exception 'owner_or_admin_required' using errcode = '42501';
  end if;

  if not public.is_board_member(r.board_id, auth.uid()) then
    raise exception 'membership_required' using errcode = '42501';
  end if;

  select *
  into template_item
  from public.board_items
  where id = r.parent_item_id
  for update;

  if template_item.id is null then
    raise exception 'parent_item_not_found' using errcode = 'P0002';
  end if;

  if template_item.type not in ('schedule', 'task') then
    raise exception 'recurring_type_not_supported' using errcode = '23514';
  end if;

  if p_title is not null and char_length(trim(p_title)) = 0 then
    raise exception 'title_required' using errcode = '23502';
  end if;

  if p_duration is not null and p_duration < interval '0 seconds' then
    raise exception 'invalid_duration' using errcode = '22023';
  end if;

  if p_assigned_to is not null and not public.is_board_member(r.board_id, p_assigned_to) then
    raise exception 'assignee_must_be_board_member' using errcode = '23514';
  end if;

  new_local_time := coalesce(p_local_time, r.local_time);
  new_ends_on := coalesce(p_ends_on, r.ends_on);

  if new_ends_on < r.starts_on then
    raise exception 'invalid_recurrence_window' using errcode = '23514';
  end if;

  template_duration := case
    when template_item.type = 'schedule' then coalesce(p_duration, template_item.due_at - template_item.starts_at)
    else null
  end;

  parent_occurrence_at := (r.starts_on + new_local_time) at time zone r.timezone;

  -- A1 스키마에는 title/detail/assigned_to/duration 템플릿 컬럼이 없으므로 parent seed item 이
  -- 향후 materialization 템플릿 역할을 겸한다. frequency/starts_on 변경은 MVP 에서 금지한다.
  update public.board_items
  set title = coalesce(trim(p_title), title),
      detail = case when p_clear_detail then null else coalesce(p_detail, detail) end,
      assigned_to = case when p_clear_assigned_to then null else coalesce(p_assigned_to, assigned_to) end,
      starts_at = case when type = 'schedule' then parent_occurrence_at else null end,
      due_at = case
        when type = 'schedule' then parent_occurrence_at + template_duration
        when type = 'task' then parent_occurrence_at
        else null
      end,
      requires_confirmation = false,
      is_done = case when type = 'task' and occurrence_local_date >= today_kst then false else is_done end
  where id = template_item.id
  returning * into template_item;

  update public.board_item_recurrences
  set local_time = new_local_time,
      ends_on = new_ends_on,
      materialized_through = least(coalesce(materialized_through, r.starts_on - 1), today_kst - 1)
  where id = r.id
  returning * into updated_recurrence;

  delete from public.board_items bi
  where bi.recurrence_id = r.id
    and bi.id <> r.parent_item_id
    and bi.occurrence_local_date >= today_kst;

  perform public.ensure_recurrence_occurrences(updated_recurrence.id, least(updated_recurrence.ends_on, today_kst + 90));

  select *
  into updated_recurrence
  from public.board_item_recurrences
  where id = r.id;

  return updated_recurrence;
end;
$$;

revoke all on function public.ensure_recurrence_occurrences(uuid, date) from public, anon, authenticated;
revoke all on function public.create_recurring_board_item(uuid, text, text, text, uuid, time, text, date, date, interval) from public, anon, authenticated;
revoke all on function public.update_recurring_board_item(uuid, text, text, boolean, uuid, boolean, time, date, interval) from public, anon, authenticated;

grant execute on function public.ensure_recurrence_occurrences(uuid, date) to authenticated;
grant execute on function public.create_recurring_board_item(uuid, text, text, text, uuid, time, text, date, date, interval) to authenticated;
grant execute on function public.update_recurring_board_item(uuid, text, text, boolean, uuid, boolean, time, date, interval) to authenticated;

-- A3 후속 권고:
-- 클라이언트가 public.board_items.recurrence_id / occurrence_local_date 를 일반 insert/update 경로에서
-- 임의로 세팅하지 못하게 막는 가드 트리거를 둘 수 있다. v1.4 A2 는 RPC materialization 구현에
-- 집중하고, 기존 board_items 단건 작성 경로와의 호환성 위험을 줄이기 위해 트리거 추가는 보류한다.
