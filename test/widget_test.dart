import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

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

  group('AppTheme', () {
    test('spacing scale follows 8dp grid', () {
      expect(AppTheme.spacing4, 4);
      expect(AppTheme.spacing8, 8);
      expect(AppTheme.spacing12, 12);
      expect(AppTheme.spacing16, 16);
      expect(AppTheme.spacing24, 24);
      expect(AppTheme.spacing32, 32);
      expect(AppTheme.spacing48, 48);
    });

    test('minimum touch target is 48dp', () {
      expect(AppTheme.minTouchTarget, 48);
    });

    test('border radius scale is defined', () {
      expect(AppTheme.radiusSmall, 8);
      expect(AppTheme.radiusMedium, 12);
      expect(AppTheme.radiusLarge, 16);
      expect(AppTheme.radiusFull, 100);
    });

    testWidgets('light theme creates valid ThemeData', (tester) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primaryColor);
      expect(theme.colorScheme.error, AppColors.error);
      expect(theme.textTheme.displayLarge, isNotNull);
      expect(theme.textTheme.headlineMedium, isNotNull);
      expect(theme.textTheme.bodyMedium, isNotNull);
      expect(theme.textTheme.labelSmall, isNotNull);
    });

    testWidgets('light theme renders scaffold correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(child: Text('Unshelf Seller')),
          ),
        ),
      );

      expect(find.text('Unshelf Seller'), findsOneWidget);
    });
  });
}
