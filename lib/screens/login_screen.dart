import 'package:flutter/material.dart';

import '../models/mock_models.dart';
import '../screens/group_selection_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.user,
    required this.onLogin,
    required this.onSignUp,
  });

  static const routeName = '/login';

  final UserProfile user;
  final void Function(String email, bool keepLoggedIn) onLogin;
  final void Function(String name, String email, bool keepLoggedIn) onSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late bool keepLoggedIn = widget.user.keepLoggedIn;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.user.email);
    passwordController = TextEditingController(text: 'uripan-demo');
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: SingleChildScrollView(
        child: PagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 28),
              const AppLogoMark(size: 66),
              const SizedBox(height: 22),
              Text('UriPan', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Welcome back to your shared board',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 32),
              const Text('Email Address'),
              const SizedBox(height: 8),
              AppTextField(
                label: 'Email',
                hint: 'Enter your email',
                leadingIcon: Icons.mail_outline_rounded,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              const Text('Password'),
              const SizedBox(height: 8),
              AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                leadingIcon: Icons.lock_outline_rounded,
                trailingIcon: Icons.visibility_off_rounded,
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: keepLoggedIn,
                    activeColor: AppColors.primary,
                    onChanged: (value) =>
                        setState(() => keepLoggedIn = value ?? false),
                  ),
                  const Expanded(child: Text('Keep me logged in')),
                  TextButton(
                    onPressed: _showPasswordResetDialog,
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Login',
                onPressed: _login,
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  TextButton(
                    onPressed: _showSignUpDialog,
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              Center(
                child: Text(
                  'By logging in, you agree to our Terms of Service',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content:
              const Text('Password reset email flow is not connected yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showSignUpDialog() {
    var name = widget.user.name;
    var email = emailController.text;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSignUp(name, email, keepLoggedIn);
                Navigator.pushReplacementNamed(
                    context, GroupSelectionScreen.routeName);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _login() {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }

    widget.onLogin(emailController.text, keepLoggedIn);
    Navigator.pushReplacementNamed(context, GroupSelectionScreen.routeName);
  }
}
