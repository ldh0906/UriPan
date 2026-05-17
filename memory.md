# UriPan 작업 메모리

이 파일은 다음 세션에서 바로 이어서 작업할 수 있도록 현재 상태를 기록한 것이다.

## 환경

- 프로젝트 경로: `/mnt/c/UriPan`
- 현재 작업은 WSL/Linux 환경에서 진행 중이다.
- Flutter SDK 경로: `/home/a/development/flutter`
- WSL Android SDK 경로: `/home/a/Android/Sdk`
- Windows PowerShell에서는 `flutter`가 PATH에 없으므로 WSL의 절대 경로 Flutter를 사용한다:
  - `/home/a/development/flutter/bin/flutter`
  - `/home/a/development/flutter/bin/dart`
- `android/local.properties`는 다음 경로를 사용하도록 수정됨:
  - `flutter.sdk=/home/a/development/flutter`
  - `sdk.dir=/home/a/Android/Sdk`

## 현재 실행 상태

- Flutter web-server를 실행해서 앱 확인을 마쳤고, 이후 사용자가 서버 종료를 요청해서 종료 완료했다.
- 마지막 실행 명령:
  - `cd /mnt/c/UriPan && /home/a/development/flutter/bin/flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`
- 마지막 브라우저 주소:
  - `http://127.0.0.1:8080`
  - in-app browser는 `http://127.0.0.1:8080/#/today`까지 열어 확인했다.
- 현재 WSL의 Flutter/Dart web-server 프로세스는 종료됐다.
- 종료 직후 Windows TCP 상태에 `FinWait2`/`TimeWait` 잔여 연결이 잠시 남을 수 있으나, `Listen` 상태는 사라졌다.
- 웹 실행은 Android 빌드/에뮬레이터를 사용하지 않았으므로 Android 추가 용량 증가 없이 확인한 경로다.
- 웹 실행 확인 결과:
  - HTTP 200 응답 확인
  - Login 화면 표시 확인
  - Today 화면까지 브라우저 이동 확인
  - 확인 당시 브라우저 콘솔 error/warning 없음

다시 실행하려면 위 실행 명령을 사용하면 된다.

## Android 설치 진행 상태

사용자가 "안드로이드 필요한 거 다 다운"을 요청해서 WSL용 Android SDK를 설치했다.

완료된 것:

- Flutter pub dependencies 설치 완료: `flutter pub get`
- Flutter Android 아티팩트 precache 완료: `flutter precache --android`
- WSL용 Android command-line tools 설치 완료:
  - `/home/a/Android/Sdk/cmdline-tools/latest`
- Android SDK 패키지 설치 완료:
  - `platform-tools`
  - `platforms;android-36`
  - `build-tools;36.0.0`
- `flutter doctor --android-licenses`로 SDK 라이선스 accepted 처리 완료
- `flutter doctor -v`에서 Android SDK를 `/home/a/Android/Sdk`로 인식함

추가로 `flutter build apk --debug`를 실행했을 때 Flutter/Gradle이 자동으로 설치한 것:

- NDK side-by-side `28.2.13676358`
- `build-tools;35.0.0`
- CMake `3.22.1`

이후 사용자가 "백그라운드로 하나해서 다운 못받은것들 다운받자"라고 요청해서 `flutter build apk --debug`를 다시 실행했고, 약 439초 후 디버그 APK 빌드가 완료됨:

- 생성물: `/mnt/c/UriPan/build/app/outputs/flutter-apk/app-debug.apk`

## 중단 및 정리 상태

사용자가 용량 때문에 설치/빌드를 취소 요청했다.

중단한 것:

- `flutter build apk --debug`
- Gradle daemon
- Kotlin compile daemon

정리한 것:

- `/home/a/.gradle/.tmp`
- `/home/a/Android/Sdk/.temp/*`
- `/mnt/c/UriPan/build/app/tmp`
- `/mnt/c/UriPan/build/app/intermediates`

완료된 설치물은 삭제하지 않았다.

마지막 확인 기준 대략 용량:

- Android SDK: 약 `2.8G`
- Flutter cache: 약 `1.5G`
- Gradle cache: 약 `1.7G`
- 프로젝트 `build`: 약 `46M`

