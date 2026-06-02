class AuthErrorMessages {
  const AuthErrorMessages._();

  static String fromAuthMessage(String rawMessage) {
    final message = rawMessage.toLowerCase();

    if (message.contains('email rate limit') ||
        message.contains('over_email_send_rate_limit')) {
      return '\uAC00\uC785 \uC694\uCCAD\uC774 \uB9CE\uC544\uC694. \uC7A0\uC2DC \uD6C4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('email address') && message.contains('invalid')) {
      return '\uC544\uC774\uB514\uB97C \uD655\uC778\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('anonymous') || message.contains('provider')) {
      return '\uC544\uC774\uB514\uC640 \uBE44\uBC00\uBC88\uD638\uB85C \uB85C\uADF8\uC778\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('invalid login credentials')) {
      return '\uC544\uC774\uB514 \uB610\uB294 \uBE44\uBC00\uBC88\uD638\uB97C \uD655\uC778\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('email') && message.contains('confirm')) {
      return '\uAD00\uB9AC\uC790\uAC00 Supabase \uC774\uBA54\uC77C \uD655\uC778 \uC124\uC815\uC744 \uB044\uACE0 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('rate') || message.contains('too many')) {
      return '\uC694\uCCAD\uC774 \uB9CE\uC544\uC694. \uC7A0\uC2DC \uD6C4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.';
    }
    if (message.contains('password')) {
      return '\uBE44\uBC00\uBC88\uD638\uB97C \uD655\uC778\uD574\uC8FC\uC138\uC694.';
    }

    return '\uB85C\uADF8\uC778 \uCC98\uB9AC \uC911 \uBB38\uC81C\uAC00 \uC0DD\uACBC\uC5B4\uC694. \uC7A0\uC2DC \uD6C4 \uB2E4\uC2DC \uC2DC\uB3C4\uD574\uC8FC\uC138\uC694.';
  }
}
