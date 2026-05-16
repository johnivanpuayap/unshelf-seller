import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/status_badge.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/models/order_model.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/views/order_history_details_view.dart';

/// Historical orders grouped by recency.
///
/// Sections: Today / This week / This month / Earlier. Each row shows order
/// number + status pill + total + relative timestamp. Tap →
/// [OrderHistoryDetailsView].
class OrderHistoryView extends ConsumerStatefulWidget {
  const OrderHistoryView({super.key});

  @override
  ConsumerState<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends ConsumerState<OrderHistoryView> {
  static const _statusFilters = <String>[
    'All',
    StatusConstants.completed,
    StatusConstants.cancelled,
    StatusConstants.ready,
    StatusConstants.processing,
    StatusConstants.pending,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderViewModelProvider.notifier).fetchOrdersHistory();
    });
  }

  Future<void> _refresh() =>
      ref.read(orderViewModelProvider.notifier).fetchOrdersHistory();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final state = ref.watch(orderViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order history',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _refresh,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: _StatusFilterChips(
                    filters: _statusFilters,
                    selected: state.currentStatus,
                    onSelected: (value) {
                      ref
                          .read(orderViewModelProvider.notifier)
                          .filterOrdersByStatus(value);
                    },
                  ),
                ),
              ),
              if (state.isLoading && state.orders.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null && state.orders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _HistoryError(
                    message: state.errorMessage!,
                    onRetry: _refresh,
                  ),
                )
              else if (state.filteredOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.history_outlined,
                    title: _emptyTitle(state.currentStatus),
                    subtitle: _emptySubtitle(state.currentStatus),
                  ),
                )
              else
                ..._buildGroupedSlivers(context, state.filteredOrders),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSlivers(
    BuildContext context,
    List<OrderModel> orders,
  ) {
    final groups = _groupOrders(orders);
    final slivers = <Widget>[];

    for (final group in groups) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          sliver: SliverToBoxAdapter(
            child: _GroupHeader(label: group.label),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          sliver: SliverList.separated(
            itemCount: group.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = group.orders[index];
              return _HistoryRow(order: order);
            },
          ),
        ),
      );
    }

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return slivers;
  }

  List<_OrderGroup> _groupOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    final today = <OrderModel>[];
    final thisWeek = <OrderModel>[];
    final thisMonth = <OrderModel>[];
    final earlier = <OrderModel>[];

    for (final o in orders) {
      final created = o.createdAt.toDate().toLocal();
      if (!created.isBefore(startOfDay)) {
        today.add(o);
      } else if (!created.isBefore(startOfWeek)) {
        thisWeek.add(o);
      } else if (!created.isBefore(startOfMonth)) {
        thisMonth.add(o);
      } else {
        earlier.add(o);
      }
    }

    return [
      if (today.isNotEmpty) _OrderGroup(label: 'Today', orders: today),
      if (thisWeek.isNotEmpty) _OrderGroup(label: 'This week', orders: thisWeek),
      if (thisMonth.isNotEmpty)
        _OrderGroup(label: 'This month', orders: thisMonth),
      if (earlier.isNotEmpty) _OrderGroup(label: 'Earlier', orders: earlier),
    ];
  }

  String _emptyTitle(String status) {
    switch (status) {
      case StatusConstants.completed:
        return 'No completed orders yet';
      case StatusConstants.cancelled:
        return 'No cancelled orders';
      case StatusConstants.ready:
        return 'No orders ready';
      case StatusConstants.processing:
        return 'No orders in processing';
      case StatusConstants.pending:
        return 'No pending orders';
      default:
        return 'No order history yet';
    }
  }

  String _emptySubtitle(String status) {
    switch (status) {
      case StatusConstants.completed:
        return 'Fulfilled orders will be listed here.';
      case StatusConstants.cancelled:
        return 'Cancelled orders will appear here.';
      default:
        return 'Once buyers place orders, they will appear here.';
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Group + group header
// ────────────────────────────────────────────────────────────────────────────

class _OrderGroup {
  final String label;
  final List<OrderModel> orders;

  const _OrderGroup({required this.label, required this.orders});
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: cs.onSurface.withValues(alpha: 0.55),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// History row
// ────────────────────────────────────────────────────────────────────────────

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final created = order.createdAt.toDate().toLocal();
    final relativeLabel = _relativeLabel(created);
    final priceLabel = NumberFormat.currency(symbol: '₱', decimalDigits: 2)
        .format(order.totalPrice);

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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(orderViewModelProvider.notifier).selectOrder(order.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderHistoryDetailsView(orderId: order.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderId}',
                        style: tt.titleSmall?.copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusBadge(status: order.status),
                          StatusBadge(
                            status: order.isPaid
                                ? StatusConstants.paid
                                : StatusConstants.unpaid,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        relativeLabel,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceLabel,
                      style: tt.titleSmall?.copyWith(color: cs.primary),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.35),
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

  String _relativeLabel(DateTime created) {
    final now = DateTime.now();
    final diff = now.difference(created);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inDays < 1) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    return DateFormat('MMM d, y').format(created);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Status filter chips
// ────────────────────────────────────────────────────────────────────────────

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (final status in filters) ...[
            ChoiceChip(
              label: Text(status),
              selected: selected == status,
              onSelected: (_) => onSelected(status),
              showCheckmark: false,
              selectedColor: cs.primary.withValues(alpha: 0.14),
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: selected == status
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected == status
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            if (status != filters.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
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
              "Couldn't load order history",
              style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
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
