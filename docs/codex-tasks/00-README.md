# UriPan Codex Task Queue (Phase 2 — real-use, features, polish)

Pre-written, self-contained prompts so you can run each one with Codex **without Claude**.
Do them **in numeric order** — later tasks assume earlier ones landed.

Weighting of this phase: **real-use / management 50%, features 30%, quality 20%.**
Everything here is **client-side Dart only** — the Supabase schema, RPCs, RLS and triggers already
support it. Do **not** change SQL/migrations.

## How to run one task

From PowerShell in `C:\UriPan`:

```powershell
Get-Content docs\codex-tasks\01-settings-sheet-signout.md -Raw |
  codex exec --dangerously-bypass-approvals-and-sandbox -o .codex_last.txt -
```

- `--dangerously-bypass-approvals-and-sandbox` is required because the Windows sandbox launcher is
  broken on this machine. Codex still uses your ChatGPT login (no API billing).
- `-o .codex_last.txt` writes **only the final report** to a small file.

Read the result, then **verify yourself**:

```powershell
Get-Content .codex_last.txt
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
```

If analyze + test are green and the report matches what you asked, commit + push:

```powershell
git add lib test
git commit -m "<short message>"
git push
```

Then delete the temp file: `Remove-Item .codex_last.txt`.

## The queue

### Real-use / management (50%)
| # | File | What it adds | Depends on |
|---|------|--------------|-----------|
| 1 | 01-settings-sheet-signout.md | Settings entry + bottom sheet; **sign out from inside a board** | — |
| 2 | 02-board-switcher.md | Switch between boards when you belong to 2+ | 01 |
| 3 | 03-edit-profile.md | Edit my display name + avatar color | 01 |
| 4 | 04-board-settings.md | Admin: rename board, change max members | 01 |
| 5 | 05-member-management.md | Admin: promote / demote / remove a member | — |
| 6 | 06-reassign-assignee-fix.md | **Bug fix:** editing a task could not change its assignee | — |
| 7 | 07-notice-confirmation-roster.md | Show who confirmed / hasn't on a required notice | — |

### Features (30%)
| # | File | What it adds |
|---|------|--------------|
| 8 | 08-search.md | Search items by title / memo / tag |
| 9 | 09-tag-filter.md | Tap a tag to filter to that tag |
| 10 | 10-friendly-dates.md | 오늘 / 내일 / N일 지남 / 요일 labels |
| 11 | 11-bottom-nav-badges.md | Unread-notice / overdue-task count badges on the bottom nav |
| 12 | 12-quick-complete-attention.md | Complete overdue tasks from the attention block; flag overdue in Tasks |

### Quality (20%)
| # | File | What it adds |
|---|------|--------------|
| 13 | 13-pull-to-refresh.md | Pull-to-refresh (keeps the refresh button) |
| 14 | 14-empty-loading-states.md | Consistent empty states + first-load skeleton |
| 15 | 15-accessibility-pass.md | Semantics labels, tap targets, tooltips |

## Rules every task already contains
- Client-side Dart only; do **not** change SQL/migrations.
- Korean UI text is stored as `\u` escapes in `.dart` files — match that style.
- Behavior-preserving: add **optional** params, never remove/rename existing public APIs, keep **all** existing tests passing.
- Mirror existing patterns (`BoardRepository` / `BoardSessionController` / `_runAction` / `_friendlyDatabaseError`).
- Destructive admin actions need a confirmation dialog **and** a friendly Korean error mapping for the DB trigger codes.
- Always end by running format + analyze + test and reporting what passed.
