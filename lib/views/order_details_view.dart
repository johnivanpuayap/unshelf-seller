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

/// Detail screen for a single order.
///
/// Layout: hero (order number + status badge + total) → buyer info card →
/// items card with subtotal/total → contextual pickup/cancellation info →
/// sticky bottom action bar with status-aware buttons.
class OrderDetailsView extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsView({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends ConsumerState<OrderDetailsView> {
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
                    _ItemsCard(order: order),
                    if (_showPickupInfo(order.status)) ...[
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
      bottomNavigationBar: order == null
          ? null
          : _ActionBar(order: order, isLoading: state.isLoading),
    );
  }

  bool _showPickupInfo(String status) {
    return status == StatusConstants.ready ||
        status == StatusConstants.completed ||
        status == StatusConstants.cancelled;
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

    if (order.status == StatusConstants.ready) {
      if (order.pickupCode != null && order.pickupCode!.isNotEmpty) {
        rows.add(_PickupCodeDisplay(code: order.pickupCode!));
      }
      if (order.pickupTime != null) {
        if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
        rows.add(_InfoRow(
          icon: Icons.schedule_rounded,
          label: 'Pickup time',
          value: DateFormat('MMM d, y • h:mm a')
              .format(order.pickupTime!.toDate().toLocal()),
        ));
      }
      if (!order.isPaid) {
        if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
        rows.add(_InfoRow(
          icon: Icons.payments_outlined,
          label: 'Pending payment',
          value: NumberFormat.currency(symbol: '₱', decimalDigits: 2)
              .format(order.totalPrice),
          valueColor: cs.error,
        ));
      }
    } else if (order.status == StatusConstants.completed) {
      if (order.completedAt != null) {
        rows.add(_InfoRow(
          icon: Icons.check_circle_outline_rounded,
          label: 'Completed at',
          value: DateFormat('MMM d, y • h:mm a')
              .format(order.completedAt!.toDate().toLocal()),
        ));
      }
    } else if (order.status == StatusConstants.cancelled) {
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

class _PickupCodeDisplay extends StatelessWidget {
  const _PickupCodeDisplay({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Pickup code',
            style: tt.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: tt.displaySmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

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
                style: tt.titleSmall?.copyWith(
                  color: valueColor ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Action bar (sticky bottom)
// ────────────────────────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.order, required this.isLoading});

  final OrderModel order;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.status == StatusConstants.completed ||
        order.status == StatusConstants.cancelled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2A20).withValues(alpha: .06),
            offset: const Offset(0, -8),
            blurRadius: 28,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: _buildActions(context, ref),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    switch (order.status) {
      case StatusConstants.pending:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed:
                      isLoading ? null : () => _showCancelDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: cs.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: tt.labelLarge?.copyWith(color: cs.error),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : () => _showApproveDialog(context, ref),
                  child: isLoading
                      ? _spinner(cs.onPrimary)
                      : const Text('Approve'),
                ),
              ),
            ),
          ],
        );

      case StatusConstants.processing:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _handleFulfill(context, ref),
            child: isLoading
                ? _spinner(cs.onPrimary)
                : const Text('Mark ready'),
          ),
        );

      case StatusConstants.ready:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed:
                isLoading ? null : () => _showCompleteDialog(context, ref),
            child: isLoading
                ? _spinner(cs.onPrimary)
                : const Text('Mark picked up'),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _spinner(Color color) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color,
      ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Cancel this order?',
          style: tt.titleMedium?.copyWith(color: cs.onSurface),
        ),
        content: Text(
          "This will notify the buyer and can't be undone.",
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Keep order',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleCancel(context, ref);
            },
            child: Text(
              'Yes, cancel',
              style: tt.labelLarge?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Approve this order?',
          style: tt.titleMedium?.copyWith(color: cs.onSurface),
        ),
        content: Text(
          'The buyer will be notified that their order is being prepared.',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Not now',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleApprove(context, ref);
            },
            child: Text(
              'Approve',
              style: tt.labelLarge?.copyWith(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final message = order.isPaid
        ? 'Mark this order as picked up?'
        : 'Confirming means you have received payment from the buyer.';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Mark as picked up?',
          style: tt.titleMedium?.copyWith(color: cs.onSurface),
        ),
        content: Text(
          message,
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Not now',
              style: tt.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _handleComplete(context, ref);
            },
            child: Text(
              'Confirm',
              style: tt.labelLarge?.copyWith(color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action handlers ────────────────────────────────────────────────────

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(orderViewModelProvider.notifier).approveOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order approved.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't approve order.")),
        );
      }
    }
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(orderViewModelProvider.notifier).cancelOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't cancel order.")),
        );
      }
    }
  }

  Future<void> _handleFulfill(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(orderViewModelProvider.notifier).fulfillOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked ready for pickup.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't mark order ready.")),
        );
      }
    }
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(orderViewModelProvider.notifier).completeOrder();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked picked up.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't complete order.")),
        );
      }
    }
  }
}
