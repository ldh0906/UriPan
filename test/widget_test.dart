import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/main.dart';

void main() {
  testWidgets('UriPan shows the Today board sections', (tester) async {
    await tester.pumpWidget(const UriPanApp());
    await tester.pumpAndSettle();

    expect(find.text('UriPan'), findsOneWidget);
    expect(find.text('오늘 보드'), findsOneWidget);
    expect(find.text('일정'), findsOneWidget);
    expect(find.text('할 일'), findsOneWidget);
    expect(find.text('공지'), findsOneWidget);
  });
}
