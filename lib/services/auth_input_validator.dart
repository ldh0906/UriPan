class AuthInputValidator {
  const AuthInputValidator._();

  static String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return '\uC774\uBA54\uC77C\uC744 \uC785\uB825\uD574\uC8FC\uC138\uC694.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return '\uC774\uBA54\uC77C \uD615\uC2DD\uC744 \uD655\uC778\uD574\uC8FC\uC138\uC694.';
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

  static String? validateEmailPassword(String email, String password) {
    return validateEmail(email) ?? validatePassword(password);
  }
}
