import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/main.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/screens/board_home_screen.dart';
import 'package:uripan/screens/today_board_screen.dart';
import 'package:uripan/services/auth_error_messages.dart';
import 'package:uripan/services/auth_input_validator.dart';
import 'package:uripan/services/board_repository.dart';
import 'package:uripan/services/notifications/reminder_planner.dart';
import 'package:uripan/services/notifications/reminder_scheduler.dart';
import 'package:uripan/widgets/board_action_sheets.dart';
import 'package:uripan/widgets/board_item_card.dart';
import 'package:uripan/widgets/comment_thread.dart';
import 'package:uripan/widgets/board_settings_sheet.dart';
import 'package:uripan/widgets/common_widgets.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('UriPan shows the Today board sections', (tester) async {
    await tester.pumpWidget(const UriPanApp());
    await tester.pumpAndSettle();

    expect(find.text('\uC6B0\uB9AC\uC9D1'), findsOneWidget);
    expect(find.text('\uC624\uB298 \uBCF4\uB4DC'), findsOneWidget);
    expect(find.text('\uC624\uB298\uC758 \uC0C1\uD669'), findsOneWidget);
    expect(find.text('\uC624\uB298 \uC77C\uC815'), findsOneWidget);
    expect(find.text('\uD560 \uC77C'), findsWidgets);
    expect(find.text('\uACF5\uC9C0'), findsWidgets);
    expect(find.text('\uCD94\uAC00'), findsOneWidget);
  });

  testWidgets('Today board shows notice count badges only when present', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBoardScreen(
          items: [
            BoardItem(
              id: 'notice-badge',
              type: BoardItemType.notice,
              title: 'Required notice',
              detail: 'Please confirm',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
            ),
            BoardItem(
              id: 'confirmed-notice',
              type: BoardItemType.notice,
              title: 'Confirmed notice',
              detail: 'Already read',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
              isConfirmedByMe: true,
            ),
          ],
          selectedTab: BoardTab.notices,
          onTabSelected: null,
        ),
      ),
    );

    final bottomNav = find.byType(AppBottomNav);
    final noticeBadge = find.byKey(const Key('app-bottom-nav-badge-notices'));

    expect(
      find.descendant(of: bottomNav, matching: find.text('\uACF5\uC9C0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: noticeBadge, matching: find.text('1')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBoardScreen(
          items: [
            BoardItem(
              id: 'confirmed-notice',
              type: BoardItemType.notice,
              title: 'Confirmed notice',
              detail: 'Already read',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
              isConfirmedByMe: true,
            ),
          ],
          selectedTab: BoardTab.notices,
          onTabSelected: null,
        ),
      ),
    );

    expect(
      find.descendant(of: bottomNav, matching: find.text('\uACF5\uC9C0')),
      findsOneWidget,
    );
    expect(noticeBadge, findsNothing);
  });

  testWidgets('AppBottomNav caps badge labels at 9+', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(
            selectedTab: BoardTab.today,
            badges: const {BoardTab.notices: 10},
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('Key board controls expose accessibility semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final now = DateTime(2026, 6, 2, 12);
    final calendarLabel = RegExp('${now.month}\uC6D4 ${now.day}\uC77C');

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'tagged-task',
              type: BoardItemType.schedule,
              title: 'Tagged schedule',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
              tags: const ['family'],
              startsAt: now,
            ),
          ],
          selectedTab: BoardTab.calendar,
          onTabSelected: _ignoreBoardTab,
          onOpenSettings: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('\uC624\uB298'), findsOneWidget);
    expect(find.bySemanticsLabel('\uC124\uC815'), findsOneWidget);
    expect(find.bySemanticsLabel('\uD0DC\uADF8 family'), findsOneWidget);
    expect(find.bySemanticsLabel(calendarLabel), findsOneWidget);

    semantics.dispose();
  });

  test('auth input validation blocks invalid id/password payloads', () {
    expect(
      AuthInputValidator.validateUserIdPassword('', ''),
      '\uC544\uC774\uB514\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateUserIdPassword('ab', '123456'),
      '\uC544\uC774\uB514\uB294 3\uC790 \uC774\uC0C1\uC73C\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateUserIdPassword('family home', '123456'),
      '\uC544\uC774\uB514\uB294 \uC601\uBB38, \uC22B\uC790, -, _\uB9CC \uC0AC\uC6A9\uD560 \uC218 \uC788\uC5B4\uC694.',
    );
    expect(
      AuthInputValidator.validateUserIdPassword('family01', ''),
      '\uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateUserIdPassword('family01', '12345'),
      '\uBE44\uBC00\uBC88\uD638\uB294 6\uC790 \uC774\uC0C1\uC73C\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateUserIdPassword('family01', '123456'),
      isNull,
    );
    expect(AuthInputValidator.normalizeUserId(' Family_01 '), 'family_01');
    expect(
      AuthInputValidator.syntheticEmailForUserId(' Family_01 '),
      'family_01@auth.uripan.app',
    );
  });

  test('auth error mapping explains id/password signup failures', () {
    expect(
      AuthErrorMessages.fromAuthMessage('429: email rate limit exceeded'),
      '\uAC00\uC785 \uC694\uCCAD\uC774 \uB9CE\uC544\uC694. \uC7A0\uC2DC \uD6C4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthErrorMessages.fromAuthMessage(
        '400: Email address "test@gmail.com" is invalid',
      ),
      '\uC544\uC774\uB514\uB97C \uD655\uC778\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthErrorMessages.fromAuthMessage('422: Anonymous sign-ins are disabled'),
      '\uC544\uC774\uB514\uC640 \uBE44\uBC00\uBC88\uD638\uB85C \uB85C\uADF8\uC778\uD574\uC8FC\uC138\uC694.',
    );
  });

  testWidgets('Today tab hides future dated schedules and tasks', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);
    final tomorrow = now.add(const Duration(days: 1));

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'today-schedule',
              type: BoardItemType.schedule,
              title: 'Today schedule',
              detail: '',
              owner: 'Us',
              timeLabel: '09:00',
              startsAt: DateTime(now.year, now.month, now.day, 9),
            ),
            BoardItem(
              id: 'future-schedule',
              type: BoardItemType.schedule,
              title: 'Future schedule',
              detail: '',
              owner: 'Us',
              timeLabel: '09:00',
              startsAt: DateTime(
                tomorrow.year,
                tomorrow.month,
                tomorrow.day,
                9,
              ),
            ),
            BoardItem(
              id: 'today-task',
              type: BoardItemType.task,
              title: 'Today task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
              dueAt: DateTime(now.year, now.month, now.day, 18),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Today schedule'), findsOneWidget);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Future schedule'), findsNothing);
  });

  testWidgets('Board item card derives friendly due date meta from dueAt', (
    tester,
  ) async {
    final now = DateTime.now();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardItemCard(
            item: BoardItem(
              id: 'today-task',
              type: BoardItemType.task,
              title: 'Today task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
              dueAt: DateTime(now.year, now.month, now.day, 18),
            ),
            accentColor: Colors.blue,
            accentSoftColor: Colors.blue.shade50,
            icon: Icons.check_rounded,
          ),
        ),
      ),
    );

    expect(find.textContaining('\uC624\uB298'), findsOneWidget);
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('Board item card shows comment badge only when comments exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardItemCard(
            item: const BoardItem(
              id: 'with-comments',
              type: BoardItemType.notice,
              title: 'With comments',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
              commentCount: 3,
            ),
            accentColor: Colors.blue,
            accentSoftColor: Colors.blue.shade50,
            icon: Icons.campaign_rounded,
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.mode_comment_outlined), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardItemCard(
            item: BoardItem(
              id: 'without-comments',
              type: BoardItemType.notice,
              title: 'Without comments',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
              commentCount: 0,
            ),
            accentColor: Colors.green,
            accentSoftColor: Colors.green.shade50,
            icon: Icons.campaign_rounded,
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.byIcon(Icons.mode_comment_outlined), findsNothing);
  });

  testWidgets('CommentThread renders comments and sends trimmed text', (
    tester,
  ) async {
    final comments = [
      BoardComment(
        id: 'comment-1',
        itemId: 'item-1',
        authorId: 'user-1',
        authorName: 'Mina',
        authorAvatarColor: '#3366FF',
        body: 'Looks good',
        createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    ];
    final addedBodies = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentThread(
            loadComments: () async => comments,
            onAddComment: (body) async => addedBodies.add(body),
            onDeleteComment: (_) async {},
            currentUserId: 'user-2',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Looks good'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Thanks  ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(addedBodies, ['Thanks']);
  });

  testWidgets('CommentThread shows empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentThread(
            loadComments: () async => const [],
            onAddComment: (_) async {},
            onDeleteComment: (_) async {},
            currentUserId: 'user-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('\uC544\uC9C1 \uB313\uAE00\uC774 \uC5C6\uC5B4\uC694'),
      findsOneWidget,
    );
  });

  testWidgets('CommentThread reloads on realtime changes and disposes', (
    tester,
  ) async {
    VoidCallback? onChanged;
    var loadCount = 0;
    var didDispose = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentThread(
            itemId: 'item-1',
            loadComments: () async {
              loadCount += 1;
              return const [];
            },
            onAddComment: (_) async {},
            onDeleteComment: (_) async {},
            currentUserId: 'user-1',
            subscribeComments: (itemId, callback) {
              expect(itemId, 'item-1');
              onChanged = callback;
              return () => didDispose = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(loadCount, 1);
    onChanged!();
    await tester.pumpAndSettle();

    expect(loadCount, 2);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(didDispose, isTrue);
  });

  testWidgets('CommentThread confirms before deleting author comment', (
    tester,
  ) async {
    final comment = BoardComment(
      id: 'comment-1',
      itemId: 'item-1',
      authorId: 'user-1',
      authorName: 'Mina',
      authorAvatarColor: '#3366FF',
      body: 'Remove me',
      createdAt: DateTime.now(),
    );
    final deleted = <BoardComment>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentThread(
            loadComments: () async => [comment],
            onAddComment: (_) async {},
            onDeleteComment: (comment) async => deleted.add(comment),
            currentUserId: 'user-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('\uB313\uAE00 \uC0AD\uC81C'), findsOneWidget);

    await tester.tap(find.text('\uC0AD\uC81C'));
    await tester.pumpAndSettle();

    expect(deleted, [comment]);
  });

  testWidgets('BoardHomeScreen syncs reminders when loaded items change', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = _FakeBoardRepository(items: const []);
    final scheduler = _RecordingReminderScheduler();
    final client = _testSupabaseClient();

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

    repository.items = [
      BoardItem(
        id: 'schedule-1',
        type: BoardItemType.schedule,
        title: 'Family dinner',
        detail: '',
        owner: 'Us',
        timeLabel: 'Later',
        startsAt: now.add(const Duration(hours: 2)),
      ),
    ];

    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    final expected = buildReminderPlan(
      items: repository.items,
      currentUserId: client.auth.currentUser?.id,
      now: DateTime.now(),
    );
    expect(scheduler.syncCalls.last, hasLength(expected.length));
  });

  testWidgets(
    'BoardHomeScreen reminder toggle cancels and re-syncs reminders',
    (tester) async {
      final repository = _FakeBoardRepository(
        items: [
          BoardItem(
            id: 'schedule-1',
            type: BoardItemType.schedule,
            title: 'Family dinner',
            detail: '',
            owner: 'Us',
            timeLabel: 'Later',
            startsAt: DateTime.now().add(const Duration(hours: 2)),
          ),
        ],
      );
      final scheduler = _RecordingReminderScheduler();

      await tester.pumpWidget(
        MaterialApp(
          home: BoardHomeScreen(
            client: _testSupabaseClient(),
            repository: repository,
            scheduler: scheduler,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scheduler.syncCalls.last, isNotEmpty);

      await tester.tap(find.bySemanticsLabel('\uC124\uC815'));
      await tester.pumpAndSettle();
      expect(find.text('\uC54C\uB9BC'), findsOneWidget);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(scheduler.syncCalls.last, isEmpty);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(scheduler.syncCalls.last, isNotEmpty);
    },
  );

  testWidgets('Empty board item section renders an EmptyState message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardItemSection(
            title: '\uD560 \uC77C',
            items: const [],
            accentColor: Colors.orange,
            accentSoftColor: Colors.orangeAccent,
            icon: Icons.check_rounded,
            emptyText: '\uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.',
          ),
        ),
      ),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.text('\uB0A8\uC740 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.'),
      findsOneWidget,
    );
  });

  testWidgets('Today tab shows overdue tasks and unconfirmed notices', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'overdue-task',
              type: BoardItemType.task,
              title: 'Overdue task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Yesterday',
              dueAt: now.subtract(const Duration(days: 1)),
            ),
            const BoardItem(
              id: 'required-notice',
              type: BoardItemType.notice,
              title: 'Required notice',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
            ),
            BoardItem(
              id: 'future-task',
              type: BoardItemType.task,
              title: 'Future task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Tomorrow',
              dueAt: now.add(const Duration(days: 1)),
            ),
          ],
        ),
      ),
    );

    expect(find.text('\uB193\uCE58\uBA74 \uC548 \uB3FC\uC694'), findsOneWidget);
    expect(find.text('Overdue task'), findsOneWidget);
    expect(find.text('Required notice'), findsWidgets);
    expect(find.text('Future task'), findsNothing);
  });

  testWidgets('Attention block lets overdue tasks be completed', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);
    BoardItem? completedItem;
    bool? completedIsDone;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'overdue-task',
              type: BoardItemType.task,
              title: 'Overdue task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Yesterday',
              dueAt: now.subtract(const Duration(days: 1)),
            ),
            const BoardItem(
              id: 'required-notice',
              type: BoardItemType.notice,
              title: 'Required notice',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
            ),
          ],
          onCompleteTask: (item, isDone) async {
            completedItem = item;
            completedIsDone = isDone;
          },
        ),
      ),
    );

    expect(find.text('\uB193\uCE58\uBA74 \uC548 \uB3FC\uC694'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.radio_button_unchecked_rounded));
    await tester.pump();

    expect(completedItem?.id, 'overdue-task');
    expect(completedIsDone, isTrue);
  });

  testWidgets('Today tab hides attention block when nothing needs attention', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'future-task',
              type: BoardItemType.task,
              title: 'Future task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Tomorrow',
              dueAt: now.add(const Duration(days: 1)),
            ),
            const BoardItem(
              id: 'confirmed-notice',
              type: BoardItemType.notice,
              title: 'Confirmed notice',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
              isConfirmedByMe: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('\uB193\uCE58\uBA74 \uC548 \uB3FC\uC694'), findsNothing);
  });

  testWidgets('Search shows matching title in a flat result section', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBoardScreen(
          items: [
            BoardItem(
              id: 'matching-task',
              type: BoardItemType.task,
              title: 'Alpha grocery run',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
            ),
            BoardItem(
              id: 'hidden-task',
              type: BoardItemType.task,
              title: 'Beta cleanup',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byTooltip('\uAC80\uC0C9'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '\uAC80\uC0C9'),
      'Alpha',
    );
    await tester.pumpAndSettle();

    expect(find.text('\uAC80\uC0C9 \uACB0\uACFC'), findsOneWidget);
    expect(find.text('Alpha grocery run'), findsOneWidget);
    expect(find.text('Beta cleanup'), findsNothing);
  });

  testWidgets(
    'Tapping a tag filters the current tab and clearing restores it',
    (tester) async {
      final now = DateTime(2026, 6, 2, 12);

      await tester.pumpWidget(
        MaterialApp(
          home: TodayBoardScreen(
            now: () => now,
            items: [
              BoardItem(
                id: 'school-task',
                type: BoardItemType.task,
                title: 'Pack homework',
                detail: '',
                owner: 'Us',
                timeLabel: 'Today',
                dueAt: DateTime(now.year, now.month, now.day, 18),
                tags: const ['School'],
              ),
              BoardItem(
                id: 'home-task',
                type: BoardItemType.task,
                title: 'Fold laundry',
                detail: '',
                owner: 'Us',
                timeLabel: 'Today',
                dueAt: DateTime(now.year, now.month, now.day, 19),
                tags: const ['Home'],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Pack homework'), findsOneWidget);
      expect(find.text('Fold laundry'), findsOneWidget);

      await tester.tap(find.text('#School'));
      await tester.pumpAndSettle();

      expect(find.text('Pack homework'), findsOneWidget);
      expect(find.text('Fold laundry'), findsNothing);
      expect(find.text('#School'), findsWidgets);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Pack homework'), findsOneWidget);
      expect(find.text('Fold laundry'), findsOneWidget);
    },
  );

  testWidgets('Members tab shows invite code and copy action for admins', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          selectedTab: BoardTab.members,
          onTabSelected: (_) {},
          board: const BoardSummary(
            id: 'board-1',
            name: 'Home',
            role: 'admin',
            maxMembers: 4,
            memberCount: 1,
          ),
          activeInvite: BoardInvite(
            id: 'invite-1',
            code: 'URIP-2026',
            expiresAt: DateTime(2026, 6, 8, 18),
          ),
        ),
      ),
    );

    expect(find.text('URIP-2026'), findsOneWidget);
    expect(find.text('\uBCF5\uC0AC'), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });

  testWidgets('Calendar tab shows schedules for the selected day', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);
    final otherDay = now.weekday == DateTime.sunday
        ? now.subtract(const Duration(days: 1))
        : now.add(const Duration(days: 1));

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'today-schedule',
              type: BoardItemType.schedule,
              title: 'Today schedule',
              detail: '',
              owner: 'Us',
              timeLabel: '09:00',
              startsAt: DateTime(now.year, now.month, now.day, 9),
            ),
            BoardItem(
              id: 'other-day-schedule',
              type: BoardItemType.schedule,
              title: 'Other day schedule',
              detail: '',
              owner: 'Us',
              timeLabel: '09:00',
              startsAt: DateTime(
                otherDay.year,
                otherDay.month,
                otherDay.day,
                9,
              ),
            ),
            BoardItem(
              id: 'today-task',
              type: BoardItemType.task,
              title: 'Today task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
              dueAt: DateTime(now.year, now.month, now.day, 18),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('\uC77C\uC815').last);
    await tester.pumpAndSettle();

    expect(find.text('Today schedule'), findsOneWidget);
    expect(find.text('Other day schedule'), findsNothing);
    expect(find.text('Today task'), findsNothing);

    await tester.tap(
      find.byKey(
        ValueKey(
          'calendar-day-${otherDay.year}-${otherDay.month}-${otherDay.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today schedule'), findsNothing);
    expect(find.text('Other day schedule'), findsOneWidget);
    expect(find.text('Today task'), findsNothing);
  });

  testWidgets('Calendar tab marks today once in the week strip', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: const [],
          selectedTab: BoardTab.calendar,
          onTabSelected: _ignoreBoardTab,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('calendar-today-dot')), findsOneWidget);
  });

  testWidgets('Tasks tab filters open, mine, and done tasks', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBoardScreen(
          currentUserId: 'user-1',
          items: [
            BoardItem(
              id: 'open-unassigned',
              type: BoardItemType.task,
              title: 'Open unassigned task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
            ),
            BoardItem(
              id: 'open-mine',
              type: BoardItemType.task,
              title: 'Open mine task',
              detail: '',
              owner: 'Us',
              assignedToId: 'user-1',
              timeLabel: 'Today',
            ),
            BoardItem(
              id: 'done-mine',
              type: BoardItemType.task,
              title: 'Done mine task',
              detail: '',
              owner: 'Us',
              assignedToId: 'user-1',
              timeLabel: 'Today',
              isDone: true,
            ),
            BoardItem(
              id: 'done-other',
              type: BoardItemType.task,
              title: 'Done other task',
              detail: '',
              owner: 'Us',
              assignedToId: 'user-2',
              timeLabel: 'Today',
              isDone: true,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('\uD560 \uC77C').last);
    await tester.pumpAndSettle();

    expect(find.text('Open unassigned task'), findsOneWidget);
    expect(find.text('Open mine task'), findsOneWidget);
    expect(find.text('Done mine task'), findsNothing);
    expect(find.text('Done other task'), findsNothing);

    await tester.tap(find.text('\uB0B4 \uD560 \uC77C'));
    await tester.pumpAndSettle();

    expect(find.text('Open unassigned task'), findsNothing);
    expect(find.text('Open mine task'), findsOneWidget);
    expect(find.text('Done mine task'), findsOneWidget);
    expect(find.text('Done other task'), findsNothing);

    await tester.tap(find.text('\uC644\uB8CC').first);
    await tester.pumpAndSettle();

    expect(find.text('Open unassigned task'), findsNothing);
    expect(find.text('Open mine task'), findsNothing);
    expect(find.text('Done mine task'), findsOneWidget);
    expect(find.text('Done other task'), findsOneWidget);
  });

  testWidgets('Tasks tab flags overdue tasks', (tester) async {
    final now = DateTime(2026, 6, 2, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          selectedTab: BoardTab.tasks,
          onTabSelected: _ignoreBoardTab,
          items: [
            BoardItem(
              id: 'overdue-task',
              type: BoardItemType.task,
              title: 'Overdue task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Yesterday',
              dueAt: now.subtract(const Duration(days: 1)),
            ),
            BoardItem(
              id: 'future-task',
              type: BoardItemType.task,
              title: 'Future task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Tomorrow',
              dueAt: now.add(const Duration(days: 1)),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Overdue task'), findsOneWidget);
    expect(find.text('Future task'), findsOneWidget);
    expect(find.text('\uC9C0\uB0A8'), findsOneWidget);
  });

  testWidgets('Tasks tab empty copy follows mine and done filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBoardScreen(
          selectedTab: BoardTab.tasks,
          onTabSelected: _ignoreBoardTab,
          currentUserId: null,
          items: [
            BoardItem(
              id: 'open-unassigned',
              type: BoardItemType.task,
              title: 'Open unassigned task',
              detail: '',
              owner: 'Us',
              timeLabel: 'Today',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('\uB0B4 \uD560 \uC77C'));
    await tester.pumpAndSettle();

    expect(
      find.text('\uB0B4 \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.'),
      findsOneWidget,
    );

    await tester.tap(find.text('\uC644\uB8CC').first);
    await tester.pumpAndSettle();

    expect(
      find.text('\uC644\uB8CC\uD55C \uD560 \uC77C\uC774 \uC5C6\uC5B4\uC694.'),
      findsOneWidget,
    );
  });

  testWidgets('Notices tab puts required unconfirmed notices first', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayBoardScreen(
          selectedTab: BoardTab.notices,
          onTabSelected: _ignoreBoardTab,
          items: [
            BoardItem(
              id: 'normal-notice',
              type: BoardItemType.notice,
              title: 'Normal notice',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
            ),
            BoardItem(
              id: 'required-notice',
              type: BoardItemType.notice,
              title: 'Required notice',
              detail: '',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('\uD655\uC778 0\uBA85'), findsOneWidget);
    expect(find.byIcon(Icons.how_to_reg_rounded), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Required notice')).dy,
      lessThan(tester.getTopLeft(find.text('Normal notice')).dy),
    );
  });

  testWidgets('Add item sheet exposes date and time controls for schedules', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AddItemSheet(initialType: BoardItemType.schedule)),
      ),
    );

    expect(find.text('\uC77C\uC815 \uB0A0\uC9DC'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('showAddItemSheet forwards an initial schedule datetime', (
    tester,
  ) async {
    final initialDateTime = DateTime(2027, 3, 14, 9, 30);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showAddItemSheet(
                context,
                initialType: BoardItemType.schedule,
                initialDateTime: initialDateTime,
              ),
              child: const Text('Open sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('2027.03.14'), findsOneWidget);
  });

  testWidgets('Add item sheet exposes due date controls for tasks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AddItemSheet(initialType: BoardItemType.task)),
      ),
    );

    expect(find.text('\uB9C8\uAC10 \uB0A0\uC9DC'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('Add item sheet assigns a task to a selected member', (
    tester,
  ) async {
    BoardItemDraft? submittedDraft;
    final observer = _ResultObserver<BoardItemDraft>(
      onPopped: (result) => submittedDraft = result,
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: AddItemSheet(
            initialType: BoardItemType.task,
            members: [
              BoardMember(
                userId: 'user-1',
                displayName: 'Mina',
                avatarColor: '#647D31',
                role: 'admin',
                joinedAt: DateTime(2026, 6),
              ),
              BoardMember(
                userId: 'user-2',
                displayName: 'Joon',
                avatarColor: '#E7A14B',
                role: 'member',
                joinedAt: DateTime(2026, 6, 1),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('\uB2F4\uB2F9\uC790'), findsOneWidget);
    expect(find.text('\uB2F4\uB2F9\uC790 \uC5C6\uC74C'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Joon').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, '\uC81C\uBAA9'),
      'Buy milk',
    );
    await tester.tap(find.widgetWithText(FilledButton, '\uCD94\uAC00'));
    await tester.pumpAndSettle();

    expect(submittedDraft?.type, BoardItemType.task);
    expect(submittedDraft?.title, 'Buy milk');
    expect(submittedDraft?.assignedTo, 'user-2');
  });

  testWidgets('Add item sheet rejects a past task datetime in create mode', (
    tester,
  ) async {
    BoardItemDraft? submittedDraft;
    final observer = _ResultObserver<BoardItemDraft>(
      onPopped: (result) => submittedDraft = result,
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: AddItemSheet(
            initialType: BoardItemType.task,
            initialDateTime: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, '\uC81C\uBAA9'),
      'Past task',
    );
    await tester.tap(find.widgetWithText(FilledButton, '\uCD94\uAC00'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\uC9C0\uB09C \uC2DC\uAC04\uC740 \uC120\uD0DD\uD560 \uC218 \uC5C6\uC5B4\uC694.',
      ),
      findsOneWidget,
    );
    expect(submittedDraft, isNull);
    expect(find.byType(AddItemSheet), findsOneWidget);
  });

  testWidgets('Add item sheet submits a future task datetime in create mode', (
    tester,
  ) async {
    BoardItemDraft? submittedDraft;
    final observer = _ResultObserver<BoardItemDraft>(
      onPopped: (result) => submittedDraft = result,
    );
    final futureDateTime = DateTime.now().add(const Duration(days: 1));

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: AddItemSheet(
            initialType: BoardItemType.task,
            initialDateTime: futureDateTime,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextField, '\uC81C\uBAA9'),
      'Future task',
    );
    await tester.tap(find.widgetWithText(FilledButton, '\uCD94\uAC00'));
    await tester.pumpAndSettle();

    expect(submittedDraft?.type, BoardItemType.task);
    expect(submittedDraft?.title, 'Future task');
    expect(
      submittedDraft?.dueAt,
      DateTime(
        futureDateTime.year,
        futureDateTime.month,
        futureDateTime.day,
        futureDateTime.hour,
        futureDateTime.minute,
      ),
    );
  });

  testWidgets('Add item sheet shows an error for an empty title', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddItemSheet())),
    );

    await tester.tap(find.widgetWithText(FilledButton, '\uCD94\uAC00'));
    await tester.pumpAndSettle();

    expect(
      find.text('\uC81C\uBAA9\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.'),
      findsOneWidget,
    );
  });

  testWidgets('Add item sheet parses and previews manual tags', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddItemSheet())),
    );

    await tester.enterText(
      find.widgetWithText(TextField, '\uD0DC\uADF8'),
      'school, #Family school  verylongtagname',
    );
    await tester.pumpAndSettle();

    expect(find.text('#school'), findsOneWidget);
    expect(find.text('#Family'), findsOneWidget);
    expect(find.text('#verylongtagn'), findsOneWidget);
  });

  testWidgets('Add item sheet edit mode prefills task fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddItemSheet(
            initialItem: BoardItem(
              id: 'edit-task',
              type: BoardItemType.task,
              title: 'Update lunch order',
              detail: 'No onions',
              owner: 'Us',
              timeLabel: 'Today',
              dueAt: DateTime(2026, 6, 1, 17, 30),
              tags: const ['Kitchen', 'Family'],
            ),
          ),
        ),
      ),
    );

    final segmentedButton = tester.widget<SegmentedButton<BoardItemType>>(
      find.byType(SegmentedButton<BoardItemType>),
    );

    expect(find.text('\uD56D\uBAA9 \uC218\uC815'), findsOneWidget);
    expect(find.text('Update lunch order'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '\uC800\uC7A5'), findsOneWidget);
    expect(segmentedButton.onSelectionChanged, isNull);
  });

  testWidgets('Create board dialog shows an error for an empty name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CreateBoardDialog())),
    );

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.widgetWithText(FilledButton, '\uB9CC\uB4E4\uAE30'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '\uBCF4\uB4DC \uC774\uB984\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tapping a task opens detail sheet with completion action', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'task-detail',
              type: BoardItemType.task,
              title: 'Detailed task',
              detail: 'Bring the full memo',
              owner: 'Us',
              assigneeName: 'Mina',
              timeLabel: 'Today',
              dueAt: DateTime(now.year, now.month, now.day, 18),
              tags: ['School', 'Family'],
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Detailed task'));
    await tester.pumpAndSettle();

    expect(find.text('Bring the full memo'), findsWidgets);
    expect(find.text('\uB2F4\uB2F9: Mina'), findsOneWidget);
    expect(find.text('#School'), findsWidgets);
    expect(find.text('#Family'), findsWidgets);
    expect(find.text('\uC644\uB8CC\uD558\uAE30'), findsOneWidget);
  });

  testWidgets('Detail sheet confirms and deletes an item', (tester) async {
    var deletedItemId = '';

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [
            BoardItem(
              id: 'delete-me',
              type: BoardItemType.notice,
              title: 'Delete this notice',
              detail: 'Old note',
              owner: 'Us',
              timeLabel: 'Read',
            ),
          ],
          onDeleteItem: (item) async {
            deletedItemId = item.id;
          },
        ),
      ),
    );

    await tester.tap(find.text('Delete this notice'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '\uC0AD\uC81C'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '\uC0AD\uC81C'));
    await tester.pumpAndSettle();

    expect(deletedItemId, 'delete-me');
  });

  testWidgets('Notice detail sheet confirms required notices', (tester) async {
    BoardItem? confirmedItem;
    bool? confirmedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [
            BoardItem(
              id: 'confirm-me',
              type: BoardItemType.notice,
              title: 'Confirm this notice',
              detail: 'Please read',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
            ),
          ],
          onConfirmNotice: (item, confirmed) async {
            confirmedItem = item;
            confirmedValue = confirmed;
          },
        ),
      ),
    );

    await tester.tap(find.text('Confirm this notice').first);
    await tester.pumpAndSettle();

    expect(find.text('\uD655\uC778 0\uBA85'), findsWidgets);
    expect(find.text('\uC544\uC9C1 \uD655\uC778 \uC804'), findsWidgets);
    await tester.tap(
      find.widgetWithText(FilledButton, '\uD655\uC778\uD588\uC5B4\uC694'),
    );
    await tester.pumpAndSettle();

    expect(confirmedItem?.id, 'confirm-me');
    expect(confirmedValue, isTrue);
  });

  testWidgets('Notice detail sheet lists confirmation roster', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [
            BoardItem(
              id: 'roster-notice',
              type: BoardItemType.notice,
              title: 'Roster notice',
              detail: 'Please read',
              owner: 'Us',
              timeLabel: 'Read',
              requiresConfirmation: true,
              confirmationCount: 1,
              confirmedUserIds: ['user-1'],
            ),
          ],
          members: [
            BoardMember(
              userId: 'user-1',
              displayName: 'Mina',
              avatarColor: '#647D31',
              role: 'admin',
              joinedAt: DateTime(2026, 6),
            ),
            BoardMember(
              userId: 'user-2',
              displayName: 'Joon',
              avatarColor: '#E7A14B',
              role: 'member',
              joinedAt: DateTime(2026, 6, 1),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Roster notice').first);
    await tester.pumpAndSettle();

    expect(find.text('\uD655\uC778\uD568'), findsOneWidget);
    expect(find.text('\uBBF8\uD655\uC778'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Joon'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Mina')).dy,
      greaterThan(tester.getTopLeft(find.text('\uD655\uC778\uD568')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Mina')).dy,
      lessThan(tester.getTopLeft(find.text('\uBBF8\uD655\uC778')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Joon')).dy,
      greaterThan(tester.getTopLeft(find.text('\uBBF8\uD655\uC778')).dy),
    );
  });

  testWidgets('Tapping edit in a task detail sheet opens edit sheet', (
    tester,
  ) async {
    final now = DateTime(2026, 6, 2, 12);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: TodayBoardScreen(
          now: () => now,
          items: [
            BoardItem(
              id: 'edit-me',
              type: BoardItemType.task,
              title: 'Edit this task',
              detail: 'Existing memo',
              owner: 'Us',
              timeLabel: 'Today',
              dueAt: DateTime(now.year, now.month, now.day, 18),
            ),
          ],
          onEditItem: (item) {
            showEditItemSheet(navigatorKey.currentContext!, item);
          },
        ),
      ),
    );

    await tester.tap(find.text('Edit this task'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '\uC218\uC815'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '\uC800\uC7A5'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Edit this task'), findsOneWidget);
  });

  testWidgets('Refresh button calls the board refresh callback', (
    tester,
  ) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          onRefresh: () async {
            refreshCount += 1;
          },
        ),
      ),
    );

    await tester.tap(find.byTooltip('\uC0C8\uB85C\uACE0\uCE68'));
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });

  testWidgets('Pull to refresh calls the board refresh callback', (
    tester,
  ) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          onRefresh: () async {
            refreshCount += 1;
          },
        ),
      ),
    );

    final refreshIndicator = find.byType(RefreshIndicator);

    expect(refreshIndicator, findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(refreshCount, 1);
  });

  testWidgets('Settings button calls the open settings callback', (
    tester,
  ) async {
    var settingsOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          onOpenSettings: () => settingsOpened = true,
        ),
      ),
    );

    await tester.tap(find.byTooltip('\uC124\uC815'));
    await tester.pumpAndSettle();

    expect(settingsOpened, isTrue);
  });

  testWidgets('Board settings sheet calls sign out callback', (tester) async {
    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardSettingsSheet(
            boardName: 'Home',
            userName: 'Mina',
            onSignOut: () => signedOut = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('\uB85C\uADF8\uC544\uC6C3'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('Board settings sheet switches to another board', (tester) async {
    String? selectedBoardId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BoardSettingsSheet(
            boardName: 'Home',
            userName: 'Mina',
            boards: const [
              BoardSummary(
                id: 'board-1',
                name: 'Home',
                role: 'admin',
                maxMembers: 4,
                memberCount: 2,
              ),
              BoardSummary(
                id: 'board-2',
                name: 'Second home',
                role: 'member',
                maxMembers: 5,
                memberCount: 3,
              ),
            ],
            activeBoardId: 'board-1',
            onSelectBoard: (id) => selectedBoardId = id,
            onSignOut: () {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Second home'), findsOneWidget);

    await tester.tap(find.text('Second home'));
    await tester.pumpAndSettle();

    expect(selectedBoardId, 'board-2');
  });

  testWidgets('Profile edit sheet saves a new display name', (tester) async {
    EditProfileResult? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextButton(
            onPressed: () async {
              saved = await showEditProfileSheet(
                tester.element(find.byType(TextButton)),
                profile: const UserProfile(
                  id: 'user-1',
                  displayName: 'Mina',
                  avatarColor: '#647D31',
                ),
              );
            },
            child: const Text('Open profile'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();

    expect(find.text('Mina'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Nari');
    await tester.tap(find.widgetWithText(FilledButton, '\uC800\uC7A5'));
    await tester.pumpAndSettle();

    expect(saved?.displayName, 'Nari');
    expect(saved?.avatarColor, '#647D31');
    expect(find.text('Nari'), findsNothing);
  });

  testWidgets(
    'Board settings edit sheet shows current name and saves new one',
    (tester) async {
      EditBoardSettingsResult? saved;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await showEditBoardSettingsSheet(
                  tester.element(find.byType(TextButton)),
                  board: const BoardSummary(
                    id: 'board-1',
                    name: 'Home',
                    role: 'admin',
                    maxMembers: 4,
                    memberCount: 2,
                  ),
                );
              },
              child: const Text('Open board settings'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open board settings'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('\uBCF4\uB4DC \uC124\uC815'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'New home');
      await tester.tap(find.widgetWithText(FilledButton, '\uC800\uC7A5'));
      await tester.pumpAndSettle();

      expect(saved?.name, 'New home');
      expect(saved?.maxMembers, 4);
      expect(find.text('New home'), findsNothing);
    },
  );

  testWidgets('Members tab shows member names and roles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          selectedTab: BoardTab.members,
          onTabSelected: (_) {},
          board: const BoardSummary(
            id: 'board-1',
            name: 'Home',
            role: 'admin',
            maxMembers: 4,
            memberCount: 2,
          ),
          members: [
            BoardMember(
              userId: 'user-1',
              displayName: 'Mina',
              avatarColor: '#647D31',
              role: 'admin',
              joinedAt: DateTime(2026, 6),
            ),
            BoardMember(
              userId: 'user-2',
              displayName: 'Joon',
              avatarColor: '#E7A14B',
              role: 'member',
              joinedAt: DateTime(2026, 6, 1, 1),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('\uAD00\uB9AC\uC790'), findsOneWidget);
    expect(find.text('Joon'), findsOneWidget);
    expect(find.text('\uBA64\uBC84'), findsOneWidget);
  });

  testWidgets('Admin viewer sees per-member action menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          selectedTab: BoardTab.members,
          onTabSelected: (_) {},
          board: const BoardSummary(
            id: 'board-1',
            name: 'Home',
            role: 'admin',
            maxMembers: 4,
            memberCount: 2,
          ),
          currentUserId: 'user-1',
          members: [
            BoardMember(
              userId: 'user-1',
              displayName: 'Mina',
              avatarColor: '#647D31',
              role: 'admin',
              joinedAt: DateTime(2026, 6),
            ),
            BoardMember(
              userId: 'user-2',
              displayName: 'Joon',
              avatarColor: '#E7A14B',
              role: 'member',
              joinedAt: DateTime(2026, 6, 1, 1),
            ),
          ],
          onUpdateMemberRole: (_, _) async {},
          onRemoveMember: (_) async {},
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.text('\uAD00\uB9AC\uC790\uB85C'), findsOneWidget);
    expect(find.text('\uB0B4\uBCF4\uB0B4\uAE30'), findsOneWidget);
  });

  testWidgets('Non-admin viewer does not see per-member action menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: const [],
          selectedTab: BoardTab.members,
          onTabSelected: (_) {},
          board: const BoardSummary(
            id: 'board-1',
            name: 'Home',
            role: 'member',
            maxMembers: 4,
            memberCount: 2,
          ),
          currentUserId: 'user-1',
          members: [
            BoardMember(
              userId: 'user-1',
              displayName: 'Mina',
              avatarColor: '#647D31',
              role: 'member',
              joinedAt: DateTime(2026, 6),
            ),
            BoardMember(
              userId: 'user-2',
              displayName: 'Joon',
              avatarColor: '#E7A14B',
              role: 'admin',
              joinedAt: DateTime(2026, 6, 1, 1),
            ),
          ],
          onUpdateMemberRole: (_, _) async {},
          onRemoveMember: (_) async {},
        ),
      ),
    );

    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });
}

void _ignoreBoardTab(BoardTab tab) {}

SupabaseClient _testSupabaseClient() {
  final client = SupabaseClient('https://example.supabase.co', 'test-anon-key');
  client.auth.stopAutoRefresh();
  return client;
}

class _FakeBoardRepository extends BoardRepository {
  _FakeBoardRepository({required this.items});

  List<BoardItem> items;

  @override
  Future<List<BoardSummary>> loadBoards() async {
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
    return items;
  }
}

class _RecordingReminderScheduler implements ReminderScheduler {
  var initCount = 0;
  var permissionRequestCount = 0;
  final syncCalls = <List<ScheduledReminder>>[];

  @override
  Future<void> init() async {
    initCount += 1;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount += 1;
    return true;
  }

  @override
  Future<void> sync(List<ScheduledReminder> reminders) async {
    syncCalls.add(List<ScheduledReminder>.of(reminders));
  }
}

class _ResultObserver<T> extends NavigatorObserver {
  _ResultObserver({required this.onPopped});

  final ValueChanged<T?> onPopped;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    route.popped.then((result) {
      if (result is T) onPopped(result);
    });
    super.didPush(route, previousRoute);
  }
}
