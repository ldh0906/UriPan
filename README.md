# UriPan

UriPan은 가족이 오늘의 일정, 할 일, 공지를 함께 보는 모바일 우선 공유 보드입니다.

## 현재 상태

- Flutter 앱
- Supabase Auth, Database, Realtime 기반
- 아이디/비밀번호 로그인
- 가족 보드 생성
- 관리자 초대 코드 생성
- 초대 코드로 보드 참여
- 일정/할 일/공지 생성
- 할 일 완료
- 보드 데이터 Realtime 동기화

## 인증 방식

앱 화면에서는 이메일을 받지 않고 `아이디 + 비밀번호`만 받습니다.

Supabase Auth는 내부적으로 이메일 형식 식별자가 필요하므로, 앱은 사용자 아이디를 다음처럼 변환합니다.

```text
family01 -> family01@auth.uripan.app
```

운영 전제:

- Supabase Email provider를 사용합니다.
- Supabase Auth의 email confirmation은 꺼야 합니다.
- `auth.uripan.app` 주소는 실제 메일 수신용이 아니라 앱 내부 로그인 식별자입니다.
- 다른 도메인을 쓰려면 `AUTH_EMAIL_DOMAIN` dart define으로 바꿀 수 있습니다.

## 로컬 실행

Flutter가 PATH에 있으면:

```powershell
flutter pub get
flutter run
```

Supabase 연결은 dart define으로 주입합니다.

```powershell
flutter run `
  --dart-define=SUPABASE_URL=<PROJECT_URL> `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<PUBLISHABLE_KEY> `
  --dart-define=AUTH_EMAIL_DOMAIN=auth.uripan.app
```

Supabase 설정이 없으면 인메모리 샘플 데이터로 실행됩니다.

## 검증

```powershell
dart format lib test
flutter analyze
flutter test
```

수동 DB 검증은 [RLS checks](docs/supabase/rls-checks.sql)를 사용합니다.
