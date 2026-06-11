import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_error_messages.dart';
import '../services/auth_input_validator.dart';
import '../services/session_preferences.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.client, this.sessionPreferences});

  final SupabaseClient client;
  final SessionPreferences? sessionPreferences;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  late final SessionPreferences _sessionPreferences =
      widget.sessionPreferences ?? SessionPreferences();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _keepSignedIn = true;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadKeepSignedIn();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadKeepSignedIn() async {
    try {
      final keepSignedIn = await _sessionPreferences.loadKeepSignedIn();
      if (!mounted) return;
      setState(() => _keepSignedIn = keepSignedIn);
    } catch (_) {}
  }

  Future<void> _setKeepSignedIn(bool keepSignedIn) async {
    setState(() => _keepSignedIn = keepSignedIn);
    try {
      await _sessionPreferences.saveKeepSignedIn(keepSignedIn);
    } catch (_) {}
  }

  Future<void> _signIn() async {
    if (!_validateUserIdPassword()) return;

    await _setKeepSignedIn(_keepSignedIn);
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

    await _setKeepSignedIn(_keepSignedIn);
    await _runAuthAction(
      () async {
        final userId = AuthInputValidator.normalizeUserId(
          _userIdController.text,
        );
        final response = await widget.client.auth.signUp(
          email: AuthInputValidator.syntheticEmailForUserId(userId),
          password: _passwordController.text,
          data: {'display_name': userId},
        );
        // Email confirmation is off, so a real new signup comes back with a
        // populated identities list. An id that already exists comes back
        // with an empty identities list (Supabase hides that the account
        // exists). Surface it instead of pretending the signup worked.
        if (response.user?.identities?.isEmpty ?? false) {
          throw AuthException('user_already_registered');
        }
      },
      successMessage:
          '\uCC98\uC74C \uC0AC\uC6A9 \uC900\uBE44\uAC00 \uB05D\uB0AC\uC5B4\uC694.',
    );
  }

  Future<void> _runAuthAction(
    Future<void> Function() action, {
    required String? successMessage,
  }) async {
    setState(() {
      _isLoading = true;
      _message = null;
      _isError = false;
    });

    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) {
        setState(() {
          _message = successMessage;
          _isError = false;
        });
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _message = _friendlyAuthError(error);
        _isError = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _isError = true;
      });
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
    setState(() {
      _message = message;
      _isError = true;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandMark(),
                  const SizedBox(height: 22),
                  Center(
                    child: Text('UriPan', style: theme.textTheme.headlineLarge),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '\uAC00\uC871\uC774 \uD568\uAED8 \uBCF4\uB294 \uC624\uB298 \uBCF4\uB4DC',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _LoginCard(
                    userIdController: _userIdController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onToggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    keepSignedIn: _keepSignedIn,
                    onKeepSignedInChanged: _isLoading ? null : _setKeepSignedIn,
                    isLoading: _isLoading,
                    onSignIn: _signIn,
                    onSubmitPassword: _signIn,
                    message: _message,
                    isError: _isError,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(56, 52),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('\uCC98\uC74C \uC0AC\uC6A9\uD558\uAE30'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.cottage_rounded, color: Colors.white, size: 36),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.userIdController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.keepSignedIn,
    required this.onKeepSignedInChanged,
    required this.isLoading,
    required this.onSignIn,
    required this.onSubmitPassword,
    required this.message,
    required this.isError,
  });

  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool keepSignedIn;
  final ValueChanged<bool>? onKeepSignedInChanged;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSubmitPassword;
  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: userIdController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: '\uC544\uC774\uB514',
              prefixIcon: Icon(Icons.person_outline_rounded),
              helperText:
                  '\uC601\uBB38, \uC22B\uC790, -, _ 3\uC790 \uC774\uC0C1',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmitPassword(),
            decoration: InputDecoration(
              labelText: '\uBE44\uBC00\uBC88\uD638',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: obscurePassword
                    ? '\uBE44\uBC00\uBC88\uD638 \uD45C\uC2DC'
                    : '\uBE44\uBC00\uBC88\uD638 \uC228\uAE30\uAE30',
              ),
            ),
          ),
          const SizedBox(height: 6),
          _KeepSignedInRow(
            value: keepSignedIn,
            onChanged: onKeepSignedInChanged,
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isError ? AppColors.dangerSoft : AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isError ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isError ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: isLoading ? null : onSignIn,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('\uB85C\uADF8\uC778'),
          ),
        ],
      ),
    );
  }
}

class _KeepSignedInRow extends StatelessWidget {
  const _KeepSignedInRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (next) => onChanged!(next ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '\uB85C\uADF8\uC778 \uC0C1\uD0DC \uC720\uC9C0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
