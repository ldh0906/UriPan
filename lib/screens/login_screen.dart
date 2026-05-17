import 'package:flutter/material.dart';

import '../screens/group_selection_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool keepLoggedIn = true;

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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 32),
              const Text('Email Address'),
              const SizedBox(height: 8),
              const AppTextField(
                label: 'Email',
                hint: 'Enter your email',
                leadingIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 16),
              const Text('Password'),
              const SizedBox(height: 8),
              const AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                leadingIcon: Icons.lock_outline_rounded,
                trailingIcon: Icons.visibility_off_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: keepLoggedIn,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setState(() => keepLoggedIn = value ?? false),
                  ),
                  const Expanded(child: Text('Keep me logged in')),
                  TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Login',
                onPressed: () => Navigator.pushReplacementNamed(context, GroupSelectionScreen.routeName),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.mutedText),
                  ),
                  TextButton(onPressed: () {}, child: const Text('Sign Up')),
                ],
              ),
              Center(
                child: Text(
                  'By logging in, you agree to our Terms of Service',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
