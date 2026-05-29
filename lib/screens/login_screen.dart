import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_error_messages.dart';
import '../services/auth_input_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_validateUserIdPassword()) return;

    await _runAuthAction(() async {
      await widget.client.auth.signInWithPassword(
        email: AuthInputValidator.syntheticEmailForUserId(
          _userIdController.text,
        ),
        password: _passwordController.text,
      );
    }, successMessage: null);
  }

  Future<void> _signUp() async {
    if (!_validateUserIdPassword()) return;

    await _runAuthAction(
      () async {
        final userId = AuthInputValidator.normalizeUserId(
          _userIdController.text,
        );
        await widget.client.auth.signUp(
          email: AuthInputValidator.syntheticEmailForUserId(userId),
          password: _passwordController.text,
          data: {'display_name': userId},
        );
      },
      successMessage:
          '\uCC98\uC74C \uC0AC\uC6A9 \uC900\uBE44\uAC00 \uB05D\uB0AC\uC5B4\uC694. \uB85C\uADF8\uC778\uD574\uC8FC\uC138\uC694.',
    );
  }

  Future<void> _runAuthAction(
    Future<void> Function() action, {
    required String? successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) {
        setState(() => _message = successMessage);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _message = _friendlyAuthError(error));
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyAuthError(AuthException error) {
    return AuthErrorMessages.fromAuthMessage(error.message);
  }

  bool _validateUserIdPassword() {
    final message = AuthInputValidator.validateUserIdPassword(
      _userIdController.text,
      _passwordController.text,
    );
    if (message == null) return true;
    setState(() => _message = message);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UriPan', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                '\uAC00\uC871\uC774 \uD568\uAED8 \uBCF4\uB294 \uC624\uB298 \uBCF4\uB4DC',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _userIdController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: '\uC544\uC774\uB514',
                  helperText:
                      '\uC601\uBB38, \uC22B\uC790, -, _ 3\uC790 \uC774\uC0C1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '\uBE44\uBC00\uBC88\uD638',
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: const Text('\uB85C\uADF8\uC778'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _isLoading ? null : _signUp,
                child: const Text('\uCC98\uC74C \uC0AC\uC6A9\uD558\uAE30'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
