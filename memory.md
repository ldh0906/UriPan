# UriPan 작업 메모리

다음 세션에서 바로 이어서 작업하기 위한 현재 상태 요약이다. 오래된 실행 로그나 일회성 서버 상태는 일부러 남기지 않는다.

## 프로젝트 개요

- 경로: `C:\UriPan`
- Flutter 기반 공유 보드 앱 프로토타입
- 목적: 가까운 사람들과 일정, 할 일, 공지를 한 보드에서 함께 확인하는 모바일 우선 앱
- 패키지명: `uripan`
- 주요 의존성:
  - `flutter`
  - `shared_preferences`
  - `flutter_lints`

## 현재 코드 상태

- 앱 진입점: `lib/main.dart`
- 테마: `lib/theme/app_theme.dart`
- 공통 위젯: `lib/widgets/common_widgets.dart`
- 모델: `lib/models/mock_models.dart`
- 목업 초기 데이터: `lib/data/mock_data.dart`
- 저장소/설정:
  - `lib/services/app_repository.dart`
  - `lib/services/app_config.dart`

구현된 화면 라우트:

- `/`: Welcome
- `/login`: Login
- `/boards`: 보드 선택
- `/today`: Today 보드
- `/calendar`: Calendar
- `/tasks`: Tasks
- `/notices`: Notices
- `/members`: Members/Invite
- `/add`: Add Item
- `/item-edit`: Item Detail/Edit

## 구현된 기능

- 로그인/회원가입 UI와 로컬 인증 상태 반영
- 보드 생성, 초대 코드 참가, 보드 선택
- 보드별 멤버/일정/할 일/공지 상태 분리
- active board 기준으로 Today/Calendar/Tasks/Notices/Members 화면 동기화
- 일정/할 일/공지 생성, 수정, 삭제
- 기존 카드 탭으로 편집 화면 진입
- 할 일 완료 토글
- 공지 확인 토글 및 확인 인원/이니셜 갱신
- 멤버 역할 변경, 멤버 삭제, 보드 나가기
- 보드 설정:
  - 알림 토글 UI
  - 완료한 할 일 자동 보관
  - 공지 확인 요청 기본값
- 계정 설정 바텀시트:
  - 사용자 프로필 수정
  - 로컬 데모 데이터 초기화
  - 로그아웃
- Calendar:
  - 실제 월 그리드
  - 이전/다음 월 이동
  - 날짜 선택
  - 선택 날짜 일정 필터링
  - 일정 마커 표시
- Tasks:
  - All/Open/Completed 필터
  - 검색
  - 빈 상태
- Notices:
  - All/Unread/Pinned 필터
  - 검색
  - 빈 상태
- Item Edit:
  - date picker/time picker 사용
  - 새 항목 생성과 기존 항목 수정 모두 지원
  - 수정 모드에서는 타입 변경 비활성화

## 저장/동기화 상태

- `LocalAppRepository`가 `shared_preferences`에 `AppSnapshot` JSON을 저장한다.
- 저장 키: `uripan.app.snapshot.v2`
- 앱 시작 시 저장된 snapshot을 불러오고, 없거나 깨져 있으면 `MockData.initialSnapshot`을 사용한다.
- 테스트용 `MemoryAppRepository`가 있다.
- `RemoteUriPanApi`와 `AppConfig.fromEnvironment()`가 준비되어 있지만 실제 원격 API는 아직 연결되지 않았다.
- `.env.example`에는 다음 환경값 예시가 있다:
  - `URIPAN_API_BASE_URL`
  - `URIPAN_API_KEY`
  - `URIPAN_ENABLE_REMOTE_SYNC`

## 다음 작업 요청

사용자가 다음 UI/기능 개선을 요청했다. 다음 세션에서 우선순위 높게 이어서 구현한다.

1. Today 화면 보드 변경 버튼 개선
   - Today 화면 오른쪽 위에 있던 보드 변경 버튼의 모양을 바꾼다.
   - 현재 버튼이 어떤 위젯/아이콘으로 구현되어 있는지 먼저 확인하고, 화면 맥락상 더 자연스러운 형태로 조정한다.
   - 목적은 "보드 변경" 동작이 더 명확하고 보기 좋게 보이도록 하는 것이다.

2. Tasks/Notices 화면에서 Today로 돌아가는 진입점 추가
   - Calendar와 Members 화면에는 오른쪽 화살표 기반 이동 UI가 있다.
   - 같은 패턴의 오른쪽 화살표를 Tasks와 Notices 화면에도 추가한다.
   - Tasks/Notices에서도 해당 화살표로 Today 화면(`/today`)에 돌아올 수 있어야 한다.
   - 기존 하단 탭 이동과 충돌하지 않게, 현재 화면의 헤더/상단 액션 패턴을 먼저 확인한 뒤 맞춰 구현한다.

