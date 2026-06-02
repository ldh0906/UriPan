# Codex Task — 달력 평면 그리드 + 연속 멀티데이 막대

> 작성: Claude(PM/QA) 2026-06-03. 구현: Codex. 완료 후 Claude가 analyze/test 검증→커밋/푸시. 실기기 비주얼은 사용자가 확인.
> 컨텍스트: `docs/claude_memory.md`. Korean UI 문자열은 `.dart`에서 `\u` 이스케이프. Warm Stone `AppColors` 토큰만 사용(새 색 금지).

검증(셋 다 green):
```
C:\Users\a3030\development\flutter\bin\dart.bat format lib test
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
```

## 문제 (현재 상태)
`lib/screens/today_board_screen.dart`의 달력:
- **주간 스트립**(`_buildWeek`)은 `bars: const []`라 멀티데이도 날짜별 점만 → 연속 일정이 "점점점"으로 보임.
- **월간 그리드**(`_buildMonthGrid` + `_CalendarDayCell`)는 각 날짜가 테두리·둥근모서리·간격 있는 카드라, 칸 안 막대가 칸 사이를 못 건너 토막남.

## 결정 (사용자 선택)
**구글 캘린더식 평면 그리드**로 재구성. 날짜별 카드 섬(테두리/배경/둥근모서리/칸 간격) 제거 → 평평한 격자. 멀티데이 일정은 **칸을 가로지르는 연속 가로 막대**. **주간·월간 둘 다** 적용.

## 구현

### 1. 평면 그리드 스타일 (`_CalendarDayCell` 또는 후속 위젯 재작성)
- 날짜 칸의 `Container` 테두리(`Border.all`)·`primarySoft` 배경·`borderRadius` 카드 룩 제거. 칸 사이 가로 간격(`SizedBox(width: 6)` 등) 제거 → 칸들이 **딱 붙음**(Expanded, gap 0).
- 날짜 숫자: 평문 텍스트(가운데). **선택일** = 숫자 뒤에 `AppColors.primary` 채운 원(지름 ~28) + `onPrimary` 텍스트. **오늘** = `AppColors.primary` 텍스트(굵게) 또는 원형 외곽선(선택일과 겹치면 선택 우선). **이번 달 밖 날짜** = `mutedText` 흐리게.
- 주 사이 세로 간격은 막대 lane 공간 확보용으로 최소 유지. 칸 배경은 투명(혹은 아주 옅은 행 구분선 1개 정도, 과하지 않게).
- 접근성: 기존 `Semantics(button, selected, label)` 유지.

### 2. 연속 막대 = lane 기반 렌더 (핵심)
한 주(7칸) 행마다 그 주를 지나는 **일정(schedule)** 들을 lane으로 쌓아 가로 막대로 그린다.
- **순수 계산 함수**(테스트 가능) 추가, 예: `List<_CalendarBarSegment> calendarWeekBars({required List<BoardItem> schedules, required DateTime weekStart})`.
  - 그 주 `weekStart`(월요일)~`weekStart+6`(일요일)와 교집합 있는 schedule만.
  - 각 schedule의 `start=dateOnly(startsAt)`, `end=dateOnly(dueAt ?? startsAt)`, `effectiveEnd = end<start ? start : end`.
  - 그 주 안에서 `segStartCol = clamp(start, weekStart..weekEnd)`의 컬럼 인덱스(0~6), `segEndCol` 동일.
  - `roundedLeft = (start >= weekStart)`(실제 시작이 이 주 안) , `roundedRight = (effectiveEnd <= weekEnd)`(실제 끝이 이 주 안). 아니면 사각(다음/이전 주로 이어짐 표시).
  - **lane 배정**: 같은 주에서 컬럼 구간이 겹치지 않으면 같은 lane 재사용(겹치면 다음 lane). 시작일 순 정렬 후 그리디.
  - **최대 lane 수 = 3**. 초과분은 버림(혹은 마지막 lane에 "+N" 작은 표식 — 과설계 말고 우선 버림).
  - 단일일 일정(start==end)도 막대로(한 칸 폭, 양끝 둥근).
- **렌더**: 각 주 행에서 날짜 숫자 줄 아래에 lane 개수만큼 막대 줄. 각 막대 줄 = 7개 `Expanded` 슬롯의 Row. 슬롯이 그 막대 구간(segStartCol..segEndCol)에 포함되면 `AppColors.primary` 채움(높이 ~5, 세로 패딩 1~2), `BorderRadius.horizontal(left: roundedLeft&&firstCol? 999:0, right: roundedRight&&lastCol? 999:0)`. 포함 안 되면 투명. **인접 채움 슬롯이 gap 0으로 붙어 연속 막대**가 됨. 같은 lane의 서로 다른 일정은 같은 줄에서 컬럼만 다르게.
  - 선택일 칸과 막대가 겹쳐도 막대는 그대로(선택 원은 숫자 뒤 레이어, 막대는 그 아래 줄).

### 3. 할일/공지
- **할일(task)**: 막대 아님. 마감일 칸 숫자 아래 작은 **앰버 점**(`AppColors.tertiary`) 유지. (일정=막대 vs 할일=점으로 "기간 있는 것" vs "그날 할 일" 구분.)
- **공지**: 표시 없음(기존대로).
- 기존 `_indicatorsForDay`에서 schedule 카운트 점은 **제거**(이제 막대가 대체). task 점만 남김.

### 4. 주간/월간 공통화
- 주간 스트립도 같은 lane 막대 렌더(주 1행). `_buildWeek`가 더 이상 `bars: const []` 넘기지 않도록.
- 월간은 6주 각 행에 동일 적용.

### 5. 테스트
- `calendarWeekBars` 순수 함수: 단일일/주 안 멀티데이/주 경계 걸친 일정(왼쪽·오른쪽 사각 끝)/겹치는 두 일정 lane 분리/3개 초과 버림/역전(end<start) 방어.
- 위젯 스모크: 멀티데이 일정 있을 때 막대 슬롯이 연속 컬럼에 그려지는지(키/finder로).

## 마무리
- format/analyze/test green, 테스트 수 보고(현재 120 → 증가 기대). 커밋/푸시는 Claude.
- 막대 색·점 색 전부 기존 `AppColors`(primary/tertiary)만. 새 색·새 패키지 금지.
