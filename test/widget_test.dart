import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/utils/tokens.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppColors', () {
    test('primary color is vibrant green', () {
      expect(AppColors.primaryColor.value, 0xFF22C55E);
    });

    test('all status colors are defined', () {
      expect(AppColors.statusPending, isNotNull);
      expect(AppColors.statusPendingText, isNotNull);
      expect(AppColors.statusProcessing, isNotNull);
      expect(AppColors.statusProcessingText, isNotNull);
      expect(AppColors.statusReady, isNotNull);
      expect(AppColors.statusReadyText, isNotNull);
      expect(AppColors.statusCompleted, isNotNull);
      expect(AppColors.statusCompletedText, isNotNull);
      expect(AppColors.statusCancelled, isNotNull);
      expect(AppColors.statusCancelledText, isNotNull);
    });

    test('semantic colors are defined', () {
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.info, isNotNull);
    });
  });

  group('UnshelfTheme', () {
    testWidgets('light theme is driven by brand-kit tokens', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: UnshelfTheme.light(),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, UnshelfTokens.colorLightPrimary);
      expect(theme.colorScheme.secondary, UnshelfTokens.colorLightAccent);
      expect(theme.colorScheme.error, UnshelfTokens.colorLightDestructive);
      expect(theme.scaffoldBackgroundColor, UnshelfTokens.colorLightBackground);
      expect(theme.textTheme.displayLarge, isNotNull);
      expect(theme.textTheme.headlineMedium, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.labelSmall, isNotNull);
    });

    testWidgets('dark theme is driven by brand-kit tokens', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: UnshelfTheme.dark(),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, UnshelfTokens.colorDarkPrimary);
      expect(theme.colorScheme.secondary, UnshelfTokens.colorDarkAccent);
      expect(theme.colorScheme.error, UnshelfTokens.colorDarkDestructive);
      expect(theme.scaffoldBackgroundColor, UnshelfTokens.colorDarkBackground);
    });

    testWidgets('light theme renders scaffold correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UnshelfTheme.light(),
          home: const Scaffold(
            body: Center(child: Text('Unshelf Seller')),
          ),
        ),
      );

      expect(find.text('Unshelf Seller'), findsOneWidget);
    });
  });
}
