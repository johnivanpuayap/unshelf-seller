import 'package:flutter/material.dart';

import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

/// A KPI metric card for the dashboard.
/// Displays a single metric with a label, value, and optional icon.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? AppColors.primaryColor;

    return Card(
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: const BorderSide(color: AppColors.border),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container
            Container(
              width: AppTheme.minTouchTarget,
              height: AppTheme.minTouchTarget,
              decoration: BoxDecoration(
                color: resolvedIconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Icon(
                icon,
                color: resolvedIconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            // Label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
