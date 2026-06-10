// QA-C1: Logout or leaving the last board must cancel previously scheduled local reminders.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/screens/board_home_screen.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/notifications/reminder_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QA-C1 active board logout syncs an empty reminder plan', (
    tester,
  ) async {
    final scheduler = _RecordingReminderScheduler();

    await tester.pumpWidget(
      MaterialApp(
        home: BoardHomeScreen(
          client: _client(),
          repository: _ReminderRepository(withBoard: true),
          scheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.syncCalls.last, isNotEmpty);

    await tester.tap(find.byTooltip('설정'));
    await tester.pumpAndSettle();
    final signOut = find.text('로그아웃', skipOffstage: false);
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pump();

    expect(scheduler.syncCalls.last, isEmpty);
  });

  testWidgets('QA-C1 no-board logout still syncs an empty reminder plan', (
    tester,
  ) async {
    final scheduler = _RecordingReminderScheduler();

    await tester.pumpWidget(
      MaterialApp(
        home: BoardHomeScreen(
          client: _client(),
          repository: _ReminderRepository(withBoard: false),
          scheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('로그아웃'));
    await tester.pump();

    expect(scheduler.syncCalls.last, isEmpty);
  });

  testWidgets('QA-C1 load-error logout still syncs an empty reminder plan', (
    tester,
  ) async {
    final scheduler = _RecordingReminderScheduler();

    await tester.pumpWidget(
      MaterialApp(
        home: BoardHomeScreen(
          client: _client(),
          repository: _ThrowingRepository(),
          scheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('로그아웃'));
    await tester.pump();

    expect(scheduler.syncCalls.last, isEmpty);
  });

  testWidgets('QA-C1 leaving the last board syncs an empty reminder plan', (
    tester,
  ) async {
    final repository = _ReminderRepository(withBoard: true);
    final scheduler = _RecordingReminderScheduler();

    await tester.pumpWidget(
      MaterialApp(
        home: BoardHomeScreen(
          client: _client(),
          repository: repository,
          scheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가족'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('보드 나가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();

    expect(repository.leftBoardIds, ['board-1']);
    expect(scheduler.syncCalls.last, isEmpty);
  });
}

SupabaseClient _client() {
  return SupabaseClient('https://example.supabase.co', 'test-anon-key')
    ..auth.stopAutoRefresh();
}

class _ThrowingRepository extends BoardRepository {
  @override
  Future<List<BoardSummary>> loadBoards() {
    throw StateError('load failed');
  }
}

class _ReminderRepository extends BoardRepository {
  _ReminderRepository({required bool withBoard}) : _withBoard = withBoard;

  bool _withBoard;
  final leftBoardIds = <String>[];

  @override
  Future<List<BoardSummary>> loadBoards() async {
    if (!_withBoard) return const [];
    return const [
      BoardSummary(
        id: 'board-1',
        name: 'Home',
        role: 'member',
        maxMembers: 4,
        memberCount: 1,
      ),
    ];
  }

  @override
  Future<UserProfile?> loadMyProfile() async => const UserProfile(
        id: 'user-1',
        displayName: 'Mina',
        avatarColor: '#647D31',
      );

  @override
  Future<List<BoardMember>> loadMembers(String boardId) async => [
        BoardMember(
          userId: 'user-1',
          displayName: 'Mina',
          avatarColor: '#647D31',
          role: 'member',
          joinedAt: DateTime(2026, 6),
        ),
      ];

  @override
  Future<List<BoardItem>> loadBoardItems({String? boardId}) async => [
        BoardItem(
          id: 'schedule-1',
          type: BoardItemType.schedule,
          title: 'Dinner',
          detail: '',
          owner: 'Mina',
          timeLabel: '',
          startsAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      ];

  @override
  Future<void> leaveBoard(String boardId) async {
    leftBoardIds.add(boardId);
    _withBoard = false;
  }
}

class _RecordingReminderScheduler implements ReminderScheduler {
  final syncCalls = <List<ScheduledReminder>>[];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(List<ScheduledReminder> reminders) async {
    syncCalls.add(List<ScheduledReminder>.of(reminders));
  }
}
