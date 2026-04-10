import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/status_badge.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/models/order_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';

class OrderDetailsView extends StatefulWidget {
  final String orderId;

  const OrderDetailsView({super.key, required this.orderId});

  @override
  State<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<OrderDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderViewModel>(context, listen: false)
          .selectOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, _) {
        final order = viewModel.selectedOrder;

        return Scaffold(
          appBar: CustomAppBar(
            title: order != null ? 'Order #${order.orderId}' : 'Order Details',
          ),
          body: viewModel.isLoading || order == null
              ? const Center(child: CircularProgressIndicator())
              : _OrderDetailsBody(order: order),
          bottomNavigationBar: viewModel.isLoading || order == null
              ? null
              : _ActionBar(order: order),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Body
// ═══════════════════════════════════════════════════════════════════════════

class _OrderDetailsBody extends StatelessWidget {
  final OrderModel order;

  const _OrderDetailsBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeaderCard(order: order),
          const SizedBox(height: AppTheme.spacing8),
          _BuyerInfoCard(buyerName: order.buyerName),
          const SizedBox(height: AppTheme.spacing8),
          _OrderItemsCard(order: order),
          if (_showPickupInfo(order.status)) ...[
            const SizedBox(height: AppTheme.spacing8),
            _PickupInfoCard(order: order),
          ],
          // Extra bottom padding so content doesn't hide behind the action bar
          const SizedBox(height: AppTheme.spacing48),
        ],
      ),
    );
  }

  bool _showPickupInfo(String status) {
    return status == StatusConstants.ready ||
        status == StatusConstants.completed ||
        status == StatusConstants.cancelled;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Status header card
// ═══════════════════════════════════════════════════════════════════════════

class _StatusHeaderCard extends StatelessWidget {
  final OrderModel order;

  const _StatusHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('MMM d, y \u2022 h:mm a')
        .format(order.createdAt.toDate().toLocal());

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            StatusBadge(status: order.status),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _statusDescription(order.status),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Order placed on $dateLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusDescription(String status) {
    switch (status) {
      case StatusConstants.pending:
        return 'Awaiting your approval';
      case StatusConstants.processing:
        return 'Preparing order items';
      case StatusConstants.ready:
        return 'Ready for buyer pickup';
      case StatusConstants.completed:
        return 'Order fulfilled';
      case StatusConstants.cancelled:
        return 'Order was cancelled';
      default:
        return status;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Buyer info card
// ═══════════════════════════════════════════════════════════════════════════

class _BuyerInfoCard extends StatelessWidget {
  final String buyerName;

  const _BuyerInfoCard({required this.buyerName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 24,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buyer',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    buyerName.isNotEmpty ? buyerName : 'Unknown buyer',
                    style: theme.textTheme.titleSmall,
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

// ═══════════════════════════════════════════════════════════════════════════
// Order items card
// ═══════════════════════════════════════════════════════════════════════════

class _OrderItemsCard extends StatelessWidget {
  final OrderModel order;

  const _OrderItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Items (${order.items.length})',
            ),
            const SizedBox(height: AppTheme.spacing8),

            // Item rows
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildItemRow(context, item),
                  if (index < order.items.length - 1)
                    const Divider(height: AppTheme.spacing16),
                ],
              );
            }),

            const Divider(height: AppTheme.spacing24),

            // Subtotal
            if (order.subtotal > 0)
              _buildSummaryRow(
                theme,
                'Subtotal',
                '\u20B1${order.subtotal.toStringAsFixed(2)}',
              ),

            // Points discount
            if (order.pointsDiscount > 0) ...[
              const SizedBox(height: AppTheme.spacing4),
              _buildSummaryRow(
                theme,
                'Points discount',
                '-\u20B1${order.pointsDiscount.toStringAsFixed(2)}',
                valueColor: AppColors.success,
              ),
            ],

            const SizedBox(height: AppTheme.spacing8),

            // Total
            _buildSummaryRow(
              theme,
              'Total',
              '\u20B1${order.totalPrice.toStringAsFixed(2)}',
              isBold: true,
              valueColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, OrderItem item) {
    final theme = Theme.of(context);

    // Resolve item name from bundles/products if available
    String itemName = item.name ?? 'Unknown item';
    String quantityLabel = 'x${item.quantity}';

    if (item.isBundle ?? false) {
      final bundle = order.bundles?.cast<BundleModel?>().firstWhere(
            (b) => b?.id == item.batchId,
            orElse: () => null,
          );
      if (bundle != null) {
        itemName = bundle.name;
      }
    } else {
      final product = order.products?.cast<BatchModel?>().firstWhere(
            (p) => p?.batchNumber == item.batchId,
            orElse: () => null,
          );
      if (product?.product != null) {
        itemName = product!.product!.name;
        quantityLabel = 'x${item.quantity} ${product.quantifier}';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  quantityLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            '\u20B1${(item.price ?? 0).toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
              : theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          value,
          style: isBold
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Pickup / completion info card
// ═══════════════════════════════════════════════════════════════════════════

class _PickupInfoCard extends StatelessWidget {
  final OrderModel order;

  const _PickupInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: _sectionTitle,
            ),
            const SizedBox(height: AppTheme.spacing8),
            ..._buildInfoRows(theme),
          ],
        ),
      ),
    );
  }

  String get _sectionTitle {
    if (order.status == StatusConstants.cancelled) return 'Cancellation Info';
    return 'Pickup Info';
  }

  List<Widget> _buildInfoRows(ThemeData theme) {
    final rows = <Widget>[];

    if (order.status == StatusConstants.ready) {
      // Pickup code displayed prominently
      if (order.pickupCode != null && order.pickupCode!.isNotEmpty) {
        rows.add(_buildPickupCodeDisplay(theme));
      }

      if (order.pickupTime != null) {
        rows.add(const SizedBox(height: AppTheme.spacing12));
        rows.add(_buildInfoRow(
          theme,
          Icons.schedule_rounded,
          'Pickup time',
          DateFormat('MMM d, y \u2022 h:mm a')
              .format(order.pickupTime!.toDate().toLocal()),
        ));
      }

      if (!order.isPaid) {
        rows.add(const SizedBox(height: AppTheme.spacing12));
        rows.add(_buildInfoRow(
          theme,
          Icons.payments_outlined,
          'Pending payment',
          '\u20B1${order.totalPrice.toStringAsFixed(2)}',
          valueColor: AppColors.error,
        ));
      }
    } else if (order.status == StatusConstants.completed) {
      if (order.completedAt != null) {
        rows.add(_buildInfoRow(
          theme,
          Icons.check_circle_outline_rounded,
          'Completed at',
          DateFormat('MMM d, y \u2022 h:mm a')
              .format(order.completedAt!.toDate().toLocal()),
        ));
      }
    } else if (order.status == StatusConstants.cancelled) {
      rows.add(_buildInfoRow(
        theme,
        Icons.cancel_outlined,
        'Cancelled at',
        order.cancelledAt != null
            ? DateFormat('MMM d, y \u2022 h:mm a')
                .format(order.cancelledAt!.toDate().toLocal())
            : 'N/A',
      ));
    }

    return rows;
  }

  Widget _buildPickupCodeDisplay(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.lightColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Column(
        children: [
          Text(
            'Pickup Code',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.darkColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            order.pickupCode!,
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.darkColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action bar (sticky bottom)
// ═══════════════════════════════════════════════════════════════════════════

class _ActionBar extends StatelessWidget {
  final OrderModel order;

  const _ActionBar({required this.order});

  @override
  Widget build(BuildContext context) {
    // No actions for completed or cancelled orders
    if (order.status == StatusConstants.completed ||
        order.status == StatusConstants.cancelled) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          child: _buildActions(context),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final viewModel = context.watch<OrderViewModel>();
    final isLoading = viewModel.isLoading;

    switch (order.status) {
      case StatusConstants.pending:
        return Row(
          children: [
            Expanded(
              child: CustomButton.destructive(
                text: 'Cancel Order',
                isLoading: isLoading,
                onPressed: () => _showCancelDialog(context, viewModel),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: CustomButton(
                text: 'Approve Order',
                isLoading: isLoading,
                onPressed: () => _showApproveDialog(context, viewModel),
              ),
            ),
          ],
        );

      case StatusConstants.processing:
        return CustomButton(
          text: 'Mark as Ready',
          isLoading: isLoading,
          onPressed: () => _handleFulfill(context, viewModel),
        );

      case StatusConstants.ready:
        return CustomButton(
          text: 'Complete Order',
          isLoading: isLoading,
          onPressed: () => _showCompleteDialog(context, viewModel),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Dialogs and action handlers ──────────────────────────────────────

  void _showCancelDialog(BuildContext context, OrderViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleCancel(context, viewModel);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, OrderViewModel viewModel) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Order'),
        content: const Text(
          'Are you sure you want to approve this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleApprove(context, viewModel);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, OrderViewModel viewModel) {
    final message = order.isPaid
        ? 'Are you sure you want to complete this order?'
        : 'Confirming order means you have accepted the money from the buyer.';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete Order'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleComplete(context, viewModel);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(
    BuildContext context,
    OrderViewModel viewModel,
  ) async {
    try {
      await viewModel.approveOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order has been approved successfully!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCancel(
    BuildContext context,
    OrderViewModel viewModel,
  ) async {
    try {
      await viewModel.cancelOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order has been cancelled successfully!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleFulfill(
    BuildContext context,
    OrderViewModel viewModel,
  ) async {
    try {
      await viewModel.fulfillOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as ready for pickup!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fulfill order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleComplete(
    BuildContext context,
    OrderViewModel viewModel,
  ) async {
    try {
      await viewModel.completeOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order has been completed!'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
