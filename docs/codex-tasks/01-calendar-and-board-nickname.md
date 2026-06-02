# Codex Task — 달력 고도화 + 보드별 별명

> 작성: Claude (PM/QA), 2026-06-03. 구현: Codex. 완료 후 Claude가 analyze/test 검증 → 커밋/푸시.
> 컨텍스트: `docs/claude_memory.md` 먼저 읽기. Korean UI 문자열은 `.dart`에서 반드시 `\u` 이스케이프(mojibake 방지). 기존 Warm Stone 디자인/`AppColors` 토큰 재사용, 새 색 만들지 말 것.

검증 명령(작업 후 반드시 실행, 셋 다 green이어야 함):
```
C:\Users\a3030\development\flutter\bin\dart.bat format lib test
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
```

---

## Feature A — 달력(일정 탭) 고도화

현재: `lib/screens/today_board_screen.dart`의 `_CalendarWeekStrip`(주간 가로 스트립) + 선택일 일정 리스트. 날짜에 일정 유무 표시 없음. 월간 뷰 없음.

### A1. 멀티데이 일정 (모델/로직, 마이그레이션 불필요)
- `board_items`에 `starts_at`/`due_at` 컬럼이 **이미 둘 다 존재**. 일정의 **종료일로 `dueAt`를 재사용**한다. (할일은 기존대로 `dueAt`=마감, 변경 없음.)
- `lib/models/board_item.dart`의 `isForDate(DateTime date)` 수정:
  - schedule 타입: `startsAt`이 null이면 false. `end = dueAt ?? startsAt`. `start.day <= target.day <= end.day`(일 단위, 로컬, 자정 절삭)이면 true. (즉 멀티데이 범위 포함.)
  - task/notice: **기존 동작 유지**(task=dueAt 그날, notice=항상 true).
  - `end < start`인 비정상 입력은 하루짜리(start만)로 취급.
- 단위 테스트 추가: 단일일/멀티데이/경계(시작일·종료일 당일)/역전 입력.

### A2. 일정 추가·수정 시트: 종료일 필드
`lib/widgets/board_action_sheets.dart`의 `AddItemSheet`:
- 현재 `_DateTimePickerRow` 하나로 schedule→`startsAt`, task→`dueAt` 단일 날짜 입력.
- **schedule 타입일 때만** "종료일(선택)" 행을 추가. 비우면 하루짜리(`dueAt=null`), 채우면 `dueAt`=종료 날짜+시간.
  - 종료일 기본값: 비어있음(off). 켜면 시작일과 동일 날짜로 시작.
  - 검증: 종료가 시작보다 빠르면 저장 막고 인라인 에러(`\u` 이스케이프된 한국어).
  - 라벨 예: 시작="시작", 종료="종료(선택)".
- 수정(initialItem) 진입 시 기존 `startsAt`/`dueAt` 채워 넣기.
- draft 빌드(현재 라인 370 부근): schedule이면 `startsAt`=시작, `dueAt`=(종료 켜짐? 종료 : null). task는 기존 그대로.

### A3. 월간 확장형 달력 위젯 (직접 구현, 의존성 0)
`_CalendarWeekStrip`을 확장하거나 새 `_CalendarPanel`로 대체:
- **기본은 주간 스트립**(현재 모습 유지). **상단 날짜범위 텍스트(`6.1 - 6.7`)를 탭하면 월간 그리드로 펼침**, 다시 탭하거나 날짜 선택하면 그 주로 접힘(캘린더 앱 표준).
- 월간 그리드: 7열 x 5~6행, 일~토 또는 월~일(현재 스트립은 월 시작 — `_weekdayLabels` 월~일 유지). 이전/다음 달 흐린 날짜(머트 텍스트) 표시. 좌우 화살표 = 월 이동.
- **타입별 색 점(dot)**: 각 날짜 칸 하단에 그 날짜에 해당하는 항목 타입별 점.
  - 일정 = `AppColors.primary`(파랑), 할일 = `AppColors.tertiary`(앰버), 공지 = `AppColors.success`(초록).
  - 해당 판정: 일정은 `isForDate`(멀티데이 범위 포함), 할일은 `dueAt` 그날, 공지는 점 표시 안 함(공지는 날짜 개념 약함 — 일정/할일만 점). → **점은 일정🔵·할일🟠 두 종류만.** (공지 초록은 토큰만 예약, 이번엔 미표시.)
  - 하루 **최대 2개 점(일정·할일 각 1)**. 개수 텍스트/"+N" 안 붙임.
- **'오늘로' 점프 버튼**: 헤더에 작은 버튼. 탭하면 선택일=오늘 & 해당 주/월로 이동.
- 멤버 정렬·a11y: 각 날짜 셀은 기존처럼 `Semantics(button, selected, label)`. 점은 `ExcludeSemantics` 안.

