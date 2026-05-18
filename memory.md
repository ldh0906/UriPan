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

- 사용자는 Android/빌드 다운로드 용량에 민감하다. 큰 다운로드나 Android 빌드를 시작하기 전에는 용량 영향을 짧게 알리는 편이 좋다.
- 완료된 SDK/Gradle/Flutter 캐시 삭제는 명시 요청이 있을 때만 한다.
- 화면 확인은 Android 빌드보다 Flutter web 실행이 가볍다. 단, 현재 PowerShell PATH에는 Flutter가 없다.
- `memory.md`에는 장기적으로 필요한 상태만 남기고, 종료된 서버 주소/일회성 브라우저 상태/오래된 진행률 수치는 다시 쌓지 않는다.
