import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uripan/main.dart';
import 'package:uripan/services/app_repository.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(UriPanApp(repository: MemoryAppRepository()));
    await tester.pumpAndSettle();
  }

  testWidgets('UriPan welcome screen renders', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('UriPan'), findsOneWidget);
    expect(find.text('Shared board for your team'), findsOneWidget);
  });

  testWidgets('new task can be created from the add flow', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sweet Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Clean kitchen windows',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Clean kitchen windows'), findsOneWidget);
  });

  testWidgets('board can be created locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Trip Crew');
    await tester.tap(find.text('Create').last);
    await tester.pumpAndSettle();

    expect(find.text('Trip Crew'), findsOneWidget);
  });

  testWidgets('member role can be changed locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sweet Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change role'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viewer'));
    await tester.pumpAndSettle();

    expect(find.text('Seoyun Kim'), findsOneWidget);
    expect(find.text('Viewer'), findsOneWidget);
  });


  testWidgets('existing task can be edited locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sweet Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wash the dishes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Task'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Wash dishes and pans');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Wash dishes and pans'), findsOneWidget);
    expect(find.text('Wash the dishes'), findsNothing);
  });

  testWidgets('active board can be left locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sweet Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Leave Board'));
    await tester.tap(find.text('Leave Board'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Your Boards'), findsOneWidget);
    expect(find.text('Algorithms Study'), findsOneWidget);
  });
}
