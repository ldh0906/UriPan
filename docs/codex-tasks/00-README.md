# UriPan Codex Task Queue

Pre-written, self-contained prompts so you can run each one with Codex **without Claude**.
Do them **in numeric order** — later tasks may assume earlier ones landed.

Running context (read this first): [`../claude_memory.md`](../claude_memory.md).

## How to run one task

From PowerShell in `C:\UriPan`:

```powershell
Get-Content docs\codex-tasks\01-*.md -Raw |
  codex exec --dangerously-bypass-approvals-and-sandbox -o .codex_last.txt -
```

- `--dangerously-bypass-approvals-and-sandbox` is required (the Windows sandbox launcher is broken
  on this machine). Codex still uses your ChatGPT login.
- `-o .codex_last.txt` writes only the final report.

Verify, then commit + push:

```powershell
Get-Content .codex_last.txt
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
git add lib test ; git commit -m "<message>" ; git push
Remove-Item .codex_last.txt
```

## Current queue — 로컬 리마인더 (Phase A)

Architecture: "local first → FCM later". Design + decisions (D1–D3, confirmed) in
[`../claude_memory.md`](../claude_memory.md). All client-side / on-device; no SQL.

| # | File | What it adds | Depends on |
|---|------|--------------|-----------|
| 1 | 01-reminders-setup-scheduler.md | Packages + platform setup + `ReminderScheduler` (Local + Noop) | — |
| 2 | 02-reminders-planner.md | Pure `buildReminderPlan` + settings model | 01 |
| 3 | 03-reminders-wiring-toggle.md | Coordinator wiring, permission, 알림 toggle | 01, 02 |

Policy: schedules → all members (start + 1h before); tasks → assignee/creator (10 min before
due); notices → Phase B (FCM). Phase B (true push) is a separate future phase.

## Rules every task carries
- Korean UI text uses `\u` escapes in `.dart` files — match it.
- Behavior-preserving: add **optional** params, never remove/rename existing public APIs, keep **all** existing tests green.
- Mirror existing patterns (`BoardRepository` / `BoardSessionController` / `_runAction` / `_friendlyDatabaseError`).
- Destructive actions need a confirmation dialog **and** a friendly Korean error mapping.
- End by running format + analyze + test and reporting what passed.
- Phase A reminders stay client-side; backend (FCM tokens / Edge Functions) is Phase B.
