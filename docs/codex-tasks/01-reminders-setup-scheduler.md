Task 01 — Local reminders: deps + platform setup + ReminderScheduler (UriPan Flutter, cwd C:\UriPan).

This is Phase A (local notifications, no server). Goal: a working, test-safe scheduling layer. Read first: pubspec.yaml, lib/main.dart, lib/app.dart, android/app/build.gradle (or build.gradle.kts), android/app/src/main/AndroidManifest.xml, ios/Runner/AppDelegate.swift, ios/Runner/Info.plist, docs/claude_memory.md.

BACKEND FACTS: none — this is fully client-side/on-device. Do NOT change SQL/migrations.

IMPLEMENT:
1. pubspec.yaml — add dependencies: `flutter_local_notifications`, `timezone`, `flutter_timezone`. (`shared_preferences` is already present.) Run `flutter pub get`. Use current stable versions; if zonedSchedule needs Android core-library desugaring, configure it (step 3).
2. New `lib/services/notifications/reminder_scheduler.dart`:
   - `class ScheduledReminder { final int id; final String title; final String body; final DateTime scheduledAt; const ... }` with value equality (== / hashCode) so tests can compare.
   - abstract `ReminderScheduler { Future<void> init(); Future<bool> requestPermission(); Future<void> sync(List<ScheduledReminder> reminders); }`.
   - `class NoopReminderScheduler implements ReminderScheduler` — all methods no-op (init/requestPermission return immediately, requestPermission returns false). Used in memory/demo/tests so NO plugin is ever touched in `flutter test`.
3. New `lib/services/notifications/local_notification_scheduler.dart` — `class LocalNotificationScheduler implements ReminderScheduler` using flutter_local_notifications + timezone:
   - init(): initialize timezone db (`tz.initializeTimeZones()` + set local location from `FlutterTimezone.getLocalTimezone()`), initialize the plugin with Android + Darwin settings.
   - requestPermission(): request notification permission (Android 13+ and iOS) via the plugin's platform-specific implementations; return whether granted.
   - sync(reminders): cancelAll, then for each reminder `zonedSchedule(id, title, body, tz.TZDateTime.from(scheduledAt, tz.local), details, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle)`. Use a single NotificationDetails (an Android channel id like 'uripan_reminders' / name '알림', and default Darwin details). Skip reminders whose scheduledAt is in the past.
   - Keep ALL plugin usage inside this file only.
4. Platform config:
   - Android: in AndroidManifest.xml add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`. In android/app/build.gradle(.kts) enable core library desugaring (`coreLibraryDesugaringEnabled = true` and `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` or current) and ensure minSdk is high enough for the plugin. Add the flutter_local_notifications receivers only if required by the installed version's README (inexact mode avoids exact-alarm permission).
   - iOS: in AppDelegate.swift register for notifications as the plugin README requires (set UNUserNotificationCenter delegate). No paid entitlement needed for local notifications.
   Follow the flutter_local_notifications README for the exact, version-correct setup.

TESTS (keep ALL existing tests green):
- A unit test constructing `ScheduledReminder` and asserting value equality, and that `NoopReminderScheduler` can be created and its methods complete without touching any platform plugin.

## Rules
- Client-side / on-device only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes in .dart files — match it.
- `flutter test` must NOT invoke the real plugin (use NoopReminderScheduler in tests).
- Behavior-preserving: additive only, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed (incl. native files) with line counts, packages added with versions, Korean strings introduced, tests added, and which verify commands passed. Note any platform setup that still needs a real device to validate.
