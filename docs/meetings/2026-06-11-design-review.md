# UriPan 디자인 리뷰 회의 — 2026-06-11

기준: v1.3.2 (`10f140c`), 브랜치 `track-c-quality-infra`. 참석: 디자인 에이전트 3명 (비주얼 / UX·레이아웃 / 모션·디테일). 의장: Claude.
방식: 읽기 전용 병렬 세션. 각자 `lib/theme`·`lib/widgets`·`lib/screens` 실코드 검토 후 Top 5 제안 + 1순위 픽 발표.
목표: "더 예쁘게" — 현재 디자인은 무난하지만 평범. 따뜻한 가족 보드 정체성을 살린 시각 완성도 향상.

## 참석자별 1순위 픽

| 참석자 | 1순위 | 핵심 논거 |
|--------|-------|-----------|
| 🎨 비주얼 | `app_theme.dart` 컴포넌트 테마 일괄 정의 (input/segmented/chip/dialog/snackBar/bottomSheet) | 커스텀 카드 사이로 M3 기본 모습의 필드·칩·다이얼로그가 노출되는 게 "Flutter 기본 앱" 인상의 최대 원인. 테마 파일 1곳 수정으로 전 화면 개선, 테스트 리스크 최소 |
| 📐 UX | 섹션 간격 리듬 재정립 (섹션 간 12→28px) + SectionHeader 액센트 바·카운트 pill | 섹션 간 12px vs 카드 간 10px — 2px 차이로는 그룹핑이 성립 안 해 화면이 "긴 카드 더미"로 읽힘. 간격 상수 + 위젯 1개 수정으로 4개 탭 동시 효과 |
| ✨ 모션 | **[결함] SoftCard 잉크 구조 수정** — InkWell이 불투명 카드를 감싸 리플이 카드 아래에 묻혀 **탭해도 시각 피드백 0** (`common_widgets.dart:97-104`, AppBottomNav 동일) | 취향이 아니라 Material 페인팅 순서 위반. 터치 피드백은 프리미엄 감의 0순위 전제이며 다른 모션 개선의 토대 |

## 교차 검토 수렴점

1. **라디우스 10종 난립** (7/8/9/12/14/15/16/17/18/22) — 비주얼 #2 + UX P4 독립 지목. `AppRadius` 토큰 4단(10/14/18/22)으로 통합 권고
2. **테마 미정의 컴포넌트** — 비주얼 1순위 + 모션 #4(bottomSheetTheme 부재로 시트마다 모서리 상이: 16 vs M3 기본 28) 수렴
3. **그림자 품질** — 비주얼(순수 블랙 → 웜 틴트 `#473A2B @8%`) + 모션(단층 → ambient/contact 2층) → `AppShadows` 토큰으로 통합
4. **숨은 하드코딩** — `board_item_card.dart:316`의 `Color(0xFF1A5FA8)`(테마 밖 유일 hex), 보더 알파값 7개 파일 산재, `FontWeight.w900` 지정이 폰트 미등록(800까지)으로 무효, `section_panel.dart`는 사용처 0인 데드 코드

## 의장 종합 — Track D "디자인 완성도" 권고안

| 순서 | 항목 | 난이도 | 출처 |
|------|------|--------|------|
| D1 | SoftCard·AppBottomNav 잉크 구조 수정 (Material/InkWell 재배치 + `Clip.antiAlias`) — `theme_warm_stone_test.dart` 호환 위해 AnimatedContainer 바깥 셸 유지 | M | 모션 1순위 |
| D2 | `app_theme.dart` 컴포넌트 테마 일괄 정의 + bottomSheetTheme(radius 24, dragHandle) 통일 | M | 비주얼 1순위 + 모션 #4 |
| D3 | 디자인 토큰: `AppRadius`(10/14/18/22) + `AppColors.border`(#E5E0D8) + `AppShadows`(웜 틴트 2층) + w900→w800 정리 + 하드코딩 `0xFF1A5FA8` 토큰 승격 + `section_panel.dart` 삭제 | S | 비주얼 #2·#4 + UX P4 + 모션 #4 |
| D4 | 섹션 리듬(간격 3단: 카드 10 / 헤더-리스트 10 / 섹션 28) + SectionHeader 액센트 바·카운트 pill (nullable 파라미터로 기존 테스트 호환) | S | UX 1순위 |
| D5 | 체크 완료 마이크로 인터랙션 (AnimatedSwitcher 200ms easeOutBack + 햅틱) + 탭 전환 페이드 220ms | M | 모션 #2·#3 |
| D6 | 카드 다이어트: 빈 detail 숨김, 비-task 아이콘 타일→4px 액센트 바, 본문 시작점 28px 통일 | M | UX P2 |
| D7 | 세이지그린 부활(공지 액센트 success→secondary+secondarySoft) + 아이콘 rounded 통일(가족 탭 `family_restroom_rounded`) + 캘린더 주말 색(일=빨강/토=파랑) | S | 비주얼 #3·#5 |

### 보류/이월
- BoardHeader 2단 구성 + FAB 이동 (UX P3) — 동선 변경이라 사용자 확인 후
- PulseCard 3열 스탯 히어로 (UX P5) — D1~D7 후 2차
- 다크모드 — 기존 결정대로 v1.4 이월 유지

### 권고 실행 순서
D1(잉크 결함) → D3(토큰) → D2(컴포넌트 테마) → D4(섹션 리듬) → D5~D7. 결함 수정과 토큰을 먼저 깔아야 이후 스타일 변경이 토큰 위에 쌓인다.
주의: 모든 애니메이션 유한(finite) — `pumpAndSettle` 무한 대기 금지. `theme_warm_stone_test.dart:43`의 `boxShadow!.single` 검증은 D3에서 토큰 값으로 갱신 필요.

## 진행 현황 (2026-06-11 갱신)
- ✅ D1~D7 전부 구현 완료 — codex 에이전트 3명이 Phase 1(D1+D3) → 2(D2+D4) → 3(D5+D6+D7) 순차 수행, Claude가 Phase별 WSL 검증. 실행 프롬프트: `docs/prompts/track-d-codex.md`
- 검증: `flutter analyze` 무이슈, `flutter test` 206개 전부 통과
- 보류 항목 유지: BoardHeader 2단+FAB(UX P3), PulseCard 3열(UX P5), 다크모드(v1.4)
