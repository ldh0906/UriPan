import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/main.dart';
import 'package:uripan/services/auth_error_messages.dart';
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
}
