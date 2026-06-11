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
    final shadows = decoration.boxShadow!;

    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.lg));
    expect(decoration.color, isNull);
    expect(shadows, AppShadows.card);

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(SoftCard),
        matching: find.byType(Material),
      ),
    );
    expect(material.color, AppColors.surface);
    expect(material.clipBehavior, Clip.antiAlias);

    final inkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(SoftCard),
        matching: find.byType(InkWell),
      ),
    );
    expect(inkWell.splashColor, AppColors.primary.withValues(alpha: 0.06));
    expect(inkWell.highlightColor, AppColors.primary.withValues(alpha: 0.04));
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
      BorderRadius.circular(AppRadius.md),
    );

    final tagContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(TagChip),
        matching: find.byType(Container),
      ),
    );
    final tagDecoration = tagContainer.decoration! as BoxDecoration;
    expect(tagDecoration.borderRadius, BorderRadius.circular(AppRadius.sm));
    expect(tagDecoration.border, isA<Border>());
    expect(
      tester.widget<Text>(find.text('#family')).style?.color,
      AppColors.primaryDeep,
    );
  });

  test('AppTheme defines shared Material component themes', () {
    final theme = AppTheme.light();

    final enabledBorder =
        theme.inputDecorationTheme.enabledBorder! as OutlineInputBorder;
    final focusedBorder =
        theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.inputDecorationTheme.fillColor, AppColors.surface);
    expect(enabledBorder.borderRadius, BorderRadius.circular(AppRadius.md));
    expect(enabledBorder.borderSide.color, AppColors.border);
    expect(focusedBorder.borderSide.color, AppColors.primary);
    expect(focusedBorder.borderSide.width, 1.5);

    final selectedStates = <WidgetState>{WidgetState.selected};
    expect(
      theme.segmentedButtonTheme.style?.backgroundColor?.resolve(
        selectedStates,
      ),
      AppColors.primarySoft,
    );
    expect(
      theme.segmentedButtonTheme.style?.foregroundColor?.resolve(
        selectedStates,
      ),
      AppColors.primaryDeep,
    );
    expect(
      theme.segmentedButtonTheme.style?.side?.resolve(selectedStates)?.color,
      AppColors.border,
    );

    expect(theme.chipTheme.backgroundColor, AppColors.surfaceVariant);
    expect(theme.chipTheme.selectedColor, AppColors.primarySoft);
    expect(theme.chipTheme.side, BorderSide.none);

    final dialogShape = theme.dialogTheme.shape! as RoundedRectangleBorder;
    expect(dialogShape.borderRadius, BorderRadius.circular(AppRadius.xl));
    expect(theme.dialogTheme.backgroundColor, AppColors.surface);
    expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);

    final snackShape = theme.snackBarTheme.shape! as RoundedRectangleBorder;
    expect(theme.snackBarTheme.backgroundColor, const Color(0xFF2A2A30));
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(snackShape.borderRadius, BorderRadius.circular(AppRadius.md));

    final sheetShape =
        theme.bottomSheetTheme.shape! as RoundedRectangleBorder;
    expect(theme.bottomSheetTheme.backgroundColor, AppColors.surface);
    expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
    expect(theme.bottomSheetTheme.showDragHandle, isTrue);
    expect(
      sheetShape.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
  });

  testWidgets('SectionHeader renders optional accent and count pill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SectionHeader(
            title: 'Section',
            count: 2,
            accentColor: AppColors.tertiary,
            accentSoftColor: AppColors.warningSoft,
          ),
        ),
      ),
    );

    expect(find.text('2\uAC1C'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) {
          if (widget is! Container ||
              widget.constraints !=
                  const BoxConstraints.tightFor(width: 4, height: 18)) {
            return false;
          }
          final decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == AppColors.tertiary &&
              decoration.borderRadius == BorderRadius.circular(2);
        },
      ),
      findsOneWidget,
    );

    final countPill = tester.widget<Container>(
      find.ancestor(of: find.text('2\uAC1C'), matching: find.byType(Container)),
    );
    final decoration = countPill.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.warningSoft);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.pill));
    expect(
      tester.widget<Text>(find.text('2\uAC1C')).style?.color,
      AppColors.tertiary,
    );
  });
}
