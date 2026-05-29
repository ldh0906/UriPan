alter table public.board_items
add column tags text[] not null default '{}'::text[];

alter table public.board_items
add constraint board_items_tags_limit check (cardinality(tags) <= 5);
