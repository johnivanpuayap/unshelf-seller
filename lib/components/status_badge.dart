import 'package:flutter/material.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';

/// A compact, pill-shaped badge that renders order, payment, and product
/// statuses using the Leaf & Honey palette via `Theme.of(context).colorScheme`.
///
/// The brand kit does not define explicit status tones, so this widget maps
/// the existing string statuses to semantic colorScheme roles:
///
/// - Pending / Processing → tertiary
/// - Ready / Completed / Paid → primary
/// - Cancelled / Unpaid → error
/// - Low stock / Out of stock → error
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = _palette(status, cs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        palette.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: palette.foreground,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }

  _StatusPalette _palette(String status, ColorScheme cs) {
    switch (status) {
      case StatusConstants.processing:
        return _StatusPalette(
          background: cs.tertiary.withValues(alpha: 0.15),
          foreground: cs.tertiary,
          label: status,
        );
      case StatusConstants.ready:
      case StatusConstants.completed:
      case StatusConstants.paid:
        return _StatusPalette(
          background: cs.primary.withValues(alpha: 0.14),
          foreground: cs.primary,
          label: status,
        );
      case StatusConstants.cancelled:
      case StatusConstants.unpaid:
        return _StatusPalette(
          background: cs.error.withValues(alpha: 0.15),
          foreground: cs.error,
          label: status,
        );
      case StatusConstants.pending:
      default:
        return _StatusPalette(
          background: cs.tertiary.withValues(alpha: 0.15),
          foreground: cs.tertiary,
          label: status,
        );
    }
  }
}

class _StatusPalette {
  final Color background;
  final Color foreground;
  final String label;

  const _StatusPalette({
    required this.background,
    required this.foreground,
    required this.label,
  });
}
