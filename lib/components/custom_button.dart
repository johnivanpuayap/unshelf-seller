import 'package:flutter/material.dart';

import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

/// Variants supported by [CustomButton].
enum _ButtonVariant { primary, outlined, destructive }

/// Sizes supported by [CustomButton].
enum _ButtonSize { regular, small, large }

/// A versatile button component with multiple size and style variants.
///
/// Named constructors:
/// - [CustomButton.new]       — Default primary (full-width) button.
/// - [CustomButton.small]     — Compact inline button.
/// - [CustomButton.large]     — Prominent hero-style button.
/// - [CustomButton.outlined]  — Outlined / secondary action.
/// - [CustomButton.destructive] — Red destructive action (delete/cancel).
///
/// All variants support an [isLoading] state which swaps the label for a
/// [CircularProgressIndicator] and disables the button.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final _ButtonVariant _variant;
  final _ButtonSize _size;

  // ─── Default (primary) ───────────────────────────────────────────────────
  const CustomButton({
    super.key,
    required this.text,
    required VoidCallback this.onPressed,
    this.isLoading = false,
  })  : _variant = _ButtonVariant.primary,
        _size = _ButtonSize.regular;

  // ─── Small ───────────────────────────────────────────────────────────────
  const CustomButton.small({
    super.key,
    required this.text,
    required VoidCallback this.onPressed,
    this.isLoading = false,
  })  : _variant = _ButtonVariant.primary,
        _size = _ButtonSize.small;

  // ─── Large ───────────────────────────────────────────────────────────────
  const CustomButton.large({
    super.key,
    required this.text,
    required VoidCallback this.onPressed,
    this.isLoading = false,
  })  : _variant = _ButtonVariant.primary,
        _size = _ButtonSize.large;

  // ─── Outlined ────────────────────────────────────────────────────────────
  const CustomButton.outlined({
    super.key,
    required this.text,
    required VoidCallback this.onPressed,
    this.isLoading = false,
  })  : _variant = _ButtonVariant.outlined,
        _size = _ButtonSize.regular;

  // ─── Destructive ─────────────────────────────────────────────────────────
  const CustomButton.destructive({
    super.key,
    required this.text,
    required VoidCallback this.onPressed,
    this.isLoading = false,
  })  : _variant = _ButtonVariant.destructive,
        _size = _ButtonSize.regular;

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = isLoading ? null : onPressed;
    final child = _buildChild();

    switch (_variant) {
      case _ButtonVariant.outlined:
        return _wrapPadding(
          OutlinedButton(
            onPressed: effectiveCallback,
            style: _outlinedStyle(),
            child: child,
          ),
        );

      case _ButtonVariant.destructive:
        return _wrapPadding(
          ElevatedButton(
            onPressed: effectiveCallback,
            style: _destructiveStyle(),
            child: child,
          ),
        );

      case _ButtonVariant.primary:
        return _wrapPadding(
          ElevatedButton(
            onPressed: effectiveCallback,
            style: _primaryStyle(),
            child: child,
          ),
        );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _wrapPadding(Widget button) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      child: button,
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      final indicatorSize = _size == _ButtonSize.small ? 16.0 : 20.0;
      return SizedBox(
        width: indicatorSize,
        height: indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _variant == _ButtonVariant.outlined
                ? AppColors.primaryColor
                : Colors.white,
          ),
        ),
      );
    }

    return Text(text);
  }

  ButtonStyle _primaryStyle() {
    return ElevatedButton.styleFrom(
      minimumSize: _minSize(),
      padding: _padding(),
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: _minSize(),
      padding: _padding(),
    );
  }

  ButtonStyle _destructiveStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      minimumSize: _minSize(),
      padding: _padding(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
    );
  }

  Size _minSize() {
    switch (_size) {
      case _ButtonSize.small:
        return const Size(0, 36);
      case _ButtonSize.large:
        return const Size(double.infinity, 56);
      case _ButtonSize.regular:
        return const Size(double.infinity, AppTheme.minTouchTarget);
    }
  }

  EdgeInsets _padding() {
    switch (_size) {
      case _ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        );
      case _ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing32,
          vertical: AppTheme.spacing16,
        );
      case _ButtonSize.regular:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing24,
          vertical: AppTheme.spacing12,
        );
    }
  }
}
