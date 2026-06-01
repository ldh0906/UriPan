# UriPan

**UriPan**은 가까운 사람들과 일정, 할 일, 공지를 함께 정리하는 공유 보드입니다.

가족, 친구, 룸메이트, 스터디, 팀플처럼  
매일 크고 작은 약속을 나누는 사람들을 위한 작은 상황판을 목표로 합니다.

> 흘러가는 채팅방 대신, 우리끼리 확인할 수 있는 한 장의 보드.

## 왜 만들었나요?

우리는 대부분의 약속과 할 일을 채팅방에서 정합니다.

하지만 채팅방은 빠르게 흘러갑니다.  
중요한 일정은 대화 사이에 묻히고, 누가 확인했는지 알기 어렵고,  
누가 무엇을 해야 하는지도 시간이 지나면 흐릿해집니다.

UriPan은 그런 순간을 줄이고 싶어서 시작한 프로젝트입니다.

“말했잖아.”  
“언제?”  
“못 봤는데?”

이런 대화가 조금 줄어들도록,  
우리끼리 공유해야 할 내용을 한곳에 모아두는 것이 UriPan의 목적입니다.

## UriPan은 어떤 앱인가요?

UriPan은 단순한 캘린더 앱이 아닙니다.

일정만 적어두는 곳이 아니라,  
**오늘 우리에게 무슨 일이 있는지**,  
**누가 무엇을 맡았는지**,  
**어떤 공지를 확인해야 하는지**를 함께 볼 수 있는 공유 공간입니다.

작은 그룹이 서로의 흐름을 놓치지 않도록 돕는  
가볍고 따뜻한 생활형 보드를 지향합니다.

## 이런 상황에 사용할 수 있어요

- 가족끼리 병원, 외식, 집안일 일정을 공유할 때
- 친구들과 여행 일정과 준비물을 정리할 때
- 룸메이트끼리 청소, 분리수거, 공과금을 관리할 때
- 스터디 그룹에서 모임 시간과 과제를 확인할 때
- 팀플에서 발표 일정과 담당 업무를 나눌 때
- 동아리나 작은 모임에서 공지를 전달할 때

## UriPan이 보여주고 싶은 것

UriPan의 중심은 거창한 기능이 아니라  
**우리끼리의 약속을 놓치지 않는 것**입니다.

오늘의 일정, 해야 할 일, 중요한 공지가  
각자 흩어져 있지 않고 한 화면에 모여 있다면  
작은 그룹은 조금 더 편하게 움직일 수 있습니다.

UriPan은 그런 작은 편리함을 만드는 앱입니다.

## 이름의 의미

**UriPan**은 “우리판”을 로마자로 적은 이름입니다.

여기서 “판”은 일정판, 할 일판, 공지판, 상황판의 의미를 담고 있습니다.

즉, UriPan은  
**우리끼리 함께 보는 판**입니다.

## 한 줄 소개

> UriPan is a simple shared board for schedules, tasks, and notices.

---

## 현재 상태

- Flutter 앱
- Supabase Auth, Database, Realtime 기반 (Supabase 미설정 시 인메모리 샘플로 실행)
- 아이디/비밀번호 로그인
- 가족 보드 생성 / 관리자 초대 코드 생성 / 초대 코드로 참여
- 일정·할 일·공지 생성, 수정, 삭제
- 할 일 완료, 공지 확인(확인 필요 공지)
- 항목 작성자·담당자 표시, 할 일 담당자 지정
- 멤버 목록(역할·정원) 보기
- 사용자 태그
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
