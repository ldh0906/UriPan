Task 02 — Local reminders: pure planner + settings model (UriPan Flutter, cwd C:\UriPan). Depends on task 01.

Goal: a pure, fully testable function that turns board items into the list of ScheduledReminders for the current user. No platform code here.

Read first: lib/services/notifications/reminder_scheduler.dart (ScheduledReminder from task 01), lib/models/board_item.dart (BoardItem: type, startsAt, dueAt, isDone, assignedToId, createdById, title), docs/claude_memory.md (confirmed policy D1/D2).

POLICY (confirmed):
- Schedules: remind EVERY member (i.e., schedule on this device regardless of who created it) at the start time AND 1 hour before the start time.
- Tasks: remind only when the task is for the current user — assignedToId == currentUserId, or (assignedToId == null && createdById == currentUserId) — not done, at 10 minutes BEFORE dueAt.
- Notices: none in Phase A.
- Only schedule times strictly after `now`. Cap to the soonest `maxCount` (default 60) to respect the iOS 64 pending limit.

IMPLEMENT (new lib/services/notifications/reminder_planner.dart):
1. `class ReminderSettings { final bool enabled; const ReminderSettings({this.enabled = true}); }` (lead times are fixed by policy; only an on/off flag is configurable).
2. `List<ScheduledReminder> buildReminderPlan({ required List<BoardItem> items, required String? currentUserId, required DateTime now, ReminderSettings settings = const ReminderSettings(), int maxCount = 60 })`:
   - If `!settings.enabled`, return const [].
   - Schedules: for each schedule with startsAt != null → candidate reminders at startsAt and startsAt.subtract(1h); title e.g. '일정' (일정), body the item title + a friendly time. (Reuse friendlyDayLabel if helpful, but keep this file dependency-light.)
   - Tasks: for each task matching the policy above with dueAt != null → one reminder at dueAt.subtract(10min); title '할 일' (할 일), body the item title.
   - Drop any candidate whose scheduledAt is <= now. Sort ascending by scheduledAt, take first maxCount.
   - Give each reminder a STABLE id: derive a non-negative int from (item.id + a kind suffix like ':start' / ':pre' / ':due') so the same logical reminder always maps to the same id (e.g. `('${item.id}:pre').hashCode & 0x7fffffff`). Document this.
3. Keep it pure — no Flutter/plugin imports beyond the model + ScheduledReminder.

TESTS (keep ALL existing green) — unit tests for buildReminderPlan:
- a task assigned to the current user → one reminder 10 min before dueAt; a task assigned to someone else → none.
- an unassigned task created by the current user → reminded; created by someone else → none.
- a future schedule → two reminders (start, start-1h); a schedule whose start-1h is already past → only the future one(s).
- past times dropped; `enabled: false` → empty; maxCount caps the count and keeps the soonest.
- stable ids: same items + now produce identical ids across calls.

## Rules
- Pure Dart, no platform/SQL. Korean UI text uses \u escapes.
- Behavior-preserving: additive only, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
