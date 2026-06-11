# Track D 실행 프롬프트 (codex용, 3단계)

> 사용법: Phase별로 codex에게 "docs/prompts/track-d-codex.md의 Phase N을 읽고 그대로 수행해"라고 지시. **반드시 Phase 1 → 2 → 3 순서로, 각 Phase의 테스트 통과 후 다음 진행** (동일 파일을 단계적으로 수정하므로 병렬 금지).

근거 문서: `docs/meetings/2026-06-11-design-review.md` (Track D 권고안)

## 공통 규칙 (모든 Phase)

- Flutter SDK는 Windows가 아니라 **WSL Ubuntu**에 있음. 검증 명령:
  - `wsl.exe -d Ubuntu -- bash -c "cd /mnt/c/UriPan && /home/a/development/flutter/bin/flutter analyze"`
  - `wsl.exe -d Ubuntu -- bash -c "cd /mnt/c/UriPan && /home/a/development/flutter/bin/flutter test"`
- 종료 조건: `flutter analyze` 무이슈 + `flutter test` 전체 통과. 실패 시 직접 수정 후 재실행.
- 모든 애니메이션은 **유한(finite)** — 반복(repeat) 애니메이션 금지 (`pumpAndSettle` 무한 대기 유발).
- 기존 `Semantics`/`ExcludeSemantics` 구조 보존. 절제된 모션 (180~300ms, 표준 커브).
- pubspec 버전 변경 금지. **git commit/push 금지** — 변경 파일 목록과 테스트 통과 개수를 한국어로 보고하고 종료.

---

## Phase 1 — D1 잉크 결함 수정 + D3 디자인 토큰

### D1. SoftCard·AppBottomNav 잉크 구조 수정 (결함)
현재 `lib/widgets/common_widgets.dart`의 `SoftCard`는 InkWell이 **불투명** AnimatedContainer를 child로 감싸 리플이 카드 아래에 묻힘 — 탭해도 시각 피드백 0. 페인팅 순서를 재배치하라:

```
AnimatedContainer(duration: 180ms)        // 바깥 셸: borderRadius·border·boxShadow만 (color 제거)
└─ Material(color: color, clipBehavior: Clip.antiAlias,
     shape: RoundedRectangleBorder(borderRadius: AppRadius.lg))
   └─ InkWell(onTap,
        splashColor: AppColors.primary @6%, highlightColor: AppColors.primary @4%)
      └─ Padding(padding) └─ child
```

- **호환 주의**: `test/theme_warm_stone_test.dart`가 SoftCard 내부 AnimatedContainer의 borderRadius/boxShadow를 검증함 → AnimatedContainer를 바깥 셸로 유지하면 통과. boxShadow 검증(`single` 등)은 D3 토큰 값으로 갱신 필요.
- `AppBottomNav`: 탭 버튼 InkWell이 리플을 그릴 수 있도록 투명 `Material(type: MaterialType.transparency)` 한 겹을 InkWell 바깥(불투명 배경 안)에 추가.

### D3. 디자인 토큰 (`lib/theme/app_theme.dart`)
1. `AppRadius` 상수 클래스 신설: `sm=10, md=14, lg=18, xl=22, pill=999.0`. 기존 라디우스 치환 매핑:
   - 7, 8, 9 → `sm`(10) — _OverdueChip(board_item_card.dart), 태그칩, InviteCodePanel(board_header.dart), _SmallPill(common_widgets.dart)
   - 12, 14, 15 → `md`(14) — 카드 아이콘 타일, 버튼류
   - 16, 17, 18 → `lg`(18) — SoftCard, PulseCard 아이콘
   - 22 → `xl`(22) — 로그인 카드(login_screen.dart)
2. `AppColors.border = Color(0xFFE5E0D8)` 신설 — 흩어진 `AppColors.text.withValues(alpha: 0.05~0.08)` 보더를 대체.
3. `AppShadows.card` 토큰 (`static const List<BoxShadow>`) — 웜 틴트 2층:
   - ambient: `Color(0x12473A2B)`, blurRadius 16, offset(0, 6)
   - contact: `Color(0x0F473A2B)`, blurRadius 3, offset(0, 1)
   - SoftCard·로그인 카드의 기존 순수 블랙 단층 그림자를 대체. `theme_warm_stone_test.dart`의 그림자 검증을 토큰 값으로 갱신.
4. `AppColors.primaryDeep = Color(0xFF2563A8)` 신설 — `board_item_card.dart`의 하드코딩 `Color(0xFF1A5FA8)`(태그 칩 텍스트)를 대체.
5. `FontWeight.w900` 지정 전부 `w800`으로 정리 (Pretendard는 800까지만 등록됨 — pubspec.yaml 참고. 시각 결과 동일): `common_widgets.dart`, `today_board_screen.dart` 등 전수 검색.
6. `lib/widgets/section_panel.dart` 삭제 — 사용처 0인 데드 코드 (삭제 전 참조 전수 검색으로 확인).

---

## Phase 2 — D2 컴포넌트 테마 + D4 섹션 리듬

### D2. `app_theme.dart` 컴포넌트 테마 일괄 정의
현재 로그인 필드·세그먼트 버튼·칩·다이얼로그·시트가 M3 기본값으로 노출됨. ThemeData에 추가:

