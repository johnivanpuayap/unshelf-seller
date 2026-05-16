import 'package:flutter/material.dart';

/// A Quality-Bar settings row used inside a grouped settings card.
///
/// Layout: leading icon in a small rounded-square primary-tinted background,
/// a title, an optional subtitle, and a trailing widget (a chevron by default
/// for navigation rows, or a [Switch] for toggle rows). The whole row is
/// tappable via [onTap].
///
/// Extracted from `settings_view.dart` once usage crossed the 3+ threshold,
/// per the Phase 4 components-extraction rule.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Optional trailing widget — typically a [Switch] for toggle rows. If
  /// omitted, a chevron is rendered (matching the navigation-row pattern).
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Optional override for the leading icon tint. Defaults to `cs.primary`.
  /// Useful for destructive rows where the icon picks up `cs.error` instead.
  final Color? iconColor;

  /// Optional override for the title color. Defaults to `cs.onSurface`. Mirrors
  /// [iconColor] for destructive rows.
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final effectiveIconColor = iconColor ?? cs.primary;
    final effectiveTitleColor = titleColor ?? cs.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: effectiveIconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: tt.titleSmall?.copyWith(color: effectiveTitleColor),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
