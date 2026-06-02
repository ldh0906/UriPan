# UriPan — Claude/Codex 러닝 메모리

> 세션이 바뀌어도 컨텍스트를 잃지 않기 위한 in-repo 메모리. 새 세션/Codex 단독 실행 전에 먼저 읽기.
> 마지막 갱신: 2026-06-03 (Warm Stone 디자인 오버홀 + 모바일 QA 블로커 픽스 + 로그인/댓글 UI 고도화 + 로그인 상태 유지)

> ✅ **마이그레이션 2개 원격 적용 확인됨 (2026-06-03)**: `20260602000000_add_item_comments.sql`, `20260603000000_add_leave_board_rpc.sql`.
> REST로 검증: item_comments 테이블/컬럼 존재, leave_board RPC 존재, anon에 grant revoke까지 반영(42501). 더 이상 `supabase db push` 불필요.

## 1. 제품 한 줄
가까운 사람들(가족·친구·룸메·스터디·팀플)이 **일정·할 일·공지**를 한 화면에서 함께 보는 공유 보드. 핵심 약속: *"말했잖아 / 언제? / 못 봤는데?"를 줄인다.* 자세한 비전은 `README.md`.

## 2. 스택 & 아키텍처
- **Flutter** 앱 + **Supabase**(Auth / Postgres / Realtime). Supabase 미설정 시 인메모리 샘플로 구동.
- 인증: 아이디/비밀번호 → 내부적으로 `id@auth.uripan.app` 합성 이메일. email confirmation off 전제.
- 레이어:
  - `lib/services/board_repository.dart` — `BoardRepository`(추상) + `MemoryBoardRepository` + `SupabaseBoardRepository`. 모든 데이터 접근의 단일 통로.
  - `lib/services/board_session_controller.dart` — `BoardSessionController`(ChangeNotifier). 상태/액션, `_runAction`로 에러 래핑, stale-request 가드.
  - `lib/screens/board_home_screen.dart` — 컨트롤러 연결, `_friendlyDatabaseError`(트리거 코드→한국어), `_runAction`→`_message` 배너.
  - `lib/screens/today_board_screen.dart` — 탭(오늘/일정/할일/공지/가족), 컨트롤드 렌더, 콜백 주입. 상세시트 수정/삭제는 `canManageItem`(관리자 OR 항목 생성자=`createdById`)일 때만 노출.
  - `lib/screens/login_screen.dart` — 브랜드 카드형 로그인(고도화). 비번 표시 토글, 에러/성공 배너, **"로그인 상태 유지" 체크박스(기본 ON)**. `lib/screens/auth_gate.dart` — 세션 유무로 로그인/홈 분기.
  - 위젯: `board_header.dart`(헤더 — 제목+새로고침+설정+검색+추가 버튼. 초대는 헤더에서 빠지고 멤버 탭 `MembersPanel`로 이동), `board_settings_sheet.dart`(설정/보드전환/프로필), `board_item_card.dart`, `item_detail_sheet.dart`, `comment_thread.dart`(채팅 버블형 댓글 UI), `common_widgets.dart`(AppBottomNav·BoardTab·SoftCard·MemberAvatar·EmptyState 등), `board_action_sheets.dart`(추가/수정 시트).
  - 모델: `lib/models/board_item.dart` — BoardItem/BoardItemDraft/BoardSummary/BoardMember/BoardInvite/UserProfile/BoardComment, `isForDate`, `boardItemMatchesQuery`, `normalizeBoardItemTags`. BoardItem.`createdById`(권한 게이트용), `commentCount`.
  - `lib/services/friendly_date.dart` — `friendlyDayLabel`(오늘/내일/N일 지남/요일), `friendlyRelativeTime`(방금/N분 전/어제/M.D).
  - `lib/services/session_preferences.dart` — `SessionPreferences`(shared_preferences). "로그인 상태 유지" 저장. OFF면 `main.dart`가 콜드 스타트 때 `signOut()`으로 세션 정리.
- **백엔드 스키마**: `supabase/migrations/` (family_board_schema 등).
  - 테이블: profiles, boards, board_members, board_invites, board_items, item_confirmations.
  - RPC: create_family_board, create_board_invite, revoke_board_invite, join_board_with_invite, complete_task, is_board_member/admin, **leave_board**(적용됨 — 방장 나가면 다음 관리자/최고참에게 방장 위임, 마지막이면 보드 삭제).
  - 트리거 에러코드(→ 한국어 매핑 대상): creator_admin_required, last_admin_required, max_members_below_current_count, board_full, invalid/expired/revoked_invite, already_joined, admin_required.
  - RLS: 멤버/관리자 기준. profiles 본인 수정 허용. Realtime publication: board_members, board_items, item_confirmations, item_comments. 테이블: profiles, boards, board_members, board_invites, board_items, item_confirmations, item_comments.

