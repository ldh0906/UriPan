# UriPan Development Memory

## English

### What has been built

- Rebuilt UriPan around a family-only board model backed by Supabase.
- Added Supabase initialization through `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` dart defines, with an in-memory fallback when Supabase config is missing.
- Implemented email/password login, signup, and magic-link entry points.
- Added local auth input validation so blank or invalid signup payloads are blocked before Supabase. This prevents the confusing `anonymous sign-ins are disabled` failure path.
- Mapped common Supabase Auth errors to Korean user-facing messages instead of showing raw backend/provider errors.
- Added an explicit anonymous-session guard. If an anonymous Supabase session is ever present, the app signs it out and returns to the normal login flow.
- Implemented board creation with a maximum member count.
- Implemented invite-code generation restricted to the board admin, which is the initial board creator.
- Implemented joining a family board with an invite code.
- Implemented board item creation and task completion.
- Added active-board Realtime subscriptions for board items, item confirmations, and board membership changes.
- Preserved the selected board after creating or joining a board instead of falling back to the first board.
- Added a dedicated board-load error screen so data/RLS/network failures are not mistaken for "no board yet."
- Added `AuthInputValidator` and unit coverage for empty email, invalid password, short password, and valid credentials.
- Added Supabase schema, RLS policies, RPCs, triggers, and live database hardening:
  - `profiles`
  - `boards`
  - `board_members`
  - `board_invites`
  - `board_items`
  - `item_confirmations`
- Applied live Supabase migration `qa_lock_trigger_functions_and_realtime`.
- Revoked anonymous access to UriPan public tables.
- Revoked direct execute access to trigger-only functions:
  - `handle_new_user_profile`
  - `handle_new_board_admin`
- Verified live DB function privileges:
  - anonymous users cannot execute app RPCs or trigger-only functions.
  - authenticated users can execute only intended app RPCs.
- Verified live Realtime publication includes:
  - `board_members`
  - `board_items`
  - `item_confirmations`

### Current caveats

- `flutter` and `dart` are not available on this machine PATH in the current shell, so local format/analyze/test could not be run after the latest QA edits.
- Signup may still require email confirmation depending on Supabase Auth dashboard settings.
- Invite codes are currently simple and usable for a private family app, but should be lengthened and rate-limited before any public or broader release.
- Task completion currently allows board members through the RPC path. The final product rule should decide whether only admins/creators/assignees can complete tasks.
- Realtime refresh currently uses setState reload behavior. It is enough for v1 family sync, but later should move to a cleaner board-state controller.

### Next work

1. Restore or locate Flutter/Dart on PATH, then run:
   - `dart format lib test`
   - `flutter analyze`
   - `flutter test`
2. Manually test the live Supabase flow:
   - signup
   - login
   - create board
   - generate invite code as admin
   - join from another family account
   - add item
   - complete task
   - verify Realtime sync between two sessions
3. Improve invite-code security:
   - use longer invite codes
   - add rate limiting or server-side attempt throttling
   - optionally add invite copy/share UI
4. Decide task permission policy and align both RLS and RPC behavior.
5. Continue design restoration toward the pre-refactor visual style:
   - softer family-board feeling
   - less generic dashboard chrome
   - keep the current functional flows intact
6. Add widget/integration tests for:
   - auth validation and friendly error mapping
   - board-load failure screen
   - create board flow
   - join invite flow
   - admin-only invite generation
7. Add a lightweight release checklist before using this with the family:
   - Supabase Auth email settings checked
   - RLS smoke checks passed
   - mobile viewport checked
   - invite and join tested with two real accounts

## Korean Translation

### 지금까지 만든 것

- UriPan을 Supabase 기반 가족 전용 보드 모델로 다시 구성했습니다.
- `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` dart define으로 Supabase를 초기화하고, 설정이 없으면 인메모리 데이터로 동작하게 했습니다.
- 이메일/비밀번호 로그인, 회원가입, 매직링크 진입점을 구현했습니다.
- 회원가입 입력 검증을 추가해서 빈 이메일/비밀번호나 잘못된 값이 Supabase로 전송되지 않게 했습니다. 그래서 `anonymous sign-ins are disabled` 같은 헷갈리는 오류 경로를 막았습니다.
- Supabase Auth 원문 에러를 그대로 보여주지 않고 한국어 사용자 메시지로 바꾸도록 했습니다.
- 익명 Supabase 세션이 남아 있는 경우 자동으로 로그아웃시키고 정상 로그인 화면으로 돌려보내는 방어 로직을 추가했습니다.
- 최대 인원 수를 정해서 보드를 만들 수 있게 했습니다.
- 초대코드는 보드 admin, 즉 최초 생성자만 만들 수 있게 했습니다.
- 초대코드로 가족 보드에 참가하는 기능을 구현했습니다.
- 보드 항목 추가와 할 일 완료 기능을 구현했습니다.
- 활성 보드에 대해 Realtime 구독을 추가했습니다:
  - 보드 항목 변경
  - 공지 확인 변경
  - 보드 멤버 변경
