# UriPan 코멘트(댓글) 기능 설계

- 날짜: 2026-06-02
- 상태: 승인됨 (brainstorming 완료, 구현 계획 작성 전)
- 작성: Claude (PM/QA), 사용자 승인

## 1. 배경 / 목표

UriPan은 가족·친구가 일정·할일·공지를 함께 보는 공유 보드다. 제품 한 줄 약속은 "말했잖아 / 언제? / 못 봤는데?"를 줄이는 것. 현재 항목에 대한 **가벼운 소통 수단이 없다.** 본 기능은 각 보드 항목에 멤버들이 짧은 텍스트 코멘트를 남길 수 있게 한다.

이번 페이즈로 현재 기능 단계를 닫는다(코멘트 이후 주제는 UI/UX 폴리시). FCM 푸시는 범위 밖(Phase B).

## 2. 범위

### 들어가는 것
- 각 항목(일정/할일/공지) 상세 시트 안의 코멘트 목록 + 입력창 + 보내기
- 코멘트 = 작성자(이름·아바타) + 본문 + 친절한 상대시간
- 작성: 보드 멤버 누구나
- 삭제: 본인 코멘트 또는 보드 관리자 (확인 다이얼로그 + 한국어 에러 매핑)
- 빈 상태 문구 (기존 EmptyState 패턴)
- 카드에 코멘트 수 배지 (💬 N), N>0일 때만
- 상세 시트가 열려 있는 동안 해당 항목 코멘트 실시간 구독(채팅처럼 즉시 반영), 닫으면 해제

### 빠지는 것 (YAGNI)
- 편집, 답글/스레딩, @멘션, 이모지 반응, 사진·첨부
- 새 코멘트 푸시 알림(FCM/APNs) — Phase B
- 코멘트 수의 실시간 갱신 — 아래 결정 D2 참조

## 3. 확정된 결정
- D1: 코멘트 스레드는 실시간. 같은 항목을 동시에 보는 멤버끼리 새 코멘트가 새로고침 없이 즉시 보인다.
- D2: 코멘트 수 배지는 표시하되 카운트는 비실시간(선택지 C). 카드 배지는 보드 로드/새로고침/항목(board_items) 변경 시 갱신되며, item_comments 변경을 보드 레벨에서 실시간 구독하지는 않는다. (스레드 자체는 D1대로 실시간.)
- 비고: D1을 위해 item_comments는 realtime publication에 포함되어야 한다. D2는 "보드 레벨 구독에 item_comments 리스너를 추가하지 않는다"는 의미일 뿐, publication 포함과 무관하지 않다 — publication에는 포함한다.

## 4. 데이터 모델 (새 마이그레이션)

파일: supabase/migrations/20260602000000_add_item_comments.sql

```sql
create table public.item_comments (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.board_items(id) on delete cascade,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index item_comments_item_id_idx on public.item_comments(item_id, created_at);
```

- board_id 컬럼은 두지 않는다. 보드 멤버십은 item_comments → board_items 조인으로 끌어온다(item_confirmations와 동일 전략).

## 5. RLS / 권한 (item_confirmations 패턴 차용)

- `alter table public.item_comments enable row level security;`
- `alter publication supabase_realtime add table public.item_comments;`
- 정책:
  - select: 해당 항목이 속한 보드의 멤버 (`exists (select 1 from board_items bi where bi.id = item_comments.item_id and public.is_board_member(bi.board_id))`)
  - insert: `author_id = auth.uid()` AND 위 보드 멤버 조건
  - delete: 본인(author_id = auth.uid()) **또는** 그 항목 보드의 관리자(`public.is_board_admin(bi.board_id)`)
- anon revoke, authenticated에 select/insert/delete grant (update는 미부여 — 편집 없음).

## 6. 모델 + Repository

- 새 모델 BoardComment { id, itemId, authorId, authorName, authorAvatarColor, body, createdAt } (lib/models/board_item.dart에 추가).
- BoardRepository에 메서드 추가:
  - `Future<List<BoardComment>> loadComments(String itemId)` (오래된→최신 정렬)
  - `Future<BoardComment> addComment(String itemId, String body)`
  - `Future<void> deleteComment(String commentId)`
- MemoryBoardRepository: 인메모리 리스트로 구현(데모/테스트). 작성자는 _myProfile 기준.
- SupabaseBoardRepository: item_comments 테이블 + profiles 조인으로 이름/아바타 색 해석. addComment은 author_id = 현재 유저로 insert 후 단건 select.
- 코멘트 수 배지(D2): board_items select 컬럼에 `item_comments(count)`를 추가하고 BoardItem에 `commentCount`(기본 0) 필드를 더한다. 비실시간이므로 보드 레벨 realtime 구독에는 item_comments를 추가하지 않는다.

## 7. UI

- lib/widgets/item_detail_sheet.dart 하단에 코멘트 섹션:
  - 목록: 각 코멘트 = MemberAvatar + 이름 + 본문 + 친절한 시간.
  - 입력창 + 보내기 버튼(빈 본문 차단, 1000자 제한).
  - 본인/관리자 코멘트에 삭제 액션 → 확인 다이얼로그 → deleteComment. 실패 시 한국어 에러 매핑(board_home_screen의 _friendlyDatabaseError 경로 재사용/확장).
  - 비었을 때 EmptyState("아직 코멘트가 없어요." 류, .dart에서는 \u 이스케이프).
- 카드(board_item_card.dart): commentCount > 0이면 💬 N 배지(기존 칩/배지 스타일 차용).
- 모든 한국어 문자열은 .dart에서 \u 이스케이프.

## 8. 친절한 상대시간

- lib/services/friendly_date.dart에 함수 추가: 방금 / N분 전 / N시간 전 / 어제 / M.D 형태. 순수 함수로 유닛테스트.

## 9. 실시간 (스레드)

- 상세 시트 열림 시 해당 item_id의 item_comments를 구독(보드 레벨 BoardRealtimeSubscription 패턴 차용, 시트 전용 경량 구독). insert/delete 콜백 → 스레드 목록 갱신. 시트 닫힐 때 채널 해제.

## 10. 테스트 (기존 73→ 유지, 추가)

- 유닛: 친절한 상대시간 포맷, MemoryBoardRepository 코멘트 CRUD(add/load 정렬/delete).
- 위젯: 상세 시트 코멘트 렌더, 작성 콜백 호출, 삭제 확인 다이얼로그, 빈 상태, 카드 commentCount 배지 표시/미표시.
- RLS 의도: docs/supabase/rls-checks.sql에 코멘트 select/insert/delete 케이스 추가(문서).
- 기존 테스트 전부 그린 유지. 행동 보존(추가만).

## 11. 마이그레이션 / 배포 노트

- 첫 스키마 변경(Phase 2까지 client-only였음). 원격 적용은 supabase 마이그레이션으로.
- realtime publication 변경 포함.

## 12. 향후(Phase B 연결 지점)

- 새 코멘트 푸시는 item_comments insert를 트리거로 하는 Supabase Edge Function으로 나중에 얹는다. 본 설계의 코멘트 코드는 그 추가 시 변경 불필요(insert 지점이 곧 트리거 지점).
