import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/main.dart';

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
}
