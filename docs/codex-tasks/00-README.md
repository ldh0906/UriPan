# UriPan Codex Task Queue — 코멘트(댓글) 기능

Pre-written, self-contained prompts so you can run each one with Codex **without Claude**.
Do them **in numeric order** — later tasks assume earlier ones landed.

Running context (read first): [`../claude_memory.md`](../claude_memory.md).
Approved design spec: [`../superpowers/specs/2026-06-02-item-comments-design.md`](../superpowers/specs/2026-06-02-item-comments-design.md).

## How to run one task

From PowerShell in `C:\UriPan`:

```powershell
Get-Content docs\codex-tasks\01-*.md -Raw |
  codex exec --dangerously-bypass-approvals-and-sandbox -o .codex_last.txt -
```

Verify, then commit + push:

```powershell
Get-Content .codex_last.txt
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
git add -A ; git commit -m "<message>" ; git push
Remove-Item .codex_last.txt
```

## Current queue — 코멘트 (첫 스키마 변경)

| # | File | What it adds | Depends on |
|---|------|--------------|-----------|
| 1 | 01-comments-schema.md | `item_comments` 테이블 + RLS + realtime publication + grants (SQL only) | — |
| 2 | 02-comments-model-repo.md | `BoardComment` 모델, `commentCount`, repository CRUD, 친절한 상대시간 | 01 |
| 3 | 03-comments-ui.md | `CommentThread` 위젯 + 상세시트/배선 + 카드 💬N 배지 (비실시간) | 02 |
| 4 | 04-comments-realtime.md | 상세시트 열림 동안 해당 item 코멘트 실시간 구독 | 03 |

Decisions (from spec): 스레드는 실시간(D1) / 코멘트 수 배지는 표시하되 카운트는 비실시간(D2, C안) / FCM은 Phase B.

## Rules every task carries
- Korean UI text uses `\u` escapes in **new** `.dart` strings.
- Behavior-preserving: additive only, never remove/rename existing public APIs, keep **all** existing tests green.
- Mirror existing patterns (`item_confirmations` for the table/RLS/realtime; `BoardRepository` Memory+Supabase dual impl; callback-injection from `board_home_screen` → `today_board_screen` → sheet with a repository fallback path; `_runAction` + `_friendlyDatabaseError`).
- Destructive actions (comment delete) need a confirmation dialog **and** a friendly Korean error mapping.
- End by running `dart format lib test` + analyze + test and reporting what passed.
- Comments stay client+Supabase; FCM push is Phase B (do not add it).
