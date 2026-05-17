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
              'Shared board for your team',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Text(
              'A simple shared board for schedules, tasks, and notices. Keep your group in sync effortlessly.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Row(
              children: [
                FeatureCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Schedules',
                  color: AppColors.info,
                  background: AppColors.infoSoft,
                ),
                SizedBox(width: 10),
                FeatureCard(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Tasks',
                  color: AppColors.success,
                  background: AppColors.successSoft,
                ),
                SizedBox(width: 10),
                FeatureCard(
                  icon: Icons.notifications_active_rounded,
                  label: 'Notices',
                  color: AppColors.warning,
                  background: AppColors.warningSoft,
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Login',
              onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Sign Up',
              variant: ButtonVariant.outline,
              onPressed: () => Navigator.pushNamed(context, LoginScreen.routeName),
            ),
            const SizedBox(height: 16),
            Text(
              'By continuing, you agree to our Terms',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
