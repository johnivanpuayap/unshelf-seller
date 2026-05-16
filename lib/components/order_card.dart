import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/status_badge.dart';

/// A compact card representing a single order.
///
/// Soft Editorial styling: honey-paper raised surface
/// (`colorScheme.surfaceContainerHighest`), 14px radius, two-layer shadow.
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
    final cs = theme.colorScheme;
    final dateLabel = DateFormat('MMM d, y').format(createdAt);
    final priceLabel =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2)
            .format(totalPrice);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            offset: const Offset(0, 1),
            blurRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1F2A20).withValues(alpha: .06),
            offset: const Offset(0, 8),
            blurRadius: 28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '#$orderId',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        buyerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    Text(
                      priceLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
