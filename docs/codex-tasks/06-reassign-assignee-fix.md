Task 06 — Bug fix: editing a task cannot change its assignee (UriPan Flutter, cwd C:\UriPan).

PROBLEM: `updateItem` never writes `assigned_to`. The edit sheet shows an assignee dropdown and the draft carries `assignedTo`, but both repositories drop it on update, so re-assigning a task silently fails.

Read first: lib/services/board_repository.dart (updateItem in BOTH SupabaseBoardRepository AND MemoryBoardRepository), lib/widgets/board_action_sheets.dart (edit mode assignee dropdown), lib/models/board_item.dart (copyWith assignedTo uses an _unset sentinel), lib/services/board_session_controller.dart, test/board_session_controller_test.dart (the _FakeBoardRepository.updateItem ALSO drops assignedTo).

BACKEND FACTS (do not change SQL): RLS `board_items_update_creator_assignee_or_admin` WITH CHECK requires `assigned_to is null or is_board_member(board_id, assigned_to)`. A task may be assigned to a member or set to null. type is immutable on update.

IMPLEMENT:
1. SupabaseBoardRepository.updateItem — add to the update map: `'assigned_to': draft.type == BoardItemType.task ? draft.assignedTo : null`.
2. MemoryBoardRepository.updateItem — when building the updated item, set the assignee from the draft: pass `assignedToId: draft.type == BoardItemType.task ? draft.assignedTo : null` to copyWith (copyWith already supports assignedToId via the _unset sentinel, so passing null actually clears it — that is what we want).
3. test/board_session_controller_test.dart `_FakeBoardRepository.updateItem` — mirror reality: set `assignedToId: draft.assignedTo` on the updated copy (so the fake matches the real repos).

TESTS (keep all existing green):
- controller test (memory): create a task assigned to 'user-2', then updateItem with a draft whose assignedTo is 'user-1' -> item.assignedToId == 'user-1'; updateItem again with assignedTo null -> item.assignedToId == null.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Surgical change — do not touch unrelated update fields.
- Behavior-preserving: keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, tests added, and which verify commands passed.
