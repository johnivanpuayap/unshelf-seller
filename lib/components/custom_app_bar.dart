import 'package:flutter/material.dart';

/// A themed AppBar that delegates all color and typography decisions to
/// [Theme.of(context)] (configured in AppTheme).
///
/// Improvements over the original:
/// - No hardcoded colors — fully theme-driven.
/// - Back arrow is white to ensure contrast on the teal background.
/// - Bottom divider removed (flat Material 3 style).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final Widget? actionWidget;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actionWidget,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      actions: actionWidget != null ? [actionWidget!] : null,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
