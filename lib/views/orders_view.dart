import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/order_card.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/views/order_details_view.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
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
      Provider.of<OrderViewModel>(context, listen: false).fetchOrders();
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
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, _) {
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
                final isSelected = viewModel.currentStatus == status;

                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacing8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (_) {
                      viewModel.currentStatus = status;
                      viewModel.filterOrdersByStatus(status);
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
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
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
      },
    );
  }

  // ─── Sort toggle ────────────────────────────────────────────────────────

  Widget _buildSortToggle(ThemeData theme) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, _) {
        final isLatestFirst = viewModel.sortOrder == 'Descending';

        return InkWell(
          onTap: () {
            viewModel.sortOrder = isLatestFirst ? 'Ascending' : 'Descending';
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing8,
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
        );
      },
    );
  }

  // ─── Order list ─────────────────────────────────────────────────────────

  Widget _buildOrderList(ThemeData theme) {
    return Consumer<OrderViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = viewModel.filteredOrders;

        if (orders.isEmpty) {
          return _buildEmptyState(viewModel.currentStatus);
        }

        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: viewModel.fetchOrders,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing8,
            ),
            itemCount: orders.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.spacing4),
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
                  viewModel.selectOrder(order.id);
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
      },
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
