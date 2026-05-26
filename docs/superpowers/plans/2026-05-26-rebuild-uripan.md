# Rebuild UriPan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recreate UriPan as a fresh Flutter project with a small, testable v1 focused on a shared Today board.

**Architecture:** Keep the Flutter platform project freshly generated, then add a compact app layer with mock/local data, focused widgets, and a Today-first navigation model. Preserve project-local agent instructions and specs, but replace old generated/app code and corrupted documentation.

**Tech Stack:** Flutter, Dart, `shared_preferences`, `flutter_test`, `flutter_lints`.

---

## File Structure

- Preserve: `AGENTS.md`
- Preserve: `docs/superpowers/specs/2026-05-26-superpowers-gstack-compound-design.md`
- Preserve: `docs/superpowers/plans/2026-05-26-rebuild-uripan.md`
- Preserve: `.env.example`
- Replace by `flutter create`: `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` if generated, `.metadata`, `pubspec.yaml`, `pubspec.lock`
- Replace app code: `lib/main.dart`
- Create: `lib/models/board_item.dart`
- Create: `lib/data/seed_data.dart`
- Create: `lib/services/board_repository.dart`
- Create: `lib/theme/app_theme.dart`
- Create: `lib/screens/today_board_screen.dart`
- Create: `lib/widgets/section_panel.dart`
- Replace tests: `test/widget_test.dart`
- Replace docs: `README.md`

## Task 1: Resolve Flutter Path

**Files:**
- No file changes.

- [ ] **Step 1: Check PowerShell PATH**

Run:

```powershell
Get-Command flutter -ErrorAction SilentlyContinue | Select-Object Source,Version
```

Expected: either a Flutter executable path or no output.

- [ ] **Step 2: Check common Windows Flutter locations**

Run:

```powershell
Get-ChildItem -Path 'C:\', 'C:\src', 'C:\tools', "$env:USERPROFILE" -Filter flutter.bat -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10 FullName
```

Expected: one or more `flutter.bat` paths, or no output if Flutter is only in WSL.

- [ ] **Step 3: Check WSL Flutter**

Run:

```powershell
wsl bash -lc 'command -v flutter && flutter --version'
```

Expected: Flutter version output. If this fails too, stop and install or locate Flutter before continuing.

## Task 2: Preserve Project Instructions and Specs

**Files:**
- Preserve: `AGENTS.md`
- Preserve: `.env.example`
- Preserve: `docs/`

- [ ] **Step 1: Create a local rebuild backup directory**

Run:

```powershell
New-Item -ItemType Directory -Force -Path 'C:\UriPan\.rebuild_backup' | Out-Null
```

Expected: exit code 0.

- [ ] **Step 2: Copy preserved files**

Run:

```powershell
Copy-Item -LiteralPath 'C:\UriPan\AGENTS.md' -Destination 'C:\UriPan\.rebuild_backup\AGENTS.md' -Force
Copy-Item -LiteralPath 'C:\UriPan\.env.example' -Destination 'C:\UriPan\.rebuild_backup\.env.example' -Force
Copy-Item -LiteralPath 'C:\UriPan\docs' -Destination 'C:\UriPan\.rebuild_backup\docs' -Recurse -Force
```

Expected: exit code 0.

- [ ] **Step 3: Verify backup**

Run:

```powershell
Test-Path 'C:\UriPan\.rebuild_backup\AGENTS.md'
Test-Path 'C:\UriPan\.rebuild_backup\.env.example'
Test-Path 'C:\UriPan\.rebuild_backup\docs\superpowers'
```

Expected: three `True` lines.

## Task 3: Regenerate Flutter Project

**Files:**
- Delete old generated/app files except preserved backup.
- Generate fresh Flutter project files.

- [ ] **Step 1: Remove replaceable old project paths**

Run only after confirming each target resolves under `C:\UriPan`:

```powershell
$targets = @(
  'android','ios','web','lib','test','build','.dart_tool','.idea',
  '.flutter-plugins-dependencies','.metadata','pubspec.lock','pubspec.yaml',
  'README.md','memory.md','flutter-web-server.err.log','flutter-web-server.log',
  'flutter_01.log','flutter_02.log','static-web-server.err.log','static-web-server.log',
  'uripan.iml'
)
$root = (Resolve-Path 'C:\UriPan').Path
foreach ($target in $targets) {
  $path = Join-Path $root $target
  if (Test-Path -LiteralPath $path) {
    $resolved = (Resolve-Path -LiteralPath $path).Path
    if (-not $resolved.StartsWith($root)) { throw "Refusing to remove outside root: $resolved" }
    Remove-Item -LiteralPath $resolved -Recurse -Force
  }
}
```

