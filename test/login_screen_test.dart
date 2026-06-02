import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uripan/screens/login_screen.dart';
import 'package:uripan/services/session_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = SupabaseClient('https://stub.supabase.co', 'stub-anon-key');
  });

  Future<SessionPreferences> sessionPreferences() async {
    return SessionPreferences(
      preferences: await SharedPreferences.getInstance(),
    );
  }

  testWidgets('renders login form with keep-signed-in checked by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          client: client,
          sessionPreferences: await sessionPreferences(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FilledButton, '\uB85C\uADF8\uC778'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(
        OutlinedButton,
        '\uCC98\uC74C \uC0AC\uC6A9\uD558\uAE30',
      ),
      findsOneWidget,
    );
    expect(
      find.text('\uB85C\uADF8\uC778 \uC0C1\uD0DC \uC720\uC9C0'),
      findsOneWidget,
    );

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('toggling keep-signed-in persists the preference', (
    tester,
  ) async {
    final preferences = await sessionPreferences();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(client: client, sessionPreferences: preferences),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('\uB85C\uADF8\uC778 \uC0C1\uD0DC \uC720\uC9C0'));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
    expect(await preferences.loadKeepSignedIn(), isFalse);
  });

  testWidgets('password visibility toggle reveals the field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          client: client,
          sessionPreferences: await sessionPreferences(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