과거 Android 설치/정리 직후 프로세스 확인 기준:

- `flutter`, `gradle`, `sdkmanager`, `kotlin`, `flutter_tester` 관련 실행 프로세스 없음

현재는 위 정리 상태 이후 사용자가 앱 실행을 요청하여 Flutter web-server 프로세스가 실행 중이다.

## 구현된 화면

`lib/main.dart`의 라우트 기준 구현된 화면:

1. Welcome 화면: `/`
2. Login 화면: `/login`
3. Your Boards / 그룹 선택 화면: `/boards`
4. Today 보드 화면: `/today`
5. Calendar 화면: `/calendar`
6. Tasks 화면: `/tasks`
7. Notices 화면: `/notices`
8. Members / 초대 화면: `/members`
9. Add New Item 선택 화면: `/add`
10. Item Detail/Edit 화면: `/item-edit`

하단 탭에 직접 연결된 화면:

- Today
- Calendar
- Tasks
- Notices
- Members

## 총 개발 진행상태

현재 프로젝트는 Flutter 기반 모바일 앱 UI 프로토타입 단계다. 주요 화면과 목업 데이터 기반 화면 흐름은 구현되어 있지만, 실제 백엔드/인증/저장소/네트워크 연동은 아직 없다.

완료된 것:

- Flutter 프로젝트 구조 생성 완료
- Android/iOS 기본 플랫폼 폴더 존재
- 앱 소개 README 작성됨
- `lib/main.dart`에서 로컬 보드 상태 관리 추가:
  - `boards` / `activeBoard` 유지
  - 보드 생성, 초대코드 참가, 보드 선택
  - 멤버 역할 변경, 멤버 삭제, active board 나가기
  - 일정/할 일/공지 삭제
  - 항목 변경 시 보드 요약 문구 자동 동기화
- Material 기반 앱 테마 구현:
  - `lib/theme/app_theme.dart`
  - 색상 팔레트, 텍스트 테마, 버튼/입력/카드 계열 스타일 포함
- 공통 UI 컴포넌트 구현:
  - `ScreenShell`
  - `PagePadding`
  - `SoftCard`
  - `AppLogoMark`
  - `PrimaryButton`
  - `AppTextField`
  - `MemberAvatar`
  - `SectionHeader`
  - `AppBottomNav`
  - `ScheduleCard`
  - `TaskCard`
  - `NoticeCard`
  - `FeatureCard`
  - `AddItemFab`
- 모델 정의 완료:
  - `FamilyMember`
  - `BoardData`
  - `ScheduleItemData`
  - `TaskItemData`
  - `NoticeItemData`
- 목업 데이터 정의 완료:
  - 구성원
  - 보드 목록
  - 일정
  - 할 일
  - 공지
  - 캘린더 하이라이트
- 화면 라우팅과 로컬 흐름 재연결 완료:
  - `GroupSelectionScreen`이 보드 목록과 create/join/select 콜백을 받음
  - `Today` / `Calendar` / `Tasks` / `Notices` / `Members` 화면이 active board 이름을 표시함
  - `ItemDetailEditScreen`이 `BoardItemType` 인자와 `onSave`를 받아 일정/할 일/공지 생성으로 연결됨
- 라우팅 연결 완료:
  - `MaterialApp.routes`에서 10개 화면 연결
- 하단 네비게이션 구현 완료:
  - Today / Calendar / Tasks / Notices / Members
  - 화면 간 기본 이동 구현:
  - Welcome -> Login
  - Login -> Boards
  - Boards -> Today
  - 하단 탭 간 이동
  - Add FAB -> Add Item
  - Add Item -> Item Edit
  - Today 섹션 헤더 -> Calendar/Tasks/Notices
  - Today members 아이콘 -> Members
