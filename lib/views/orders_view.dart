import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/order_card.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/views/order_details_view.dart';

class OrdersView extends ConsumerStatefulWidget {
  const OrdersView({super.key});

  @override
  ConsumerState<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends ConsumerState<OrdersView> {
  static const _statusFilters = [
    'All',
    'Pending',
    'Processing',
    'Ready',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderViewModelProvider.notifier).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildFilterChips(theme),
          _buildSortToggle(theme),
          const Divider(height: 1),
          Expanded(child: _buildOrderList(theme)),
        ],
      ),
    );
  }

  // ─── Status filter chips ────────────────────────────────────────────────

  Widget _buildFilterChips(ThemeData theme) {
    final state = ref.watch(orderViewModelProvider);
    final notifier = ref.read(orderViewModelProvider.notifier);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((status) {
            final isSelected = state.currentStatus == status;

            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacing8),
              child: ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (_) {
                  notifier.currentStatus = status;
                  notifier.filterOrdersByStatus(status);
                },
                selectedColor: AppColors.primaryColor,
                backgroundColor: AppColors.surface,
                labelStyle: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                side: isSelected
                    ? BorderSide.none
                    : const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing4,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Sort toggle ────────────────────────────────────────────────────────

  Widget _buildSortToggle(ThemeData theme) {
    final state = ref.watch(orderViewModelProvider);
    final notifier = ref.read(orderViewModelProvider.notifier);
    final isLatestFirst = state.sortOrder == 'Descending';

    return SizedBox(
      height: AppTheme.minTouchTarget,
      child: InkWell(
        onTap: () {
          notifier.sortOrder = isLatestFirst ? 'Ascending' : 'Descending';
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLatestFirst
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                isLatestFirst ? 'Latest first' : 'Oldest first',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Order list ─────────────────────────────────────────────────────────

  Widget _buildOrderList(ThemeData theme) {
    final state = ref.watch(orderViewModelProvider);
    final notifier = ref.read(orderViewModelProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = state.filteredOrders;

    if (orders.isEmpty) {
      return _buildEmptyState(state.currentStatus);
    }

    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: notifier.fetchOrders,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing8,
        ),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacing4),
        itemBuilder: (context, index) {
          final order = orders[index];

          return OrderCard(
            orderId: order.orderId,
            buyerName: order.buyerName,
            status: order.status,
            totalPrice: order.totalPrice,
            createdAt: order.createdAt.toDate().toLocal(),
            itemCount: order.items.length,
            onTap: () {
              notifier.selectOrder(order.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsView(orderId: order.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Empty state per filter ─────────────────────────────────────────────

  Widget _buildEmptyState(String status) {
    final config = _emptyStateConfig(status);

    return EmptyState(
      icon: config.icon,
      title: config.title,
      subtitle: config.subtitle,
    );
  }

  _EmptyConfig _emptyStateConfig(String status) {
    switch (status) {
      case 'Pending':
        return const _EmptyConfig(
          icon: Icons.hourglass_empty_rounded,
          title: 'No pending orders',
          subtitle: 'New orders from buyers will appear here.',
        );
      case 'Processing':
        return const _EmptyConfig(
          icon: Icons.sync_rounded,
          title: 'No orders in processing',
          subtitle: 'Approved orders being prepared will show here.',
        );
      case 'Ready':
        return const _EmptyConfig(
          icon: Icons.check_circle_outline_rounded,
          title: 'No orders ready',
          subtitle: 'Orders ready for pickup will appear here.',
        );
      case 'Completed':
        return const _EmptyConfig(
          icon: Icons.done_all_rounded,
          title: 'No completed orders',
          subtitle: 'Fulfilled orders will be listed here.',
        );
      case 'Cancelled':
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
