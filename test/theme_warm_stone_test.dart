import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uripan/theme/app_theme.dart';
import 'package:uripan/widgets/board_item_card.dart';
import 'package:uripan/widgets/common_widgets.dart';

void main() {
  test('AppTheme uses Warm Stone colors and Pretendard typography', () {
    final theme = AppTheme.light();

    expect(AppColors.background, const Color(0xFFF8F6F3));
    expect(AppColors.primary, const Color(0xFF3B82C4));
    expect(AppColors.secondary, const Color(0xFF6D9B8A));
    expect(AppColors.tertiary, const Color(0xFFB85C00));
    expect(AppColors.primarySoft, const Color(0xFFE8F0FA));

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.textTheme.headlineSmall?.fontFamily, 'Pretendard');
    expect(theme.textTheme.headlineSmall?.fontSize, 24);
    expect(theme.textTheme.headlineSmall?.fontWeight, FontWeight.w800);
    expect(theme.textTheme.headlineSmall?.height, 1.3);
    expect(theme.textTheme.bodyLarge?.fontSize, 17);
    expect(theme.textTheme.bodyLarge?.height, 1.6);
  });

  testWidgets('SoftCard uses the subtle Warm Stone card treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const SoftCard(child: Text('card')),
      ),
    );

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(SoftCard),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final shadow = decoration.boxShadow!.single;

    expect(decoration.borderRadius, BorderRadius.circular(18));
    expect(shadow.color, Colors.black.withValues(alpha: 0.05));
    expect(shadow.blurRadius, 10);
    expect(shadow.offset, const Offset(0, 2));
  });

  testWidgets('AddItemFab and TagChip use rounded rectangle shapes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Column(
          children: [
            AddItemFab(),
            TagChip(label: 'family'),
          ],
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final shape = button.style!.shape!.resolve(<WidgetState>{})!;
    expect(shape, isA<RoundedRectangleBorder>());
    expect(
      (shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(14),
    );

    final tagContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(TagChip),
        matching: find.byType(Container),
      ),
    );
    final tagDecoration = tagContainer.decoration! as BoxDecoration;
    expect(tagDecoration.borderRadius, BorderRadius.circular(8));
    expect(tagDecoration.border, isA<Border>());
    expect(
      tester.widget<Text>(find.text('#family')).style?.color,
      const Color(0xFF1A5FA8),
    );
  });
}
