-- v1.4 Track A1: recurring schedules/tasks — schema only.
--
-- 회의(2026-06-14) 확정 모델: 하이브리드.
--   * board_item_recurrences = 반복 "규칙"만 저장(local wall-clock).
--   * 실제 화면/완료/댓글/알림 대상은 board_items occurrence 행으로 materialize.
--   * occurrence 의 starts_at/due_at 만 기존 규칙대로 UTC timestamptz 로 저장.
-- occurrence 생성/clamp/회차 완료 RPC 는 Track A2(후속 마이그레이션). 이 파일은
-- 스키마(테이블/컬럼/제약/인덱스/RLS/realtime)만 깐다.
--
-- 신규 컬럼은 전부 nullable 이라 구버전 클라/기존 단건 item 은 영향 없음(backfill 불필요).

-- 1. 반복 규칙 테이블. board_id 비정규화 + is_board_member RLS 패턴(v1.3) 재사용.
create table public.board_item_recurrences (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references public.boards(id) on delete cascade,
  -- 사용자가 반복 항목을 만들 때 생기는 첫 occurrence(seed) board_items 행.
  parent_item_id uuid not null unique
    references public.board_items(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,

  frequency text not null check (frequency in ('daily', 'weekly', 'monthly')),
  -- v1.4 MVP 는 매일/매주/매월만. 격일/격주/매N월은 이월이라 1로 고정.
  interval_count integer not null default 1 check (interval_count = 1),

  -- 규칙은 UTC instant 가 아니라 지역 wall-clock. v1.4 공식 지원은 Asia/Seoul.
  timezone text not null default 'Asia/Seoul',
  starts_on date not null,
  ends_on date not null,
  local_time time not null,

  -- weekly: ISO weekday(월=1 .. 일=7). 시작일의 요일로 자동 결정.
  by_weekday smallint check (by_weekday between 1 and 7),
  -- monthly: 1..31. 없는 날짜는 그달 마지막 날로 clamp(2026-06-14 확정, UI 옵션 없음).
  by_month_day smallint check (by_month_day between 1 and 31),
  month_day_policy text not null default 'clamp_to_last_day'
    check (month_day_policy in ('clamp_to_last_day')),

  -- 클라 rolling materialization 진척(어느 날짜까지 occurrence 를 깔았는지).
  materialized_through date,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  check (ends_on >= starts_on),
  -- frequency 별로 필요한 컬럼만 존재하도록 강제.
  check (
    (frequency = 'daily'   and by_weekday is null     and by_month_day is null)
    or (frequency = 'weekly'  and by_weekday is not null  and by_month_day is null)
    or (frequency = 'monthly' and by_weekday is null     and by_month_day is not null)
  )
);

-- 2. board_items 에 occurrence 연결 컬럼 추가(nullable = 단건 item).
alter table public.board_items
  add column if not exists recurrence_id uuid
    references public.board_item_recurrences(id) on delete set null,
  add column if not exists occurrence_local_date date;

-- occurrence 행이면 로컬 날짜는 반드시 존재(단건 item 은 둘 다 null). 기존 행은
-- recurrence_id is null 이라 통과 → backfill 불필요. 재실행 안전하게 guard.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'board_items_recurrence_requires_local_date'
      and conrelid = 'public.board_items'::regclass
  ) then
    alter table public.board_items
      add constraint board_items_recurrence_requires_local_date
      check (recurrence_id is null or occurrence_local_date is not null);
  end if;
end;
$$;

-- 같은 규칙에서 한 로컬 날짜에 occurrence 는 하나만(rolling 재실행 idempotent).
create unique index if not exists board_items_recurrence_occurrence_unique
  on public.board_items(recurrence_id, occurrence_local_date)
  where recurrence_id is not null;

-- 3. board_id 무결성: 규칙의 board_id 는 항상 parent item 의 board 를 따른다
-- (클라가 board_id 를 임의로 보내도 트리거가 부모에서 강제). set_item_child_board_id 와 동일 패턴.
create or replace function public.set_recurrence_board_id()
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
  where id = new.parent_item_id;

  if parent_board_id is null then
    raise exception 'item_not_found' using errcode = 'P0002';
  end if;

  new.board_id := parent_board_id;
  return new;
end;
$$;

drop trigger if exists board_item_recurrences_set_board_id on public.board_item_recurrences;
create trigger board_item_recurrences_set_board_id
before insert or update on public.board_item_recurrences
for each row execute function public.set_recurrence_board_id();

drop trigger if exists board_item_recurrences_set_updated_at on public.board_item_recurrences;
create trigger board_item_recurrences_set_updated_at
before update on public.board_item_recurrences
for each row execute function app_private.set_updated_at();

-- 4. RLS: v1.3 직접 멤버십 체크 패턴.
alter table public.board_item_recurrences enable row level security;

drop policy if exists "board_item_recurrences_select_members" on public.board_item_recurrences;
create policy "board_item_recurrences_select_members"
on public.board_item_recurrences
for select
to authenticated
using (public.is_board_member(board_id));

drop policy if exists "board_item_recurrences_insert_own_members" on public.board_item_recurrences;
create policy "board_item_recurrences_insert_own_members"
on public.board_item_recurrences
for insert
to authenticated
with check (
  created_by = auth.uid()
  and public.is_board_member(board_id)
);

drop policy if exists "board_item_recurrences_update_creator_or_admin" on public.board_item_recurrences;
create policy "board_item_recurrences_update_creator_or_admin"
on public.board_item_recurrences
for update
to authenticated
using (
  created_by = auth.uid()
  or public.is_board_admin(board_id)
)
with check (public.is_board_member(board_id));

drop policy if exists "board_item_recurrences_delete_creator_or_admin" on public.board_item_recurrences;
create policy "board_item_recurrences_delete_creator_or_admin"
on public.board_item_recurrences
for delete
to authenticated
using (
  created_by = auth.uid()
  or public.is_board_admin(board_id)
);

-- 5. 인덱스: 보드 스코프 접근 경로 + rolling 윈도우 쿼리.
create index if not exists board_item_recurrences_board_window_idx
  on public.board_item_recurrences(board_id, starts_on, ends_on);
create index if not exists board_items_board_recurrence_idx
  on public.board_items(board_id, recurrence_id, occurrence_local_date)
  where recurrence_id is not null;

-- 6. Realtime: board_id 필터 DELETE 이벤트 수신 위해 replica identity full(v1.3 자식 테이블과 동일).
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'board_item_recurrences'
  ) then
    alter publication supabase_realtime add table public.board_item_recurrences;
  end if;
end;
$$;

alter table public.board_item_recurrences replica identity full;

revoke all on function public.set_recurrence_board_id() from public, anon, authenticated;