Expected: exit code 0.

- [ ] **Step 2: Restore preserved files before generation**

Run:

```powershell
Copy-Item -LiteralPath 'C:\UriPan\.rebuild_backup\AGENTS.md' -Destination 'C:\UriPan\AGENTS.md' -Force
Copy-Item -LiteralPath 'C:\UriPan\.rebuild_backup\.env.example' -Destination 'C:\UriPan\.env.example' -Force
Copy-Item -LiteralPath 'C:\UriPan\.rebuild_backup\docs' -Destination 'C:\UriPan\docs' -Recurse -Force
```

Expected: exit code 0.

- [ ] **Step 3: Create fresh Flutter project**

Use the Flutter executable found in Task 1.

Run:

```powershell
flutter create --project-name uripan --platforms android,ios,web .
```

Expected: fresh Flutter project files and exit code 0.

## Task 4: Build the Minimal UriPan v1 App

**Files:**
- Modify: `pubspec.yaml`
- Replace: `lib/main.dart`
- Create: `lib/models/board_item.dart`
- Create: `lib/data/seed_data.dart`
- Create: `lib/services/board_repository.dart`
- Create: `lib/theme/app_theme.dart`
- Create: `lib/screens/today_board_screen.dart`
- Create: `lib/widgets/section_panel.dart`

- [ ] **Step 1: Keep dependencies minimal**

Set `pubspec.yaml` dependencies to include:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.3
```

Expected: no app-only dependencies beyond `shared_preferences`.

- [ ] **Step 2: Add board item model**

Create `lib/models/board_item.dart` with:

```dart
enum BoardItemType { schedule, task, notice }

class BoardItem {
  const BoardItem({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.owner,
    required this.timeLabel,
    this.isDone = false,
    this.isPinned = false,
  });

  final String id;
  final BoardItemType type;
  final String title;
  final String detail;
  final String owner;
  final String timeLabel;
  final bool isDone;
  final bool isPinned;
}
```

- [ ] **Step 3: Add seed data**

Create `lib/data/seed_data.dart` with schedule, task, and notice examples that render without network or login.

- [ ] **Step 4: Add repository abstraction**

Create `lib/services/board_repository.dart` with an abstract `BoardRepository` and an in-memory implementation that returns the seed items.

- [ ] **Step 5: Add app theme**

Create `lib/theme/app_theme.dart` with a restrained, high-contrast Material theme suitable for repeated use.

- [ ] **Step 6: Add reusable section panel**

Create `lib/widgets/section_panel.dart` for section title, count, and child list rendering.

- [ ] **Step 7: Add Today board screen**

Create `lib/screens/today_board_screen.dart` that shows:

- top app title `UriPan`
- date/status summary
- schedule section
- tasks section
- notices section
- compact bottom action row

- [ ] **Step 8: Wire `main.dart`**

Replace generated `lib/main.dart` with a `UriPanApp` that uses `TodayBoardScreen`.

## Task 5: Replace README and Tests

**Files:**
- Replace: `README.md`
- Replace: `test/widget_test.dart`

- [ ] **Step 1: Write new Korean README**

Create a concise README explaining UriPan as a small shared board for schedules, tasks, and notices.

- [ ] **Step 2: Add widget smoke test**

Replace `test/widget_test.dart` with tests that pump `UriPanApp` and assert `UriPan`, `오늘 보드`, `일정`, `할 일`, and `공지` are visible.

## Task 6: Verify

**Files:**
- No planned source changes unless verification exposes a real issue.

- [ ] **Step 1: Format**

Run:

```powershell
dart format lib test
```

Expected: files formatted successfully.

- [ ] **Step 2: Analyze**

Run:

```powershell
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Test**

Run:

```powershell
flutter test
```

Expected: all tests pass.

## Self-Review

- Spec coverage: covers full project regeneration, preserved files, minimal Today-first v1, README rewrite, and test verification.
- Placeholder scan: no `TBD`, `TODO`, or unspecified implementation steps remain.
- Type consistency: model names, repository names, and screen names are consistent across tasks.