- 일부 로컬 상태 동작 구현:
  - 할 일 체크 상태 토글
  - 공지 확인 상태/확인 수 토글
  - Add Item -> Item Edit -> Save 흐름에서 로컬 일정/할 일/공지 생성
  - Tasks 화면에서 할 일 스와이프 삭제
  - Notices 화면에서 공지 스와이프 삭제
  - Calendar 화면에서 일정 스와이프 삭제
  - Login의 keep me logged in 체크박스
  - Tasks segmented filter: All / Open / Completed
  - Tasks 검색 토글 및 제목/담당자/메모 검색
  - Notices segmented filter: All Notices / Unread / Pinned
  - Notices 검색 토글 및 제목/본문 검색
  - Item Edit의 타입 선택, 스위치, 체크박스, 멤버 칩 선택
  - Tasks/Notices 빈 상태 UI
  - Members 화면 초대 코드 복사
  - Members 화면 역할 요약 다이얼로그, 멤버 액션 시트, 보드 나가기 확인 다이얼로그
  - Members 화면에서 멤버 역할 변경(Admin/Member/Viewer) 로컬 반영
  - Members 화면에서 멤버 삭제 로컬 반영 및 active board 멤버 수 요약 갱신
  - Members 화면에서 Leave Board 시 active board를 로컬 목록에서 제거하고 Boards 화면으로 이동
  - Members 화면 FAB를 Add Item 대신 초대 코드 복사 동작으로 변경
  - Login 화면 비밀번호 찾기/회원가입 다이얼로그
  - Boards 화면 계정 설정 바텀시트
  - Calendar/Tasks/Notices FAB가 각각 Schedule/Task/Notice 작성 화면으로 직접 이동
  - Today 화면 날짜를 현재 날짜 기준으로 표시
  - Item Edit의 날짜/시간 입력을 자유 텍스트에서 date/time picker 기반 입력으로 변경
  - Calendar 화면 초기 월/선택 날짜를 현재 날짜 기준으로 변경
  - Calendar/Tasks/Notices 화면의 보드명 표시를 active board 기준으로 동기화
  - 보드 생성/참가/선택 후 화면 전체가 해당 보드 문맥을 따라가도록 연결
  - 항목 생성/삭제 후 보드 요약이 즉시 갱신되도록 연결

부분 구현/목업 상태:

- 로그인 화면은 UI만 있음. 실제 인증 없음.
- 회원가입, 비밀번호 찾기 버튼은 로컬 다이얼로그만 표시하며 실제 인증 기능은 없음.
- 보드 생성/참여는 로컬 앱 상태에만 반영되고 서버에는 저장되지 않음.
- 보드 선택과 active board 전환도 로컬 앱 상태에만 반영되고 서버에는 저장되지 않음.
- 설정은 UI만 있고 동작 없음.
- 멤버 더보기, 초대 코드 복사, 역할 변경, 멤버 삭제는 로컬 상태에만 반영되고 서버에는 저장되지 않음.
- 보드 나가기는 로컬 상태에서 active board를 제거하지만 서버 상태와는 연결되어 있지 않음.
- Add Item 화면은 항목 종류 선택 후 Item Edit 화면으로 이동하고 타입을 전달함.
- Item Edit 저장은 실제 로컬 리스트에 새 항목을 추가한다.
- 일정/할 일/공지 삭제는 로컬 리스트에서만 반영된다.
- 캘린더는 실제 월 그리드/월 이동/날짜 선택/날짜별 일정 필터링이 구현됐고, 새 일정 날짜는 date picker로 입력함.
- Today 화면 날짜는 현재 날짜를 표시하고, 보드명은 선택한 active board를 표시함.
- 데이터는 `MockData`와 앱 State 내부 리스트에만 존재하며 앱 재시작 시 유지되지 않음.

아직 미구현:

- Supabase/Firebase/REST API 등 백엔드 연동
- 실제 로그인/회원가입/세션 관리
- 사용자/그룹/보드 수정/삭제
- 일정 수정
- 공지 수정
- 할 일 수정
- 실제 초대 코드 생성/검증/서버 참여
- 서버 기반 권한/역할 관리
- 알림/푸시
- 로컬 저장소 또는 서버 동기화
- 에러/로딩/빈 상태 처리

검증 상태:

- `flutter pub get` 완료
- Android SDK는 WSL용으로 설치되어 Flutter가 인식함
- `flutter doctor -v`에서 Android toolchain은 SDK를 인식했으나, Android 외 Chrome/Linux desktop toolchain 이슈는 남아 있었음
- `flutter build apk --debug` 완료
  - `/mnt/c/UriPan/build/app/outputs/flutter-apk/app-debug.apk`
  - 최근 로컬 기능 추가 후 다시 빌드 완료: 약 65초
