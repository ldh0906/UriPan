# UriPan Codex Task Queue

Pre-written, self-contained prompts so you can run each one with Codex **without Claude**.
Do them **in numeric order** — later tasks assume earlier ones landed.

## How to run one task

From PowerShell in `C:\UriPan`:

```powershell
Get-Content docs\codex-tasks\01-item-author-display-names.md -Raw |
  codex exec --dangerously-bypass-approvals-and-sandbox -o .codex_last.txt -
```

- `--dangerously-bypass-approvals-and-sandbox` is required because the Windows sandbox launcher is broken on this machine (see `.codex` sandbox log). Codex still uses your ChatGPT login (no API billing).
- `-o .codex_last.txt` writes **only the final report** to a small file, so you don't have to scroll the giant streaming log.

Read the result, then **verify yourself**:

```powershell
Get-Content .codex_last.txt
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
```

If analyze + test are green and the report matches what you asked, commit:

```powershell
git add lib test
git commit -m "<short message>"
```

Then delete the temp file: `Remove-Item .codex_last.txt`.

## The queue

| # | File | What it adds |
|---|------|--------------|
| 1 | 01-item-author-display-names.md | Real author/assignee names on items (no more hardcoded '우리') |
| 2 | 02-members-tab-real-list.md | Members tab shows the real member list, roles, capacity |
| 3 | 03-assignee-picker.md | Pick an assignee when adding/editing a task |
| 4 | 04-invite-management.md | Copy / regenerate / revoke invite codes + expiry/full states |
| 5 | 05-leave-board.md | A member can leave the board |
| 6 | 06-datetime-validation.md | Date/time input validation for schedules and tasks |
| 7 | 07-tasks-filter.md | Tasks tab filter: open / mine / done |
| 8 | 08-calendar-week-strip.md | Calendar week strip + selected-date schedule list |
| 9 | 09-today-needs-attention.md | Today highlights overdue tasks + unconfirmed important notices |
| 10 | 10-notices-ordering.md | Notices: important & unconfirmed first, clearer status |

## Rules every task already contains
- Client-side Dart only; do **not** change SQL/migrations unless the task says so.
- Korean UI text is stored as `\u` escapes in `.dart` files — match that style.
- Behavior-preserving: add **optional** params, never remove/rename existing public APIs, keep **all** existing tests passing.
- Mirror existing patterns (`createItem` / `updateItem` / `completeTask` / `confirmNotice`).
- Always end by running format + analyze + test and reporting what passed.