3. 여러 날 이어지는 일정 생성 지원
   - 현재 Calendar/Item Edit 흐름은 하루짜리 일정만 만들 수 있는 구조다.
   - 2일 이상 이어지는 일정을 만들 수 있도록 일정 모델과 편집 UI를 확장한다.
   - 시작 날짜와 종료 날짜를 입력/선택할 수 있어야 한다.
   - 종료 날짜가 시작 날짜보다 앞서지 않도록 검증한다.
   - 기존 단일 날짜 일정은 계속 정상 동작해야 한다.

4. Calendar에서 여러 날 일정 시각화
   - 2일 이상 이어지는 일정은 Calendar 월 그리드에서 이어지는 직선/막대 형태로 보이게 한다.
   - 하루짜리 일정 마커와 구분되되, 기존 디자인 톤을 해치지 않게 구현한다.
   - 한 주를 넘어가는 일정은 주 단위로 자연스럽게 끊겨 보이거나 이어져 보이도록 처리한다.
   - 선택한 날짜의 일정 목록에는 해당 날짜가 일정 기간 안에 포함되면 표시되도록 한다.

관련해서 손댈 가능성이 큰 파일:

- `lib/models/mock_models.dart`
- `lib/data/mock_data.dart`
- `lib/main.dart`
- `lib/screens/item_detail_edit_screen.dart`
- `lib/screens/calendar_view_screen.dart`
- `lib/screens/tasks_list_screen.dart`
- `lib/screens/notices_board_screen.dart`
- 필요 시 `lib/widgets/common_widgets.dart`

## 아직 미구현

- 실제 백엔드 API 연동
- 실제 로그인/회원가입/세션 검증
- 서버 기반 초대 코드 생성/검증
- 서버 기반 권한/역할 관리
- 사용자/보드의 완전한 수정/삭제 UX
- 푸시 알림
- 충돌 처리, 로딩/에러 상태, 네트워크 실패 처리
- 원격 동기화 어댑터 구현

## 테스트/검증 상태

- 테스트 파일:
  - `test/widget_test.dart`
  - `test/screen_capture_test.dart`
- `widget_test.dart`는 `MemoryAppRepository`로 로컬 저장소 영향을 피한다.
- 현재 포함된 주요 위젯 테스트:
  - Welcome 화면 렌더
  - Add flow로 새 Task 생성
  - 보드 생성
  - 멤버 역할 변경
  - 기존 Task 수정
  - active board 나가기
- 화면 캡처 테스트는 기본 실행에서 skip된다.
- 캡처가 필요할 때:
  - `flutter test --update-goldens --dart-define=URIPAN_CAPTURE_SCREENS=true test/screen_capture_test.dart`
- 생성된 캡처:
  - `test/screen_captures/01_welcome.png` ~ `10_item_edit.png`
  - `test/screen_captures/contact_sheet.png`

## 현재 환경 메모

- 현재 Codex 세션은 Windows PowerShell에서 `C:\UriPan`을 작업 중이다.
- 이 환경에서는 `flutter`와 `dart`가 PATH에 잡혀 있지 않다.
- 따라서 이번 memory 정리 시점에는 `flutter test`, `dart analyze`를 실행하지 못했다.
- memory 갱신 전 `git status --short` 기준 작업트리는 깨끗했다.
- 최근 git log 상단:
  - `479f6c2 Localize app UI to Korean`
  - `a785331 Refresh Flutter metadata for web`
  - `ca9890e Fix app home routing and update tests`
  - `65c9ee4 Remove local config section from README`
  - `3e5f537 Merge pull request #2 from ldh0906/codex/local-app-completion`

## 작업 시 주의

- 다른 컴퓨터에서도 이 저장소 작업이 진행 중일 수 있다. 작업 전 `git status`, 필요하면 `git log`/`git pull` 상태를 확인하고, 내가 만들지 않은 변경은 되돌리지 않는다.
- 사용자는 Android/빌드 다운로드 용량에 민감하다. 큰 다운로드나 Android 빌드를 시작하기 전에는 용량 영향을 짧게 알리는 편이 좋다.
- 완료된 SDK/Gradle/Flutter 캐시 삭제는 명시 요청이 있을 때만 한다.
- 화면 확인은 Android 빌드보다 Flutter web 실행이 가볍다. 단, 현재 PowerShell PATH에는 Flutter가 없다.
- `memory.md`에는 장기적으로 필요한 상태만 남기고, 종료된 서버 주소/일회성 브라우저 상태/오래된 진행률 수치는 다시 쌓지 않는다.
