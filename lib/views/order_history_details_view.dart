import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/status_badge.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/models/order_model.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';

/// Read-only detail screen for an order in history.
///
/// Mirrors [OrderDetailsView]'s layout (hero + buyer + items + pickup info)
/// but omits the action bar — historical orders aren't actionable from here.
class OrderHistoryDetailsView extends ConsumerStatefulWidget {
  final String orderId;

  const OrderHistoryDetailsView({super.key, required this.orderId});

  @override
  ConsumerState<OrderHistoryDetailsView> createState() =>
      _OrderHistoryDetailsViewState();
}

class _OrderHistoryDetailsViewState
    extends ConsumerState<OrderHistoryDetailsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderViewModelProvider.notifier).selectOrder(widget.orderId);
    });
  }

  Future<void> _refresh() =>
      ref.read(orderViewModelProvider.notifier).selectOrder(widget.orderId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderViewModelProvider);
    final order = state.selectedOrder;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          order != null ? 'Order #${order.orderId}' : 'Order',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (order == null) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Order not available',
              subtitle: state.errorMessage ??
                  'This order may have been removed or is unavailable.',
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          return RefreshIndicator(
            color: cs.primary,
            onRefresh: _refresh,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(order: order),
                    const SizedBox(height: 16),
                    _BuyerCard(buyerName: order.buyerName),
                    const SizedBox(height: 16),
                    _PaymentCard(order: order),
                    const SizedBox(height: 16),
                    _ItemsCard(order: order),
                    if (_showPickupInfo(order)) ...[
                      const SizedBox(height: 16),
                      _PickupInfoCard(order: order),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _showPickupInfo(OrderModel order) {
    return order.status == StatusConstants.ready ||
        order.status == StatusConstants.completed ||
        order.status == StatusConstants.cancelled;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Shared card decoration
// ────────────────────────────────────────────────────────────────────────────

BoxDecoration _cardDecoration(ColorScheme cs) {
  return BoxDecoration(
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
  );
}

// ────────────────────────────────────────────────────────────────────────────
// Hero card
// ────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final dateLabel = DateFormat('MMM d, y • h:mm a')
        .format(order.createdAt.toDate().toLocal());
    final totalLabel = NumberFormat.currency(symbol: '₱', decimalDigits: 2)
        .format(order.totalPrice);

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(cs),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: tt.titleSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusDescription(order.status),
                      style: tt.headlineSmall?.copyWith(color: cs.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                totalLabel,
                style: tt.headlineSmall?.copyWith(color: cs.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusDescription(String status) {
    switch (status) {
      case StatusConstants.pending:
        return 'Was awaiting approval';
      case StatusConstants.processing:
        return 'Was in processing';
      case StatusConstants.ready:
        return 'Ready for pickup';
      case StatusConstants.completed:
        return 'Order fulfilled';
      case StatusConstants.cancelled:
        return 'Order was cancelled';
      default:
        return status;
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Buyer card
// ────────────────────────────────────────────────────────────────────────────

class _BuyerCard extends StatelessWidget {
  const _BuyerCard({required this.buyerName});

  final String buyerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(cs),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 22,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buyer',
                  style: tt.labelLarge?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  buyerName.isNotEmpty ? buyerName : 'Unknown buyer',
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Payment card
// ────────────────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(cs),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: tt.titleMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Method',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              Text(
                order.isPaid ? 'Paid online' : 'Cash on pickup',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              StatusBadge(
                status: order.isPaid
                    ? StatusConstants.paid
                    : StatusConstants.unpaid,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Items card
// ────────────────────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(cs),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${order.items.length})',
            style: tt.titleMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < order.items.length; i++) ...[
            _ItemRow(item: order.items[i], order: order),
            if (i < order.items.length - 1)
              Divider(
                height: 24,
                color: cs.onSurface.withValues(alpha: 0.08),
              ),
          ],
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: cs.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          if (order.subtotal > 0)
            _SummaryRow(
              label: 'Subtotal',
              value: NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                  .format(order.subtotal),
            ),
          if (order.pointsDiscount > 0) ...[
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Points discount',
              value:
                  '-${NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(order.pointsDiscount)}',
              valueColor: cs.primary,
            ),
          ],
          const SizedBox(height: 16),
          _SummaryRow(
            label: 'Total',
            value: NumberFormat.currency(symbol: '₱', decimalDigits: 2)
                .format(order.totalPrice),
            isTotal: true,
            valueColor: cs.primary,
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.order});

  final OrderItem item;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final resolved = _resolveItem();
    final lineTotal = (item.price ?? 0);
    final priceLabel =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(lineTotal);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 48,
            height: 48,
            child: resolved.imageUrl.isEmpty
                ? Container(
                    color: cs.surface,
                    child: Icon(
                      Icons.image_outlined,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  )
                : Image.network(
                    resolved.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cs.surface,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resolved.name,
                style: tt.titleSmall?.copyWith(color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                resolved.quantityLabel,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          priceLabel,
          style: tt.titleSmall?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }

  _ResolvedItem _resolveItem() {
    String name = item.name ?? 'Unknown item';
    String quantityLabel = '× ${item.quantity}';
    String imageUrl = '';

    if (item.isBundle ?? false) {
      final bundle = order.bundles?.cast<BundleModel?>().firstWhere(
            (b) => b?.id == item.batchId,
            orElse: () => null,
          );
      if (bundle != null) {
        name = bundle.name;
        imageUrl = bundle.mainImageUrl;
      }
    } else {
      final batch = order.products?.cast<BatchModel?>().firstWhere(
            (p) => p?.batchNumber == item.batchId,
            orElse: () => null,
          );
      if (batch?.product != null) {
        name = batch!.product!.name;
        quantityLabel = '× ${item.quantity} ${batch.quantifier}'.trim();
        imageUrl = batch.product!.mainImageUrl;
      }
    }

    return _ResolvedItem(
      name: name,
      quantityLabel: quantityLabel,
      imageUrl: imageUrl,
    );
  }
}

class _ResolvedItem {
  final String name;
  final String quantityLabel;
  final String imageUrl;

  const _ResolvedItem({
    required this.name,
    required this.quantityLabel,
    required this.imageUrl,
  });
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final labelStyle = isTotal
        ? tt.titleMedium?.copyWith(color: cs.onSurface)
        : tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
          );
    final valueStyle = isTotal
        ? tt.titleLarge?.copyWith(color: valueColor ?? cs.onSurface)
        : tt.bodyMedium?.copyWith(color: valueColor ?? cs.onSurface);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Pickup info card
// ────────────────────────────────────────────────────────────────────────────

class _PickupInfoCard extends StatelessWidget {
  const _PickupInfoCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final rows = _buildRows(theme);

    return Container(
      width: double.infinity,
      decoration: _cardDecoration(cs),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.status == StatusConstants.cancelled
                ? 'Cancellation info'
                : 'Pickup info',
            style: tt.titleMedium?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  List<Widget> _buildRows(ThemeData theme) {
    final cs = theme.colorScheme;
    final rows = <Widget>[];

    if (order.pickupTime != null) {
      rows.add(_InfoRow(
        icon: Icons.schedule_rounded,
        label: 'Scheduled pickup',
        value: DateFormat('MMM d, y • h:mm a')
            .format(order.pickupTime!.toDate().toLocal()),
      ));
    }

    if (order.status == StatusConstants.ready ||
        order.status == StatusConstants.completed) {
      if (order.pickupCode != null && order.pickupCode!.isNotEmpty) {
        if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
        rows.add(_InfoRow(
          icon: Icons.confirmation_number_outlined,
          label: 'Pickup code',
          value: order.pickupCode!,
        ));
      }
    }

    if (order.status == StatusConstants.completed &&
        order.completedAt != null) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(_InfoRow(
        icon: Icons.check_circle_outline_rounded,
        label: 'Completed at',
        value: DateFormat('MMM d, y • h:mm a')
            .format(order.completedAt!.toDate().toLocal()),
      ));
    }

    if (order.status == StatusConstants.cancelled) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(_InfoRow(
        icon: Icons.cancel_outlined,
        label: 'Cancelled at',
        value: order.cancelledAt != null
            ? DateFormat('MMM d, y • h:mm a')
                .format(order.cancelledAt!.toDate().toLocal())
            : 'N/A',
      ));
    }

    if (rows.isEmpty) {
      rows.add(Text(
        'No additional details.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
      ));
    }

    return rows;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.65)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: tt.titleSmall?.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
