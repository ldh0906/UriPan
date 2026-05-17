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
    expect(find.text('우리끼리 함께 쓰는 공유 보드'), findsOneWidget);
  });

  testWidgets('new task can be created from the add flow', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('로그인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('우리 집'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('항목 추가'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('할 일'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      '부엌 창문 닦기',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('할 일'), findsWidgets);
    expect(find.text('부엌 창문 닦기'), findsOneWidget);
  });

  testWidgets('board can be created locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('로그인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('만들기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '여행 모임');
    await tester.tap(find.text('만들기').last);
    await tester.pumpAndSettle();

    expect(find.text('여행 모임'), findsOneWidget);
  });

  testWidgets('member role can be changed locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('로그인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('우리 집'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('멤버'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('역할 변경'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('읽기 전용'));
    await tester.pumpAndSettle();

    expect(find.text('김서윤'), findsOneWidget);
    expect(find.text('읽기 전용'), findsOneWidget);
  });

  testWidgets('existing task can be edited locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('로그인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('우리 집'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('설거지하기'));
    await tester.pumpAndSettle();

    expect(find.text('수정 할 일'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '설거지와 냄비 정리');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('설거지와 냄비 정리'), findsOneWidget);
    expect(find.text('설거지하기'), findsNothing);
  });

  testWidgets('active board can be left locally', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('로그인').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('우리 집'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('멤버'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('보드 나가기'));
    await tester.tap(find.text('보드 나가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();

    expect(find.text('내 보드'), findsOneWidget);
    expect(find.text('알고리즘 스터디'), findsOneWidget);
  });
}