- `inputDecorationTheme`: `filled: true, fillColor: Colors.white`, `OutlineInputBorder(borderRadius: AppRadius.md, borderSide: AppColors.border 1px)`, focused는 primary 1.5px, label/hint는 mutedText
- `segmentedButtonTheme`: selected bg `AppColors.primarySoft`, selected fg `AppColors.primaryDeep`, side `AppColors.border`
- `chipTheme`: bg `AppColors.surfaceVariant`, selected bg `AppColors.primarySoft`, radius `AppRadius.sm`, side 없음
- `dialogTheme`: radius `AppRadius.xl`, bg surface, `surfaceTintColor: Colors.transparent`
- `snackBarTheme`: bg `Color(0xFF2A2A30)`, radius `AppRadius.md`, `behavior: SnackBarBehavior.floating`
- `bottomSheetTheme`: `RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`, `showDragHandle: true`, bg surface, `surfaceTintColor: Colors.transparent`
- 시트 ad-hoc shape/backgroundColor 지정 제거 (예: `today_board_screen.dart`의 캘린더 일자 시트 radius 16 직접 지정) → 테마로 일원화. 단 `showDragHandle` 도입으로 시트 상단 여백이 변하면 기존 시트 내 자체 핸들 위젯과 중복되는지 확인하고 중복 제거.
- 로그인 화면(login_screen.dart)에 TextField 데코레이션이 인라인으로 있으면 테마와 충돌하는 부분만 제거.

### D4. 섹션 리듬 + SectionHeader 액센트
1. 간격 3단 리듬: 카드 간 10 / 헤더-리스트 10 / **섹션 간 28**.
   - `today_board_screen.dart`의 섹션 사이 `SizedBox(height: 12)` → 28 (오늘 탭 섹션 경계 4곳), PulseCard→첫 섹션 12 → 20, 캘린더 탭 16 → 20.
2. `SectionHeader`(common_widgets.dart)에 `accentColor`/`accentSoftColor` **nullable** 파라미터 추가 (기본 null = 기존 렌더 유지 → 기존 호출부·테스트 호환):
   - accentColor 지정 시: 타이틀 좌측에 4×18px 라운드(radius 2) 컬러 바 + `SizedBox(width: 8)`
   - 카운트: 기존 파란 텍스트 → `accentSoftColor` 배경 pill (패딩 H8/V3, radius `AppRadius.pill`, 텍스트는 accentColor w700)
3. `BoardItemSection`(board_item_card.dart)이 이미 받는 accentColor/accentSoftColor를 SectionHeader로 전달.

---

## Phase 3 — D5 모션 + D6 카드 다이어트 + D7 컬러·아이콘

### D5. 마이크로 인터랙션 (board_item_card.dart, today_board_screen.dart, common_widgets.dart)
1. 체크 토글 아이콘: `AnimatedSwitcher(duration: 200ms, switchInCurve: Curves.easeOutBack, transitionBuilder: ScaleTransition)` + 상태별 `ValueKey`. pending 스피너도 같은 스위처에 태움. 완료 시 `HapticFeedback.lightImpact()` (해제 시 생략 가능).
2. 제목 취소선·색 전환: `Text` → `AnimatedDefaultTextStyle(duration: 250ms, curve: Curves.easeOut)`.
3. 탭 전환: 탭별 콘텐츠를 `_buildTabContent(selectedTab)`로 추출 후 `AnimatedSwitcher(duration: 220ms)` — `FadeTransition` + 미세 `SlideTransition(begin: Offset(0, 0.015))`, `Curves.easeOutCubic`, `KeyedSubtree(key: ValueKey(selectedTab))` 필수. 콘텐츠 추출이 위젯 트리를 크게 흔들면 탭 전환 스위처는 생략 가능 (보고에 사유 기록).
4. AppBottomNav 선택 pill: `Container` → `AnimatedContainer(200ms, Curves.easeOutCubic)`, 라벨 → `AnimatedDefaultTextStyle`.
- 기존 `find.byIcon(Icons.check_circle_rounded)` 류 테스트 파인더 유지 확인.

### D6. BoardItemCard 다이어트 (board_item_card.dart)
1. 빈 detail 숨김: `item.detail.trim().isNotEmpty`일 때만 detail Text + 간격 렌더.
2. 비-task 카드의 42px 아이콘 타일 → **4px 세로 액센트 바** (`accentColor`, stretch, radius 2) + 간격 10. 섹션 헤더가 이미 종류를 표시하므로(P D4) 카드 내 반복 아이콘 제거.
3. 본문 시작점 통일: task(체크박스)와 비-task(액센트 바)의 제목 좌측 시작점이 같도록 체크박스 영역 폭 조정.
- 카드 아이콘을 find하는 위젯 테스트가 있으면 새 구조에 맞게 갱신 (의도 유지).

### D7. 컬러·아이콘 마감
1. `AppColors.secondarySoft = Color(0xFFE9F2EE)` 신설. 공지 섹션 액센트를 success(#2D7A5B)→`secondary`(#6D9B8A)+`secondarySoft`로 교체 (`today_board_screen.dart`의 공지 섹션 accentColor/accentSoftColor). success는 상태 피드백 전용으로 분리.
2. 하단 내비 아이콘 rounded 통일 (`common_widgets.dart` BoardTab.icon): `dashboard_customize_outlined→space_dashboard_rounded`, `calendar_month_outlined→calendar_month_rounded`, `check_box_outlined→check_circle_outline_rounded`, `campaign_outlined→campaign_rounded`, `group_outlined→family_restroom_rounded`.
3. PulseCard 아이콘 `monitor_heart_rounded` → `home_rounded` (board_header.dart).
4. 캘린더 주말 색 (today_board_screen.dart 캘린더 그리드): 일요일 숫자 `Color(0xFFC94F4F)`, 토요일 `Color(0xFF3B82C4)` (오늘/선택 상태 스타일이 우선).
- 아이콘 기반 테스트 파인더(`find.byIcon`)가 구 아이콘을 참조하면 갱신.
