import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/services/friendly_date.dart';

void main() {
  test(
    'friendlyRelativeTime labels future times as just now for clock skew',
    () {
      final now = DateTime(2026, 6, 2, 15, 30);

      expect(
        friendlyRelativeTime(DateTime(2026, 6, 2, 15, 30, 45), now: now),
        '\uBC29\uAE08',
      );
    },
  );
}
