import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/viewmodels/batch_history_viewmodel.dart';

/// Batch history screen.
///
/// Shows a single batch's order history: summary KPI card (units sold + total
/// sale) on top, then a list of orders that drew stock from this batch.
class BatchHistoryView extends ConsumerStatefulWidget {
  final String batchId;

  const BatchHistoryView({super.key, required this.batchId});

  @override
  ConsumerState<BatchHistoryView> createState() => _BatchHistoryViewState();
}

class _BatchHistoryViewState extends ConsumerState<BatchHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(batchHistoryViewModelProvider.notifier)
          .fetchBatchHistory(widget.batchId);
    });
  }

  Future<void> _refresh() => ref
      .read(batchHistoryViewModelProvider.notifier)
      .fetchBatchHistory(widget.batchId);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchHistoryViewModelProvider);
    final notifier = ref.read(batchHistoryViewModelProvider.notifier);
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
          'Batch history',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return _HistoryError(
              message: state.errorMessage!,
              onRetry: _refresh,
            );
          }

          final batchData = notifier.batchHistory[widget.batchId];
          if (batchData == null) {
            return const EmptyState(
              icon: Icons.history_outlined,
              title: 'No history yet',
              subtitle: "This batch hasn't been sold in any orders.",
            );
          }

          final orderHistory =
              (batchData['orderHistory'] as List?) ?? const [];
          final unitsSold =
              (batchData['totalProductsSold'] as num?)?.toInt() ?? 0;
          final totalSale =
              (batchData['totalSaleSize'] as num?)?.toDouble() ?? 0.0;

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: _refresh,
            child: SafeArea(
              top: false,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  _SummaryCard(
                    batchId: widget.batchId,
                    unitsSold: unitsSold,
                    totalSale: totalSale,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Orders',
                    style: tt.titleMedium?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 16),
                  if (orderHistory.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      subtitle:
                          'Once buyers place orders against this batch, '
                          "they'll show up here.",
                    )
                  else
                    for (var i = 0; i < orderHistory.length; i++) ...[
                      _OrderRow(entry: orderHistory[i]),
                      if (i < orderHistory.length - 1)
                        const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Summary card
// ────────────────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.batchId,
    required this.unitsSold,
    required this.totalSale,
  });

  final String batchId;
  final int unitsSold;
  final double totalSale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final priceLabel =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalSale);

    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch $batchId',
            style: tt.titleSmall?.copyWith(color: cs.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricBlock(
                  label: 'Units sold',
                  value: unitsSold.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MetricBlock(
                  label: 'Total sale',
                  value: priceLabel,
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Order row
// ────────────────────────────────────────────────────────────────────────────

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.entry});

  /// May be either a raw Map (seeded demo data) or an [OrderModel] (live
  /// fetch). We read the fields defensively to support both shapes.
  final dynamic entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final orderId = _readOrderId(entry);
    final isBundle = _readBundle(entry);
    final quantity = _readQuantity(entry);
    final price = _readPrice(entry);
    final priceLabel =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(price);

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              isBundle
                  ? CupertinoIcons.gift
                  : Icons.shopping_bag_outlined,
              color: cs.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order $orderId',
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$quantity ${quantity == 1 ? "unit" : "units"} '
                  '${isBundle ? "(in a bundle)" : ""}',
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
            style: tt.titleSmall?.copyWith(color: cs.primary),
          ),
        ],
      ),
    );
  }

  String _readOrderId(dynamic e) {
    if (e is Map) return (e['orderId'] ?? '').toString();
    try {
      return (e.orderId as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  bool _readBundle(dynamic e) {
    if (e is Map) return (e['soldWithBundle'] ?? false) as bool;
    return false;
  }

  int _readQuantity(dynamic e) {
    if (e is Map) return (e['soldQuantity'] as num?)?.toInt() ?? 0;
    try {
      return (e.items as List?)?.fold<int>(
            0,
            (sum, item) => sum + ((item.quantity as int?) ?? 0),
          ) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  double _readPrice(dynamic e) {
    if (e is Map) return (e['soldPrice'] as num?)?.toDouble() ?? 0.0;
    try {
      return (e.totalPrice as num?)?.toDouble() ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Error
// ────────────────────────────────────────────────────────────────────────────

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load batch history",
              style:
                  theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