- `flutter analyze` 통과
- `dart analyze lib test` 통과
- `flutter test test/widget_test.dart` 통과
  - Welcome 화면 렌더 테스트
  - Add Item에서 Task 생성 후 Tasks 화면에 표시되는 흐름 테스트
  - 보드 생성 로컬 반영 테스트
  - 멤버 역할 변경 로컬 반영 테스트
  - active board 나가기 로컬 반영 테스트
- `test/screen_capture_test.dart`에 구현된 10개 화면 캡처 스크립트 추가 및 golden 업데이트 방식으로 정리
  - 기본 `flutter test`에서는 캡처 테스트가 skip 처리됨
  - 캡처가 필요할 때만 `--dart-define=URIPAN_CAPTURE_SCREENS=true --update-goldens`로 실행
- `flutter test` 전체 통과
  - 캡처 테스트 10개는 기본 테스트에서는 skip 처리됨
- Flutter web-server 실행 확인
  - `http://127.0.0.1:8080`
  - in-app browser에서 `/today` 화면까지 표시 확인
  - 확인 당시 브라우저 콘솔 error/warning 없음

최근 추가 구현:

- Boards 화면:
  - 루트 앱 상태에서 `boards` 리스트 관리
  - 선택한 보드를 `activeBoard`로 저장하고 Today 화면 제목에 반영
  - 일정/할 일/공지 추가, 삭제, 확인 상태 변경 시 active board 요약 문구 갱신
  - Create 버튼으로 보드 생성 다이얼로그 표시 및 로컬 보드 추가
  - Join 버튼으로 초대 코드 입력 다이얼로그 표시 및 로컬 보드 추가
  - 보드가 비었을 때 빈 상태 UI 표시
  - 보드 생성/참여 다이얼로그의 controller dispose 타이밍 문제 수정
- Members 화면:
  - 멤버별 액션 시트에서 역할 변경을 실제 로컬 상태에 반영
  - 멤버 삭제 확인 후 로컬 리스트에서 제거
  - Leave Board 확인 후 active board를 로컬 목록에서 제거하고 Boards 화면으로 이동
  - 멤버 수 변경 시 board summary 갱신
- Calendar 화면:
  - `StatefulWidget`으로 변경
  - 실제 월 시작 요일/일수 기반 6주 그리드 렌더링
  - 초기 포커스 월/선택 날짜를 현재 날짜로 설정
  - 이전/다음 월 이동 버튼
  - 날짜 선택 상태 및 선택 날짜 라벨 표시
  - `ScheduleItemData.date` 추가
  - 선택한 날짜와 같은 일정만 목록에 표시
  - 일정 카드에 날짜 표시 추가
  - 일정이 있는 날짜는 캘린더 마커로 표시
- Item Edit 화면:
  - Date/Due Date 필드를 `showDatePicker` 기반 read-only 입력으로 변경
  - Start/End Time 필드를 `showTimePicker` 기반 read-only 입력으로 변경
  - 새 항목 기본 날짜를 현재 날짜로 설정
- 화면 캡처:
  - 기존 `RenderRepaintBoundary.toImage()` 직접 호출 방식은 테스트 환경에서 멈춰 폐기
  - `matchesGoldenFile` + `--update-goldens` 방식으로 10개 화면 PNG 생성 완료
  - Login 화면 하단의 "Don't have an account? / Sign Up" 가로 overflow를 발견해 `Wrap`으로 수정 완료

대략적인 진행률 감각:

- UI/프로토타입: 약 70%
- 화면 라우팅/탭 흐름: 약 75%
- 실제 앱 기능/데이터 영속성: 약 20%
- 백엔드/인증/동기화: 0%
- Android 빌드 환경: 디버그 APK 빌드 완료
- 로컬 웹 실행 확인: 완료

## 화면 캡처 시도 상태

사용자가 "구현된 화면 보여줘"라고 요청해서 Flutter 위젯 테스트 기반 PNG 캡처를 구현했고, 이후 안정적인 golden 업데이트 방식으로 정리했다.

