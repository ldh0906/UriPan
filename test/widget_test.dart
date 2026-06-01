import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/main.dart';
import 'package:uripan/models/board_item.dart';
import 'package:uripan/screens/today_board_screen.dart';
import 'package:uripan/services/auth_error_messages.dart';
import 'package:uripan/services/auth_input_validator.dart';
import 'package:uripan/widgets/board_action_sheets.dart';

void main() {
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
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
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

  testWidgets(
    'Calendar tab shows all schedules and excludes other item types',
    (tester) async {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: TodayBoardScreen(
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

      await tester.tap(find.text('\uC77C\uC815').last);
      await tester.pumpAndSettle();

      expect(find.text('Today schedule'), findsOneWidget);
      expect(find.text('Future schedule'), findsOneWidget);
      expect(find.text('Today task'), findsNothing);
    },
  );

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
    final now = DateTime.now();

    await tester.pumpWidget(
      MaterialApp(
        home: TodayBoardScreen(
          items: [
            BoardItem(
              id: 'task-detail',
              type: BoardItemType.task,
              title: 'Detailed task',
              detail: 'Bring the full memo',
              owner: 'Us',
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

    await tester.tap(find.text('Confirm this notice'));
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
}
