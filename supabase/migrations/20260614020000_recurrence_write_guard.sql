-- v1.4 Track A3: recurrence write guard.
--
-- 목적: public.board_items.recurrence_id / occurrence_local_date 는 반복 RPC가
-- 관리하는 컬럼이므로 일반 클라이언트가 단건 insert/update 경로에서 임의로 쓰지 못하게 막는다.
--
-- 판정 근거: Supabase PostgREST 직접 클라이언트 쓰기는 current_user = 'authenticated' 로
-- 실행된다. 반면 A2의 SECURITY DEFINER RPC 안에서 발생하는 board_items 쓰기는 함수
-- 소유자(postgres) 권한의 current_user 로 실행되므로 통과한다.
--
-- completeTask 같은 is_done update 는 두 recurrence 컬럼이 불변이면 통과한다.
--
-- 위험/판정 포인트:
--   * current_user 기반 판정은 Supabase의 authenticated 역할 실행 가정에 의존한다.
--   * service_role 등 authenticated 가 아닌 직접 쓰기는 통과하며, 이는 허용으로 간주한다.

-- NOTE: SECURITY INVOKER 여야 한다(중요). SECURITY DEFINER 면 트리거 함수 내부
-- current_user 가 항상 함수 소유자(postgres)로 평가돼 'authenticated' 판정이 절대 참이
-- 되지 않아 가드가 무력화된다. INVOKER 면 직접 클라 쓰기는 current_user='authenticated',
-- A2 RPC(SECURITY DEFINER, postgres 컨텍스트) 내부 쓰기는 current_user='postgres' 로 평가된다.
create or replace function public.guard_recurrence_columns()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if current_user <> 'authenticated' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.recurrence_id is not null or new.occurrence_local_date is not null then
      raise exception 'recurrence_columns_are_managed' using errcode = '42501';
    end if;

    return new;
  end if;

  if tg_op = 'UPDATE' then
    if new.recurrence_id is distinct from old.recurrence_id
      or new.occurrence_local_date is distinct from old.occurrence_local_date then
      raise exception 'recurrence_columns_are_managed' using errcode = '42501';
    end if;

    return new;
  end if;

  return new;
end;
$$;

drop trigger if exists board_items_guard_recurrence_columns on public.board_items;
create trigger board_items_guard_recurrence_columns
before insert or update on public.board_items
for each row execute function public.guard_recurrence_columns();

revoke all on function public.guard_recurrence_columns() from public, anon, authenticated;