- 보드 생성이나 참가 이후 첫 번째 보드로 튀지 않고 해당 보드를 유지하도록 했습니다.
- 보드 로딩 실패 화면을 추가해서 RLS, 네트워크, 세션 문제를 "보드 없음"으로 오해하지 않게 했습니다.
- `AuthInputValidator`를 추가했고 빈 이메일, 빈 비밀번호, 짧은 비밀번호, 정상 입력에 대한 테스트를 추가했습니다.
- Supabase 스키마, RLS 정책, RPC, 트리거, 보안 보강을 추가했습니다:
  - `profiles`
  - `boards`
  - `board_members`
  - `board_invites`
  - `board_items`
  - `item_confirmations`
- 라이브 Supabase에 `qa_lock_trigger_functions_and_realtime` 마이그레이션을 적용했습니다.
- 익명 사용자에게 UriPan public 테이블 권한이 없도록 정리했습니다.
- 트리거 전용 함수의 직접 실행 권한을 차단했습니다:
  - `handle_new_user_profile`
  - `handle_new_board_admin`
- 라이브 DB 권한을 확인했습니다:
  - 익명 사용자는 앱 RPC와 트리거 전용 함수를 실행할 수 없습니다.
  - authenticated 사용자는 의도한 앱 RPC만 실행할 수 있습니다.
- 라이브 Realtime publication에 아래 테이블이 포함된 것을 확인했습니다:
  - `board_members`
  - `board_items`
  - `item_confirmations`

### 현재 주의할 점

- 현재 셸 PATH에서 `flutter`, `dart`를 찾을 수 없어 최신 QA 수정 이후 로컬 format/analyze/test는 실행하지 못했습니다.
- Supabase Auth 대시보드 설정에 따라 회원가입 후 이메일 확인이 필요할 수 있습니다.
- 초대코드는 가족끼리 쓰는 v1에는 충분하지만, 공개 배포나 더 넓은 사용 전에는 길이를 늘리고 rate limit을 넣는 편이 좋습니다.
- 할 일 완료 권한은 현재 RPC 기준으로 보드 멤버에게 열려 있습니다. 최종 제품 정책에서 admin/작성자/담당자만 가능한지 결정하고 RLS와 RPC를 맞춰야 합니다.
- Realtime 갱신은 현재 setState 기반입니다. 가족용 v1 동기화에는 충분하지만, 이후에는 보드 상태 컨트롤러로 정리하는 편이 좋습니다.

### 다음에 할 일

1. Flutter/Dart PATH를 복구하거나 위치를 확인한 뒤 실행합니다:
   - `dart format lib test`
   - `flutter analyze`
   - `flutter test`
2. 실제 Supabase 흐름을 수동 테스트합니다:
   - 회원가입
   - 로그인
   - 보드 생성
   - admin으로 초대코드 생성
   - 다른 가족 계정으로 참가
   - 항목 추가
   - 할 일 완료
   - 두 세션 사이 Realtime 동기화 확인
3. 초대코드 보안을 개선합니다:
   - 더 긴 초대코드 사용
   - 서버 측 시도 제한 또는 rate limit 추가
   - 필요하면 초대 복사/공유 UI 추가
4. 할 일 완료 권한 정책을 결정하고 RLS와 RPC 동작을 일치시킵니다.
5. 리팩토링 전 디자인 느낌으로 계속 복원합니다:
   - 더 부드러운 가족 보드 느낌
   - 덜 일반적인 대시보드 느낌
   - 현재 구현된 기능 흐름은 유지
6. 위젯/통합 테스트를 추가합니다:
   - 인증 입력 검증과 친절한 에러 메시지
   - 보드 로딩 실패 화면
   - 보드 생성 흐름
   - 초대코드 참가 흐름
   - admin 전용 초대코드 생성
7. 가족끼리 실제 사용하기 전 간단한 릴리스 체크리스트를 완료합니다:
   - Supabase Auth 이메일 설정 확인
   - RLS 스모크 체크 통과
   - 모바일 화면 확인
   - 실제 계정 두 개로 초대와 참가 테스트
