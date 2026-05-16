import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/order_card.dart';
import 'package:unshelf_seller/core/constants/status_constants.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/views/order_details_view.dart';

/// Seller-side orders list.
///
/// Layout: top filter chips (All / Pending / Processing / Ready / Completed /
/// Cancelled) + a sort toggle (Latest / Oldest first), then a full-width
/// list of [OrderCard]s. Pull-to-refresh. Tap → [OrderDetailsView].
class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  static const _statusFilters = <String>[
    'All',
    StatusConstants.pending,
    StatusConstants.processing,
    StatusConstants.ready,
    StatusConstants.completed,
    StatusConstants.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderViewModelProvider.notifier).fetchOrders();
    });
  }

  Future<void> _refresh() =>
      ref.read(orderViewModelProvider.notifier).fetchOrders();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final state = ref.watch(orderViewModelProvider);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      appBar: canPop
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Orders',
                style: tt.titleLarge?.copyWith(color: cs.onSurface),
              ),
              centerTitle: false,
            )
          : null,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _refresh,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: _SortToggle(
                    sortOrder: state.sortOrder,
                    onToggle: () {
                      ref.read(orderViewModelProvider.notifier).sortOrder =
                          state.sortOrder == 'Descending'
                              ? 'Ascending'
                              : 'Descending';
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
                  child: _OrdersError(
                    message: state.errorMessage!,
                    onRetry: _refresh,
                  ),
                )
              else if (state.filteredOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(state.currentStatus),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  sliver: SliverList.separated(
                    itemCount: state.filteredOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final order = state.filteredOrders[index];
                      return OrderCard(
                        orderId: order.orderId,
                        buyerName: order.buyerName,
                        status: order.status,
                        totalPrice: order.totalPrice,
                        createdAt: order.createdAt.toDate().toLocal(),
                        itemCount: order.items.length,
                        onTap: () {
                          ref
                              .read(orderViewModelProvider.notifier)
                              .selectOrder(order.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailsView(orderId: order.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String status) {
    final config = _emptyConfig(status);
    return EmptyState(
      icon: config.icon,
      title: config.title,
      subtitle: config.subtitle,
    );
  }

  _EmptyConfig _emptyConfig(String status) {
    switch (status) {
      case StatusConstants.pending:
        return const _EmptyConfig(
          icon: Icons.hourglass_empty_rounded,
          title: 'No pending orders',
          subtitle: 'New orders from buyers will appear here.',
        );
      case StatusConstants.processing:
        return const _EmptyConfig(
          icon: Icons.sync_rounded,
          title: 'No orders in processing',
          subtitle: 'Approved orders being prepared will show up here.',
        );
      case StatusConstants.ready:
        return const _EmptyConfig(
          icon: Icons.check_circle_outline_rounded,
          title: 'No orders ready',
          subtitle: 'Orders ready for pickup will appear here.',
        );
      case StatusConstants.completed:
        return const _EmptyConfig(
          icon: Icons.done_all_rounded,
          title: 'No completed orders',
          subtitle: 'Fulfilled orders will be listed here.',
        );
      case StatusConstants.cancelled:
        return const _EmptyConfig(
          icon: Icons.cancel_outlined,
          title: 'No cancelled orders',
          subtitle: 'Cancelled orders will appear here.',
        );
      default:
        return const _EmptyConfig(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          subtitle: 'Orders from buyers will show up here.',
        );
    }
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
// Sort toggle
// ────────────────────────────────────────────────────────────────────────────

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.sortOrder, required this.onToggle});

  final String sortOrder;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLatestFirst = sortOrder == 'Descending';

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLatestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              Text(
                isLatestFirst ? 'Latest first' : 'Oldest first',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Error
// ────────────────────────────────────────────────────────────────────────────

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

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
              "Couldn't load orders",
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

class _EmptyConfig {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
