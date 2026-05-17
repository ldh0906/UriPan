import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      child: PagePadding(
        child: Column(
          children: [
            const Spacer(),
            const AppLogoMark(size: 84),
            const SizedBox(height: 24),
            Text(
              'UriPan',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '우리끼리 함께 쓰는 공유 보드',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Text(
              '일정, 할 일, 공지를 한곳에 모아 우리 모임의 흐름을 쉽게 맞춰보세요.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                FeatureCard(
                  icon: Icons.calendar_today_rounded,
                  label: '일정',
                  color: AppColors.info,
                  background: AppColors.infoSoft,
                ),
                SizedBox(width: 10),
                FeatureCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: '할 일',
                  color: AppColors.success,
                  background: AppColors.successSoft,
                ),
                SizedBox(width: 10),
                FeatureCard(
                  icon: Icons.notifications_active_rounded,
                  label: '공지',
                  color: AppColors.warning,
                  background: AppColors.warningSoft,
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              label: '로그인',
              onPressed: () =>
                  Navigator.pushNamed(context, LoginScreen.routeName),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: '회원가입',
              variant: ButtonVariant.outline,
              onPressed: () =>
                  Navigator.pushNamed(context, LoginScreen.routeName),
            ),
            const SizedBox(height: 16),
            Text(
              '계속하면 이용약관에 동의한 것으로 간주됩니다',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
