Task 01 — Comments: backend schema migration (UriPan Flutter, cwd C:\UriPan). First schema change since Phase 2.

Goal: add the `item_comments` table with RLS, realtime, and grants, mirroring the existing `item_confirmations` design. SQL only — no Dart in this task.

Read first: supabase/migrations/20260526000000_family_board_schema.sql (study the `item_confirmations` table, its RLS policies, the `alter publication supabase_realtime add table ...` lines, the anon revoke / authenticated grant block, and helper functions `public.is_board_member` / `public.is_board_admin`), docs/supabase/rls-checks.sql, docs/claude_memory.md, docs/superpowers/specs/2026-06-02-item-comments-design.md.

IMPLEMENT:
1. New file supabase/migrations/20260602000000_add_item_comments.sql:
   - Create table public.item_comments:
     - id uuid primary key default gen_random_uuid()
     - item_id uuid not null references public.board_items(id) on delete cascade
     - author_id uuid not null references auth.users(id) on delete cascade
     - body text not null check (char_length(body) between 1 and 1000)
     - created_at timestamptz not null default now()
   - Index: create index item_comments_item_id_idx on public.item_comments(item_id, created_at);
   - alter table public.item_comments enable row level security;
   - alter publication supabase_realtime add table public.item_comments;
   - Policies (to authenticated):
     - select: USING ( exists (select 1 from public.board_items bi where bi.id = item_comments.item_id and public.is_board_member(bi.board_id)) )
     - insert: WITH CHECK ( author_id = auth.uid() and exists (select 1 from public.board_items bi where bi.id = item_comments.item_id and public.is_board_member(bi.board_id)) )
     - delete: USING ( author_id = auth.uid() or exists (select 1 from public.board_items bi where bi.id = item_comments.item_id and public.is_board_admin(bi.board_id)) )
   - revoke all on public.item_comments from anon;
   - grant select, insert, delete on public.item_comments to authenticated;  (no update — comments are not editable)
2. Update docs/supabase/rls-checks.sql: append a section with check queries for item_comments mirroring the item_confirmations checks (a member can select/insert/delete own; a non-member is blocked; an admin can delete others' comments). Match the file's existing style.

## Rules
- SQL only. Do NOT change any Dart. Mirror item_confirmations exactly in structure.
- Behavior-preserving: additive migration; do not edit prior migration files.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`
(These confirm no Dart broke; the SQL itself is validated when applied to Supabase — note that remote apply is a separate deploy step and is NOT done here.)

## Report
Files changed with line counts, the exact policy SQL, and which verify commands passed. Note that the migration has not been applied to any remote Supabase project yet.