### A4. 멀티데이 막대 (월간 뷰에서)
- 월간 그리드에서 여러 날 걸친 **일정**은 가로 막대로 연결 표시(시작~종료). 색 = `AppColors.primary`, soft 배경 `primarySoft`.
- 주간 스트립에선 막대 대신 점 유지(공간 부족). 막대는 월간 펼친 상태 한정.
- 구현이 과하면(주 경계 넘는 막대 분할 등) **1차 범위: 같은 주 안에서만 막대 연결, 주 경계 넘으면 각 날 점**으로 폴백. (완벽한 멀티위크 막대는 후속.)

---

## Feature B — 보드별 별명

목표: 로그인 아이디/전역 `profiles.display_name`은 고정. **보드마다 자기 표시 이름(별명)을 따로** 설정. 효과 범위 = **그 보드 안 모든 곳**(멤버 목록 + 댓글 작성자 + 담당자 + 확인자). 효과적 이름 = `nickname ?? display_name`.

### B1. 마이그레이션 (이미 Claude가 작성함 — 코드만 맞추면 됨)
파일: `supabase/migrations/20260603120000_add_board_member_nickname.sql`
- `board_members.nickname text` (nullable, 1~40자 체크).
- RPC `set_board_nickname(target_board_id uuid, new_nickname text)` SECURITY DEFINER — 호출자 자기 멤버십의 nickname만 업데이트. 빈/공백 → null. (직접 UPDATE 정책 안 줌: 자가 role 승격 구멍 방지.)
- **원격 적용은 Claude가 별도 처리**(현재 환경에서 DDL 푸시 불가). Codex는 **MemoryBoardRepository로 동작/테스트**하면 됨.

### B2. 모델
`lib/models/board_item.dart`:
- `BoardMember`에 `final String? nickname;` 추가(생성자 optional). `String get effectiveName => (nickname != null && nickname!.trim().isNotEmpty) ? nickname! : displayName;`
- (선택) 같은 패턴이 필요하면 헬퍼 추가하되 과설계 금지.

### B3. Repository — 보드별 별명 해석
`lib/services/board_repository.dart`:
- **추상** `BoardRepository`에 `Future<void> setBoardNickname(String boardId, String? nickname)` 추가.
- **MemoryBoardRepository**: 멤버 맵에 nickname 저장. `setBoardNickname` 구현. 멤버 목록/댓글 작성자/담당자/확인자 이름 해석에서 그 보드 nickname을 우선 적용.
- **SupabaseBoardRepository**:
  - 멤버 조회 쿼리에 `nickname` 컬럼 select 추가 → `BoardMember.nickname` 채움.
  - 이름 해석 헬퍼(`_displayNames`, `_profiles`)는 현재 **boardId 무관**(profiles만). 이름이 쓰이는 보드-스코프 경로(댓글 작성자, 담당자, 확인자 명단)에서 **그 boardId의 nickname 맵을 오버레이**: `effective = boardNickname[userId] ?? profileDisplayName`.
    - 새 헬퍼 `Future<Map<String,String>> _boardNicknames(String boardId)` (board_members에서 user_id→nickname, null 제외).
  - `setBoardNickname` → `rpc('set_board_nickname', {target_board_id, new_nickname})`. 에러는 기존 `_friendlyDatabaseError` 매핑 흐름 타도록 코드(`membership_required`=42501, `authentication_required`=28000, `nickname_too_long`=23514) 한국어 매핑 추가.
- 모든 이름 노출 지점이 보드 별명을 반영하는지 확인(멤버 패널, 댓글, 담당자 칩, 확인자 목록).

### B4. Controller
`lib/services/board_session_controller.dart`:
- `setBoardNickname(String? nickname)` 액션 추가(`_runAction` 래핑, 현재 보드 id 사용, 성공 시 멤버/항목 새로고침해서 바뀐 이름 반영).

### B5. UI — 설정창
`lib/widgets/board_settings_sheet.dart`:
- "내 정보"(전역 프로필) 항목 **아래**에 "**이 보드에서 내 별명**" 항목 추가. subtitle = 현재 내 effectiveName(별명 없으면 "별명 없음" 등 안내). 탭하면 별명 편집 시트.
- 편집 시트: TextField(최대 40자, 비우면 별명 해제=전역 이름 사용). 저장 시 `onSetBoardNickname(nickname)` 콜백. 라벨 한국어 `\u` 이스케이프.
- `board_home_screen.dart`에서 콜백을 컨트롤러 `setBoardNickname`에 연결.
- 라벨 제안: 제목 "이 보드에서 내 별명", 입력 힌트 "비우면 기본 이름을 써요".

### B6. 테스트
- `setBoardNickname` 후 그 보드 멤버 effectiveName 변경, 댓글 작성자/담당자 표시도 변경(Memory repo 기준).
- 다른 보드에선 전역 이름 그대로(별명은 보드 스코프).
- 빈 문자열/공백 → 별명 해제.

---

## 마무리
- `dart format`/`analyze`/`test` 셋 다 green 확인 후 변경 요약 보고.
- 테스트 수 보고(현재 110 → 증가 기대). analyze 무이슈 유지.
- 커밋/푸시는 Claude가 검증 후 진행.
