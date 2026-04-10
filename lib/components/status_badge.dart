import 'package:flutter/material.dart';

import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

/// A compact, pill-shaped badge that renders order/product statuses using
/// semantic colors from [AppColors].
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
          height: 1,
        ),
      ),
    );
  }

  _StatusColors _resolveColors(String status) {
    switch (status) {
      case StatusConstants.processing:
        return const _StatusColors(
          background: AppColors.statusProcessing,
          foreground: AppColors.statusProcessingText,
        );
      case StatusConstants.ready:
        return const _StatusColors(
          background: AppColors.statusReady,
          foreground: AppColors.statusReadyText,
        );
      case StatusConstants.completed:
        return const _StatusColors(
          background: AppColors.statusCompleted,
          foreground: AppColors.statusCompletedText,
        );
      case StatusConstants.cancelled:
        return const _StatusColors(
          background: AppColors.statusCancelled,
          foreground: AppColors.statusCancelledText,
        );
      case StatusConstants.pending:
      default:
        return const _StatusColors(
          background: AppColors.statusPending,
          foreground: AppColors.statusPendingText,
        );
    }
  }
}

class _StatusColors {
  final Color background;
  final Color foreground;

  const _StatusColors({required this.background, required this.foreground});
}
