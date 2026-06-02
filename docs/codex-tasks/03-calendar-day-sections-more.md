# Codex Task — 달력 선택일에 할일 추가 + 카테고리별 3개 + 더보기 모달

> 작성: Claude(PM/QA) 2026-06-03. 구현: Codex. 완료 후 Claude 검증→커밋/푸시. 실기기 비주얼은 사용자 확인.
> 컨텍스트: `docs/claude_memory.md`. Korean UI 문자열은 `.dart`에서 `\u` 이스케이프. Warm Stone `AppColors`만 사용(새 색·새 패키지 금지). Surgical.

검증(셋 다 green):
```
C:\Users\a3030\development\flutter\bin\dart.bat format lib test
C:\Users\a3030\development\flutter\bin\flutter.bat analyze
C:\Users\a3030\development\flutter\bin\flutter.bat test
```

## 배경
달력 탭(`lib/screens/today_board_screen.dart`, `selectedTab == BoardTab.calendar`)은 지금 선택일의 **일정** 한 섹션만 보여줌. 사용자 요청: **할일도** 같이 보고, 각 카테고리 **최대 3개**만 표시, 초과 시 **더보기** 버튼 → 작은 스크롤 모달.

## 결정 (사용자 확정)
- **카테고리별 3개** 제한(일정 3 / 할일 3, 각각 독립 더보기).
- **공지는 제외** (날짜 개념 없음 → 달력엔 안 넣음). 일정 + 할일 두 섹션만.

## 구현

### 1. `BoardItemSection`에 개수 제한 + 더보기 (`lib/widgets/board_item_card.dart`)
- optional 파라미터 추가: `final int? maxVisible;`, `final VoidCallback? onShowMore;`.
- 동작:
  - `maxVisible == null` 또는 `items.length <= maxVisible` → 지금처럼 전부 렌더.
  - `items.length > maxVisible` → 앞에서 `maxVisible`개만 렌더하고, 그 아래에 **더보기 버튼**(예: `TextButton`/`InkWell`) 한 줄. 라벨: "더보기 +{items.length - maxVisible}" (한국어 `\u` 이스케이프, 예 `더보기 +3`). 색은 `accentColor`. 탭 → `onShowMore?.call()`.
  - 빈 상태(`emptyText`) 로직은 그대로.
- 기존 호출부 전부 그대로 동작해야 함(추가 파라미터는 옵셔널·기본 null).

### 2. 달력 탭에 할일 섹션 + 더보기 연결 (`today_board_screen.dart`)
현재 일정 `BoardItemSection` 블록을 다음으로:
- **일정 섹션**: 기존 그대로 + `maxVisible: 3`, `onShowMore: () => _showCalendarDaySheet(context, _CalendarDayCategory.schedule)`.
- 그 아래 **할일 섹션** 신설:
  - `title: '할 일'`, items = `tasks.where((t) => t.isForDate(_selectedCalendarDate))` (마감일이 그날인 할일).
  - `accentColor: AppColors.tertiary`, `accentSoftColor: AppColors.warningSoft`, `icon: Icons.check_rounded`.
  - `showCheckbox: true`, `onToggle: _toggleTask`, `isOverdue: _isOverdueTask`, `pendingTaskIds: _pendingTaskIds`.
  - `onItemTap: _showItemDetail`, `onTagTap: _setActiveTag`.
  - `emptyText: '이날 할 일이 없어요.'`.
  - `maxVisible: 3`, `onShowMore: () => _showCalendarDaySheet(context, _CalendarDayCategory.task)`.
- 공지 섹션은 추가하지 않음.

### 3. 더보기 모달 `_showCalendarDaySheet`
- `showModalBottomSheet`(rounded top 16, `isScrollControlled: true`, 배경 `AppColors.surface`)로 **작은 스크롤 창**.
- 높이: 내용에 맞추되 화면의 최대 ~70%까지(`DraggableScrollableSheet` 또는 `ConstrainedBox(maxHeight: MediaQuery height * 0.7)` + 내부 스크롤).
- 헤더: 날짜+카테고리 제목. 예 일정 → `'${month}월 ${day}일 일정'`, 할일 → `'${month}월 ${day}일 할 일'`. (friendly_date 헬퍼 있으면 재사용 가능하나 과설계 말 것.)
- 본문: 해당 카테고리의 **그날 전체 항목**을 스크롤 리스트로. 항목 렌더는 기존 카드 재사용 — 가장 단순하게 모달 안에서 `BoardItemSection`(maxVisible 없이=전체)을 `SingleChildScrollView`로 감싸 렌더하거나, 동일 콜백(onItemTap=_showItemDetail, 할일이면 showCheckbox/onToggle/isOverdue)으로 리스트 구성.
  - 일정 카테고리: schedule 항목, accent primary/primarySoft, 체크박스 없음.
  - 할일 카테고리: task 항목, accent tertiary/warningSoft, 체크박스 있음(onToggle _toggleTask).
- 항목 탭 시 상세시트 열기: 모달 위에 상세가 겹치면 어색하니, 탭하면 **이 시트를 먼저 닫고**(`Navigator.pop`) `_showItemDetail` 호출하는 식으로. (구현 단순 우선.)
- `_CalendarDayCategory { schedule, task }` enum은 파일 내부 private로.

### 4. 테스트
- `BoardItemSection` maxVisible: 4개 + maxVisible 3 → 3개만 보이고 "더보기 +1" 존재 / 3개 이하면 더보기 없음 / onShowMore 탭 콜백.
- 위젯: 달력 탭에 할일 섹션이 뜨고, 그날 할일 4개면 더보기 버튼 노출. (기존 달력 위젯 테스트와 충돌 안 나게.)

## 마무리
- format/analyze/test green, 테스트 수 보고(현재 127 → 증가 기대). 커밋/푸시는 Claude.
