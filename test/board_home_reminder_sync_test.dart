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

  testWidgets('syncs empty reminder plan after leaving the last board', (
    tester,
  ) async {
    final repository = _LeaveBoardRepository();
    final scheduler = _RecordingReminderScheduler();
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    )..auth.stopAutoRefresh();

    await tester.pumpWidget(
      MaterialApp(
        home: BoardHomeScreen(
          client: client,
          repository: repository,
          scheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.syncCalls, isNotEmpty);
    expect(scheduler.syncCalls.last, isNotEmpty);

    await tester.tap(find.text('\uAC00\uC871'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\uBCF4\uB4DC \uB098\uAC00\uAE30'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('\uB098\uAC00\uAE30'));
    await tester.pumpAndSettle();

    expect(repository.leftBoardIds, ['board-1']);
    expect(scheduler.syncCalls.last, isEmpty);
  });

  testWidgets('syncs empty reminder plan before logout', (tester) async {
    final repository = _LeaveBoardRepository();
    final scheduler = _RecordingReminderScheduler();
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    )..auth.stopAutoRefresh();

    await tester.pumpWidget(
      MaterialApp(
        home: BoardHomeScreen(
          client: client,
          repository: repository,
          scheduler: scheduler,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.syncCalls, isNotEmpty);
    expect(scheduler.syncCalls.last, isNotEmpty);

    await tester.tap(find.byTooltip('\uC124\uC815'));
    await tester.pumpAndSettle();
    final signOut = find.text('\uB85C\uADF8\uC544\uC6C3', skipOffstage: false);
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pump();

    expect(scheduler.syncCalls.last, isEmpty);
  });
}

class _LeaveBoardRepository extends BoardRepository {
  var boards = const [
    BoardSummary(
      id: 'board-1',
      name: 'Home',
      role: 'member',
      maxMembers: 4,
      memberCount: 1,
    ),
  ];
  final leftBoardIds = <String>[];

  @override
  Future<List<BoardSummary>> loadBoards() async => boards;

  @override
  Future<UserProfile?> loadMyProfile() async {
    return const UserProfile(
      id: 'user-1',
      displayName: 'Mina',
      avatarColor: '#647D31',
    );
  }

  @override
  Future<List<BoardMember>> loadMembers(String boardId) async {
    return [
      BoardMember(
        userId: 'user-1',
        displayName: 'Mina',
        avatarColor: '#647D31',
        role: 'member',
        joinedAt: DateTime(2026, 6),
      ),
    ];
  }

  @override
  Future<List<BoardItem>> loadBoardItems({String? boardId}) async {
    return [
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
  }

  @override
  Future<void> leaveBoard(String boardId) async {
    leftBoardIds.add(boardId);
    boards = const [];
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
