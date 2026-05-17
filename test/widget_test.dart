import 'package:flutter_test/flutter_test.dart';

import 'package:uripan/main.dart';

void main() {
  testWidgets('UriPan welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const UriPanApp());

    expect(find.text('UriPan'), findsOneWidget);
    expect(find.text('Shared board for your team'), findsOneWidget);
  });
}
