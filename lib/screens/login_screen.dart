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
                '공유 보드에 다시 오신 것을 환영합니다',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.mutedText),
              ),
              const SizedBox(height: 32),
              const Text('이메일 주소'),
              const SizedBox(height: 8),
              AppTextField(
                label: '이메일',
                hint: '이메일을 입력하세요',
                leadingIcon: Icons.mail_outline_rounded,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              const Text('비밀번호'),
              const SizedBox(height: 8),
              AppTextField(
                label: '비밀번호',
                hint: '비밀번호를 입력하세요',
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
                  const Expanded(child: Text('로그인 상태 유지')),
                  TextButton(
                    onPressed: _showPasswordResetDialog,
                    child: const Text('비밀번호 찾기'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: '로그인',
                onPressed: _login,
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '아직 계정이 없나요?',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.mutedText),
                  ),
                  TextButton(
                    onPressed: _showSignUpDialog,
                    child: const Text('회원가입'),
                  ),
                ],
              ),
              Center(
                child: Text(
                  '로그인하면 이용약관에 동의한 것으로 간주됩니다',
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
          title: const Text('비밀번호 재설정'),
          content: const Text('비밀번호 재설정 이메일 흐름은 아직 연결되지 않았습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
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
          title: const Text('계정 만들기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: '이름'),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => email = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSignUp(name, email, keepLoggedIn);
                Navigator.pushReplacementNamed(
                    context, GroupSelectionScreen.routeName);
              },
              child: const Text('계속'),
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
        const SnackBar(content: Text('이메일과 비밀번호를 입력하세요.')),
      );
      return;
    }

    widget.onLogin(emailController.text, keepLoggedIn);
    Navigator.pushReplacementNamed(context, GroupSelectionScreen.routeName);
  }
}
