Task 07 — Notice confirmation roster: who confirmed / who hasn't (UriPan Flutter, cwd C:\UriPan).

GOAL: on a required notice's detail sheet, show which members have confirmed and which have not. The data is already fetched.

Read first: lib/services/board_repository.dart (loadBoardItems already selects `item_confirmations(user_id)`; see `_itemFromRow`), lib/models/board_item.dart (BoardItem: confirmationCount, isConfirmedByMe), lib/widgets/item_detail_sheet.dart, lib/screens/today_board_screen.dart (`_showItemDetail`, widget.members), lib/widgets/common_widgets.dart (MemberAvatar), test/widget_test.dart.

BACKEND FACTS (do not change SQL): `item_confirmations(item_id, user_id)` is selectable by board members and is already joined into the item select. No SQL changes.

IMPLEMENT:
1. lib/models/board_item.dart — add `final List<String> confirmedUserIds;` (default const []). Keep `confirmationCount` working (it can stay a separate field, or derive from confirmedUserIds.length — your call, but keep existing constructors/tests valid by giving it a default). Add it to copyWith.
2. SupabaseBoardRepository._itemFromRow — populate `confirmedUserIds` from the confirmations list (the user_id of each confirmation map). Keep `confirmationCount` and `isConfirmedByMe` behaving as before.
3. MemoryBoardRepository + test fakes — when confirming/unconfirming, also maintain confirmedUserIds if you derive count from it; otherwise leave confirmedUserIds default. Keep existing confirmNotice count behavior intact.
4. ItemDetailSheet — accept an optional `List<BoardMember> members`. For a required-confirmation notice, render a roster: a "확인함" group (members whose userId is in confirmedUserIds, with MemberAvatar + name) and a "미확인" group (the rest). Hide the roster if members is empty.
5. today_board_screen.dart `_showItemDetail` — pass `members: widget.members` to ItemDetailSheet.

TESTS (keep all existing green):
- widget test: a required notice with confirmedUserIds containing one member and a second un-confirmed member -> the detail sheet lists the first under '확인함' and the second under '미확인'.

## Rules
- Client-side Dart only. Do NOT change SQL/migrations.
- Korean UI text uses \u escapes — match it.
- Behavior-preserving: add OPTIONAL params/fields with defaults, keep ALL existing tests green.

## Verify (run, report exactly what passed)
- `dart format lib test`
- `C:\Users\a3030\development\flutter\bin\flutter.bat analyze`
- `C:\Users\a3030\development\flutter\bin\flutter.bat test`

## Report
Files changed with line counts, Korean strings introduced, tests added, and which verify commands passed.
