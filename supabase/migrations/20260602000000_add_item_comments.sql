create table public.item_comments (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.board_items(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index item_comments_item_id_idx on public.item_comments(item_id, created_at);

alter table public.item_comments enable row level security;

alter publication supabase_realtime add table public.item_comments;

create policy "item_comments_select_members"
on public.item_comments
for select
to authenticated
using (
  exists (
    select 1
    from public.board_items bi
    where bi.id = item_comments.item_id
      and public.is_board_member(bi.board_id)
  )
);

create policy "item_comments_insert_own_members"
on public.item_comments
for insert
to authenticated
with check (
  author_id = auth.uid()
  and exists (
    select 1
    from public.board_items bi
    where bi.id = item_comments.item_id
      and public.is_board_member(bi.board_id)
  )
);

create policy "item_comments_delete_own_or_admin"
on public.item_comments
for delete
to authenticated
using (
  author_id = auth.uid()
  or exists (
    select 1
    from public.board_items bi
    where bi.id = item_comments.item_id
      and public.is_board_admin(bi.board_id)
  )
);

revoke all on public.item_comments from anon;
grant select, insert, delete on public.item_comments to authenticated;