## 3. 작업 방식 (역할 분담)
- **Claude = PM/QA**: 설계·QA·검증·커밋/푸시. Codex 산출물을 라인 단위로 검증.
- **Codex = dev**: 실제 구현. 호출 경로:
  - MCP: `mcp__codex__codex` (sandbox=`danger-full-access`, approval-policy=`never`, cwd=`C:\UriPan`).
  - 또는 PowerShell: `Get-Content docs\codex-tasks\NN-*.md -Raw | codex exec --dangerously-bypass-approvals-and-sandbox -o .codex_last.txt -`
- **검증**: `dart format lib test` → `C:\Users\a3030\development\flutter\bin\flutter.bat analyze` → `... test`. (이 세션에선 flutter 직접 실행이 권한 차단될 수 있음 — Codex가 실행/보고.)
- **규칙**: 태스크당 커밋+푸시(확인 없이 — 사용자 지침). Korean UI text는 `.dart`에서 `\u` 이스케이프. Phase 2까지는 **client-side Dart only**(스키마 무수정). 파괴적 관리 동작엔 확인 다이얼로그 + 트리거 에러 한국어 매핑.
- 현재 브랜치: `codex/rebuild-uripan` (main으로 PR 예정).

## 4. 진행 상황
- **Phase 1**: 코어(보드/항목 CRUD/완료·확인/태그/실시간/담당자/멤버목록). 완료.
- **Phase 2 (15태스크)**: 설정·로그아웃 / 보드전환 / 프로필편집 / 보드설정 / 멤버관리 / 담당자버그수정 / 확인자명단 / 검색 / 태그필터 / 친절한날짜 / 네비배지 / 빠른완료·지남표시 / 당겨서새로고침 / 빈·로딩상태 / 접근성. **전부 출시, 테스트 40→73, analyze 무이슈.** 큐는 소진 후 삭제됨.
- **Phase A (로컬 리마인더, 3태스크)**: 패키지/플랫폼 셋업 + ReminderScheduler(Local+Noop) / 순수 buildReminderPlan + ReminderSettings / 코디네이터 wiring + 권한 + 알림 토글(shared_preferences). 정책 D1/D2 반영, 테스트 73→85, analyze 무이슈. 큐 소진 후 삭제. 단말 실제 알림 전달은 미검증(실기기 필요). 다음은 Phase B(FCM/APNs).
- **코멘트/댓글 페이즈 (5태스크)**: 첫 스키마 변경(item_comments 테이블+RLS+realtime publication). BoardComment 모델, repository CRUD(Memory+Supabase), friendlyRelativeTime, CommentThread 위젯, 카드 💬 배지(비실시간 카운트), 상세시트 열림 동안 item별 실시간 구독. UI 라벨은 "댓글". 테스트 85→100. 주의: (a) item_comments 마이그레이션 원격 적용 확인됨(2026-06-03), (b) 댓글 에러 시 board 배너+스레드 인라인 이중 표시 — 폴리시 후보(미해결), (c) 실시간 E2E는 실제 2클라이언트 필요.
- **디자인 오버홀 (2026-06-02, 커밋 18440b4)**: **Warm Stone** 테마 + **Pretendard** 폰트로 전면 리디자인. 토큰은 `lib/theme/app_theme.dart`의 `AppColors`(primary `#3B82C4` 블루, background `#F8F6F3` 스톤). 보드 카드/헤더/a11y 대비 다듬음. (구 `docs/DESIGN.md`는 이 오버홀로 무효화돼 삭제됨.)
- **모바일 QA 블로커 픽스 (2026-06-03, 커밋 dccbb68, Codex)**: AndroidManifest에 **INTERNET 권한** 추가(이게 없어 백엔드 연결 불가였음), 상세시트 수정/삭제 권한 게이트(`canManageItem`), `leaveBoard`를 `leave_board` RPC로 전환(+신규 마이그레이션), 헤더 단순화(초대 버튼 멤버 탭으로), item_comments 실시간 구독 추가. 테스트 100→105.
- **UI/UX 고도화 (2026-06-03, 이번 세션, 커밋 61ce5b2)**: **댓글창 채팅 버블형 재디자인**(사용자가 "댓글창 못생김" 지적 → 본인/상대 정렬, 작성자+시각 헤더, 카운트 배지, 빈상태, 라운드 컴포저). **로그인 화면 고도화**(브랜드 마크 카드, 비번 표시 토글, 에러/성공 배너) + **"로그인 상태 유지" 체크박스**(SessionPreferences, OFF면 콜드 스타트에 signOut). 테스트 105→110, analyze 무이슈. (검증: analyze/test green. 실기기 비주얼은 미확인 — flutter run 필요.)

