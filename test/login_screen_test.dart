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

  testWidgets('signup persists keep-signed-in and shows signed-in success', (
    tester,
  ) async {
    final preferences = _RecordingSessionPreferences();
    final signupClient = _SignupSupabaseClient();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          client: signupClient,
          sessionPreferences: preferences,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'family01');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(
      find.widgetWithText(
        OutlinedButton,
        '\uCC98\uC74C \uC0AC\uC6A9\uD558\uAE30',
      ),
    );
    await tester.pumpAndSettle();

    expect(await preferences.loadKeepSignedIn(), isFalse);
    expect(preferences.savedValues, [false]);
    expect(
      find.text(
        '\uCC98\uC74C \uC0AC\uC6A9 \uC900\uBE44\uAC00 \uB05D\uB0AC\uC5B4\uC694. \uB85C\uADF8\uC778\uD574\uC8FC\uC138\uC694.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        '\uCC98\uC74C \uC0AC\uC6A9 \uC900\uBE44\uAC00 \uB05D\uB0AC\uC5B4\uC694.',
      ),
      findsOneWidget,
    );
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

class _SignupSupabaseClient extends SupabaseClient {
  _SignupSupabaseClient()
    : _auth = _SignupAuthClient(),
      super(
        'https://stub.supabase.co',
        'stub-anon-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

class _SignupAuthClient extends GoTrueClient {
  _SignupAuthClient() : super(autoRefreshToken: false);

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    return AuthResponse(
      user: const User(
        id: 'user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        email: 'family01@auth.uripan.app',
        createdAt: '2026-06-10T00:00:00Z',
        identities: [
          UserIdentity(
            id: 'identity-1',
            userId: 'user-1',
            identityData: {},
            identityId: 'identity-1',
            provider: 'email',
            createdAt: '2026-06-10T00:00:00Z',
            lastSignInAt: '2026-06-10T00:00:00Z',
          ),
        ],
      ),
    );
  }
}

class _RecordingSessionPreferences extends SessionPreferences {
  final savedValues = <bool>[];
  bool _keepSignedIn = false;

  @override
  Future<bool> loadKeepSignedIn() async => _keepSignedIn;

  @override
  Future<void> saveKeepSignedIn(bool keepSignedIn) async {
    savedValues.add(keepSignedIn);
    _keepSignedIn = keepSignedIn;
  }
}