캡처 테스트 파일:

- `/mnt/c/UriPan/test/screen_capture_test.dart`

현재 방식:

- 화면별 개별 `testWidgets`로 분리되어 있다.
- 기본 `flutter test`에서는 `URIPAN_CAPTURE_SCREENS` 값이 없으므로 skip된다.
- 캡처가 필요할 때만 golden 파일을 갱신한다.
- 기존 `RenderRepaintBoundary.toImage()` 직접 호출 방식은 WSL 테스트 환경에서 멈출 수 있어 사용하지 않는다.

다음에 화면을 보여줘야 하면 권장 접근:

1. `test/screen_capture_test.dart`는 이제 golden 업데이트 방식으로 정리됨.
2. 기본 `flutter test`에서는 캡처 테스트가 skip 처리되며, 필요할 때만 다음 명령으로 PNG를 갱신한다:
   - `/home/a/development/flutter/bin/flutter test --update-goldens --dart-define=URIPAN_CAPTURE_SCREENS=true test/screen_capture_test.dart`
3. 생성된 화면 PNG:
   - `/mnt/c/UriPan/test/screen_captures/01_welcome.png`
   - `/mnt/c/UriPan/test/screen_captures/02_login.png`
   - `/mnt/c/UriPan/test/screen_captures/03_boards.png`
   - `/mnt/c/UriPan/test/screen_captures/04_today.png`
   - `/mnt/c/UriPan/test/screen_captures/05_calendar.png`
   - `/mnt/c/UriPan/test/screen_captures/06_tasks.png`
   - `/mnt/c/UriPan/test/screen_captures/07_notices.png`
   - `/mnt/c/UriPan/test/screen_captures/08_members.png`
   - `/mnt/c/UriPan/test/screen_captures/09_add_item.png`
   - `/mnt/c/UriPan/test/screen_captures/10_item_edit.png`
   - 보기용 콜라주: `/mnt/c/UriPan/test/screen_captures/contact_sheet.png`
4. 캡처 중 Login 화면 하단의 "Don't have an account? / Sign Up" Row overflow가 발견되어 `Wrap`으로 수정 완료.
5. 최근 검증:
   - `dart analyze lib test` 통과
   - `flutter test` 전체 통과
   - 캡처 생성 명령 통과
6. Android 빌드를 다시 진행하려면 추가 다운로드/빌드 용량이 더 들 수 있으므로 사용자에게 먼저 확인한다.

## 현재 실행/브라우저 관련 주의할 점

- Flutter web-server는 마지막 요청으로 종료했다.
- 마지막 서버 주소는 `http://127.0.0.1:8080`.
- 마지막으로 사용자가 본 in-app browser URL은 `http://127.0.0.1:8080/#/today`.
- 포트 확인:
  - PowerShell: `Get-NetTCPConnection -LocalPort 8080`
  - WSL: `ps -ef | grep -E 'flutter|dart' | grep -v grep`
- 서버 종료 직후에는 브라우저 잔여 연결 때문에 `FinWait2`/`TimeWait`가 잠시 보일 수 있다. `Listen`이 없으면 서버는 내려간 상태다.
- 다시 실행 요청을 받으면 Flutter web-server로 우선 띄우는 것이 가볍다.
- 웹 실행은 Android 빌드보다 가볍고, 현재 앱 UI 확인용으로 우선 사용하기 좋다.

## 주의할 점

- 사용자는 Android 설치 용량에 민감하다. 추가 다운로드나 빌드를 시작하기 전에 용량 영향을 짧게 설명하는 것이 좋다.
- WSL에서 작업 중이므로 Windows Android SDK(`/mnt/c/Users/.../Android/Sdk`)를 Flutter Linux 빌드에 연결하지 말 것.
- 완료된 SDK/Gradle 캐시는 남겨두라는 요청이 있었다. 삭제 요청이 명확하지 않으면 `/home/a/Android/Sdk`, `/home/a/.gradle`, Flutter cache는 지우지 말 것.
- `test/screen_capture_test.dart`는 현재 화면 캡처용으로 정리된 보조 테스트다. 기본 테스트에는 영향을 주지 않도록 skip된다.
