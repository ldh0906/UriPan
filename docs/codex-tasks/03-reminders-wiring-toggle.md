Task 03 — Local reminders: coordinator wiring + permission + settings toggle (UriPan Flutter, cwd C:\UriPan). Depends on tasks 01 + 02.

Goal: actually schedule the reminders as data changes, request permission once, and let the user turn reminders on/off.

Read first: lib/screens/board_home_screen.dart (controller listener, items, client.auth.currentUser), lib/services/board_session_controller.dart, lib/services/notifications/reminder_scheduler.dart (task 01), lib/services/notifications/reminder_planner.dart (task 02), lib/widgets/board_settings_sheet.dart, lib/app.dart (constructs repository; decide where to inject the scheduler), test/widget_test.dart, test/board_session_controller_test.dart, docs/claude_memory.md.

IMPLEMENT:
1. Injection: `BoardHomeScreen` (and/or UriPanApp) gains an optional `ReminderScheduler? scheduler`. In production use `LocalNotificationScheduler` when a real Supabase client is present; default to `NoopReminderScheduler` otherwise (memory/demo) and in all existing tests (so no plugin is touched).
2. Coordinator (in `_BoardHomeScreenState`):
   - On first successful board load: `await scheduler.init()` then, if reminders are enabled, `await scheduler.requestPermission()` (once).
   - Whenever the controller notifies and items are loaded, recompute `buildReminderPlan(items: controller.items, currentUserId: client.auth.currentUser?.id, now: DateTime.now(), settings: <current settings>)` and call `scheduler.sync(plan)`. Debounce/guard so it is not spammed (e.g. only re-sync when items or settings change). Wrap in try/catch so a scheduling failure never breaks the UI.
3. Settings persistence: a tiny `ReminderPreferences` helper over `shared_preferences` (already a dependency) storing the enabled flag (default true). Load on startup; expose to the coordinator.
4. Settings sheet: add an "알림" (알림) SwitchListTile. Toggling off → persist false and `scheduler.sync(const [])` (cancel all); toggling on → persist true, requestPermission if needed, and re-sync the current plan.

TESTS (keep ALL existing green) — use a fake ReminderScheduler that records calls:
- when items change, the coordinator calls `sync` with a plan whose length matches buildReminderPlan for that data + currentUserId.
- turning the toggle off calls `sync` with an empty list; turning it on re-syncs.
- existing tests still pass with the default NoopReminderScheduler (no plugin calls).

## Rules
- Client-side / on-device only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- Scheduling must never throw into the UI; guard it.
- Behavior-preserving: add OPTIONAL params, inject Noop in tests, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed. Note that end-to-end notification delivery needs a real device to confirm.
