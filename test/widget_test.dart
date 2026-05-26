import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/main.dart';
import 'package:uripan/services/auth_input_validator.dart';

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

  test('auth input validation blocks empty anonymous-like signup payloads', () {
    expect(
      AuthInputValidator.validateEmailPassword('', ''),
      '\uC774\uBA54\uC77C\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateEmailPassword('family@example.com', ''),
      '\uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateEmailPassword('family@example.com', '12345'),
      '\uBE44\uBC00\uBC88\uD638\uB294 6\uC790 \uC774\uC0C1\uC73C\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.',
    );
    expect(
      AuthInputValidator.validateEmailPassword(
        'family@example.com',
        '123456',
      ),
      isNull,
    );
  });
}
