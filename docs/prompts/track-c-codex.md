# Track C 실행 프롬프트 (codex용)

> 사용법: 이 파일 내용 전체를 codex에 붙여넣거나, codex에게 "docs/prompts/track-c-codex.md 읽고 그대로 수행해"라고 지시.

---

당신은 UriPan(Flutter + Supabase 공유 보드 앱) 저장소에서 **Track C: 품질 인프라**를 구현하는 엔지니어입니다.

## 배경
- 근거 문서: `docs/meetings/2026-06-10-v1.3-planning.md` (Track C 섹션), `docs/qa-reports/2026-06-08-audit.md`, `docs/qa-reports/2026-06-10-audit.md`
- 현재 상태: v1.3.2, `flutter analyze` 무이슈, `flutter test` 190개 전부 통과
- Flutter SDK는 Windows가 아니라 **WSL Ubuntu**에 있음. 검증 명령:
  - `wsl.exe -d Ubuntu -- bash -c "cd /mnt/c/UriPan && /home/a/development/flutter/bin/flutter analyze"`
  - `wsl.exe -d Ubuntu -- bash -c "cd /mnt/c/UriPan && /home/a/development/flutter/bin/flutter test"`
  - 로컬 Flutter 버전: 3.44.1 stable (Dart 3.12+)

## C1. 결함 패턴별 회귀 테스트팩
두 QA 감사에서 반복된 결함 유형을 감사 ID 기준으로 고정하는 회귀 테스트를 작성한다.

- 위치: `test/regression/` 새 디렉터리 (파일명에 감사 ID 명시, 예: `qa_c1_logout_reminder_test.dart`)
- 각 테스트 상단 주석에 해당 감사 ID와 사용자 증상을 한 줄로 기록
- 커버할 패턴 (감사 보고서에서 추출, 기존 테스트와 중복되면 건너뛰고 목록에 사유 기록):
  1. **날짜/시간 경계** — UTC 저장 round-trip, 월말 이동 클램프, UTC 자정 경계의 주 시작(QA-B4), 미래 상대시간(friendlyRelativeTime)
  2. **stale async** — activeBoard 전환 후 옛 요청이 items/members/invite를 덮지 않음 (QA-C4 계열, `_stateRequestId` 계약)
  3. **로그아웃/탈퇴 시 알림 취소** — 로그아웃 3개 경로 모두 reminder sync(const []) 호출 (QA-C1)
  4. **타 보드 realtime 무시** — `shouldRefreshItemsForItemChildChange`의 board_id 불일치/누락/delete 케이스 (QA-C2m)
  5. **0-row mutation 실패** — updateMemberRole/removeMember/deleteComment/deleteItem이 빈 결과에서 StateError
  6. **Memory↔Supabase 동작 일치** — MemoryBoardRepository 보드별 스코프 (QA-C5)
- 구현 세부가 아니라 사용자 증상 중심으로 작성 (리팩터링 내성)

## C2. GitHub Actions CI
- `.github/workflows/ci.yml` 생성: push(main) + pull_request 트리거
- 단계: checkout → `subosito/flutter-action@v2`로 **Flutter 3.44.1 stable 고정** → `flutter pub get` → `flutter analyze --fatal-infos` → `flutter test`
- 캐시: pub 캐시 활성화 (`cache: true`)
- 타임아웃 15분, 동시성 그룹으로 중복 실행 취소(`concurrency`)

## C3. 릴리스 체크리스트 템플릿
- `docs/qa-reports/release-checklist-template.md` 생성. 항목:
  - [ ] `flutter analyze` 무이슈 (CI 링크)
  - [ ] `flutter test` 전부 통과 — 통과 개수 기록 (CI 링크)
  - [ ] `test/regression/` 회귀팩 통과
  - [ ] 로그아웃/보드 탈퇴 시 알림 취소 수동 확인
  - [ ] 새 마이그레이션 있으면: 운영 적용 여부 + RLS/트리거 검증 쿼리 결과
  - [ ] pubspec 버전 bump (`x.y.z+n`)
  - [ ] Known issues / 이월 항목 명시 (감사 ID 링크)
  - [ ] 롤백 조건 1줄
  - [ ] 승인자

## 검증 및 마무리
1. 위 WSL 명령으로 `flutter analyze` 무이슈, `flutter test` 전부 통과 확인 (회귀팩 포함, 실패 시 직접 수정)
2. CI yml은 로컬 실행이 불가하므로 문법을 정독 검토 (actionlint가 있으면 사용)
3. pubspec 버전은 변경하지 말 것 (CI/테스트는 앱 릴리스가 아님)
4. **git commit/push는 하지 말 것** — 변경 파일 목록, 테스트 결과(통과 개수), 신규 회귀 테스트 이름을 한국어로 보고하고 종료. 커밋은 사람이 검수 후 수행