## 5. 다음 방향 (gstack 패널 결론, 2026-06-02)
판정: **"잘 만든 공유 보드"는 맞지만 아직 "가족 데일리 드라이버"는 아님.** 결정적 공백 순서:
1. ~~**알림/리마인더**~~ (Phase A 완료, Phase B=FCM 남음)
2. ~~**코멘트/가벼운 소통**~~ ← **출시 완료 (2026-06-02)**. 설계: `docs/superpowers/specs/2026-06-02-item-comments-design.md`. 결정: 스레드 실시간 / 코멘트 수 배지 비실시간(C안) / FCM은 Phase B.
3. ~~**UI/UX 폴리시**~~ ← **대부분 완료**: Warm Stone 디자인 오버홀(06-02) + 댓글창/로그인 화면 고도화(06-03). **남은 것: 댓글 에러 이중표시 정리(board 배너 vs 스레드 인라인)**, 실기기 비주얼 확인.
4. **계정 복구(비번 재설정) + 배포(가족 폰 설치)** — 현 상태 A(설치 0대). 실제 배포 마음먹으면 1순위 승격. 합성 이메일 구조라 비번 재설정 선행 필요. (참고: 마이그레이션 2개는 2026-06-03 원격 적용 확인됨.)
5. 반복 일정/할 일
보조: 첨부·사진, 올데이/종료시간, 오프라인 내성.

### 알림 설계 — 선택: **C. 로컬 먼저 → FCM 나중**
- **Phase A (로컬 리마인더, client-side)**: `flutter_local_notifications`+`timezone`+`flutter_timezone`. 구성: ① 패키지/플랫폼 권한 셋업 ② `NotificationService`(플랫폼 래퍼, 얇게) ③ 순수 `buildReminderPlan({items,currentUserId,now,settings})`(테스트 가능, 30일/iOS 64개 상한) ④ 코디네이터(items 변경 시 재계산→sync, 첫 진입 권한요청) ⑤ 설정 토글+리드타임.
  - 주의: Supabase는 OS 푸시를 못 보냄 → 로컬은 *시간기반 리마인더*만. "새 공지 즉시 푸시"는 Phase B.
- **Phase B (FCM/APNs, 나중)**: 토큰 테이블 + Edge Function/트리거로 새 공지·새 배정 즉시 푸시. Firebase/APNs 셋업 필요(코드 밖).

### 확정된 결정 (2026-06-02)
- **D1 ✅** 정책: 일정=전 멤버 알림 / 할 일=담당자(없으면 생성자) 알림.
- **D2 ✅** 리드타임: 일정 "시작 정시 + 1시간 전", **할 일 "마감 10분 전"**.
- **D3 ✅** 설정 토글 저장에 `shared_preferences` 사용 (이미 pubspec 의존성에 존재).
- 추가 필요 패키지: `flutter_local_notifications`, `timezone`, `flutter_timezone`.
→ `docs/codex-tasks/`에 로컬 리마인더 태스크 3개(01 셋업/Scheduler · 02 순수 planner+settings · 03 코디네이터 wiring+토글) 작성됨.

## 6. 참고
- 검증용 RLS 체크: `docs/supabase/rls-checks.sql`
- **디자인 토큰/시스템의 단일 원천 = `lib/theme/app_theme.dart`(`AppColors`/`AppTheme`)**. (구 `docs/DESIGN.md`는 Warm Stone 오버홀과 불일치해 삭제 — 별도 디자인 문서 만들지 말고 코드를 보라.)
- 히스토리성 설계 스펙: `docs/superpowers/specs/`.
- 코드 한글은 `.dart`에서 반드시 `\u` 이스케이프(mojibake 방지). 변환은 PowerShell로 non-ASCII→`\uXXXX` 일괄 처리.
- (이 환경에서 `python`/`supabase` CLI는 미동작. flutter/dart는 `C:\Users\a3030\development\flutter\bin\`의 `.bat`로 호출.)
