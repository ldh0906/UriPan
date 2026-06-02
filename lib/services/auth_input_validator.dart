class AuthInputValidator {
  const AuthInputValidator._();

  static const _syntheticEmailDomain = String.fromEnvironment(
    'AUTH_EMAIL_DOMAIN',
    defaultValue: 'auth.uripan.app',
  );

  static String normalizeUserId(String userId) {
    return userId.trim().toLowerCase();
  }

  static String syntheticEmailForUserId(String userId) {
    return '${normalizeUserId(userId)}@$_syntheticEmailDomain';
  }

  static String? validateUserId(String userId) {
    final trimmed = normalizeUserId(userId);
    if (trimmed.isEmpty) {
      return '\uC544\uC774\uB514\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }

    if (trimmed.length < 3) {
      return '\uC544\uC774\uB514\uB294 3\uC790 \uC774\uC0C1\uC73C\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }

    if (trimmed.length > 24) {
      return '\uC544\uC774\uB514\uB294 24\uC790 \uC774\uD558\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }

    final userIdPattern = RegExp(r'^[a-z0-9_-]+$');
    if (!userIdPattern.hasMatch(trimmed)) {
      return '\uC544\uC774\uB514\uB294 \uC601\uBB38, \uC22B\uC790, -, _\uB9CC \uC0AC\uC6A9\uD560 \uC218 \uC788\uC5B4\uC694.';
    }

    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return '\uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }

    if (password.length < 6) {
      return '\uBE44\uBC00\uBC88\uD638\uB294 6\uC790 \uC774\uC0C1\uC73C\uB85C \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }

    return null;
  }

  static String? validateUserIdPassword(String userId, String password) {
    return validateUserId(userId) ?? validatePassword(password);
  }
}
