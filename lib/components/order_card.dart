import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/status_badge.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

/// A compact card representing a single order.
/// Used in the orders list and the dashboard recent-orders section.
class OrderCard extends StatelessWidget {
  final String orderId;
  final String buyerName;
  final String status;
  final double totalPrice;
  final DateTime createdAt;
  final int itemCount;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.buyerName,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    required this.itemCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('MMM d, y').format(createdAt);
    final priceLabel =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalPrice);

    return Card(
      elevation: AppTheme.elevationLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: order ID + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '#$orderId',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  StatusBadge(status: status),
                ],
              ),

              const SizedBox(height: AppTheme.spacing8),

              // Middle row: buyer name + item count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    buyerName,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing8),

              // Bottom row: date + price
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    priceLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
