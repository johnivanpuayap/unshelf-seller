import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/status_badge.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/views/order_history_details_view.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<OrderViewModel>(context, listen: false);
      viewModel.fetchOrdersHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = Provider.of<OrderViewModel>(context);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Order History',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Column(
        children: [
          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: AppTheme.spacing8),
                // Filter PopupMenuButton
                PopupMenuButton<String>(
                  onSelected: (value) {
                    viewModel.currentStatus = value;
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      'All',
                      'Pending',
                      'Processing',
                      'Ready',
                      'Completed',
                      'Cancelled'
                    ].map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, size: 20),
                        const SizedBox(width: AppTheme.spacing4),
                        Text(
                          viewModel.currentStatus,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // Sort Order PopupMenuButton
                PopupMenuButton<String>(
                  onSelected: (value) {
                    viewModel.sortOrder = value;
                  },
                  itemBuilder: (BuildContext context) {
                    return ['Ascending', 'Descending'].map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing8),
                    child: Row(
                      children: [
                        const Icon(Icons.sort, size: 20),
                        const SizedBox(width: AppTheme.spacing4),
                        Text(
                          viewModel.sortOrder,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: Consumer<OrderViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredOrders = viewModel.filteredOrders;

                if (filteredOrders.isEmpty) {
                  final statusMessages = {
                    'Pending': 'No pending orders',
                    'Processing': 'No orders in processing.',
                    'Ready': 'No orders that are ready',
                    'Completed': 'No completed orders.',
                    'Cancelled': 'No cancelled orders',
                  };

                  String message = statusMessages[viewModel.currentStatus] ??
                      'No orders found.';
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: message,
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final isAlternate = index % 2 == 0;

                    return InkWell(
                      onTap: () {
                        viewModel.selectOrder(order.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderHistoryDetailsView(orderId: order.id),
                          ),
                        );
                      },
                      child: Container(
                        color: isAlternate
                            ? AppColors.surface
                            : theme.colorScheme.surface,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacing8,
                          horizontal: AppTheme.spacing16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacing16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order ID: ${order.orderId}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacing4),
                                    Text(
                                      order.createdAt
                                          .toDate()
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: AppTheme.spacing4),
                                    StatusBadge(status: order.status),
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\u20B1 ${order.totalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacing8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppTheme.spacing4,
                                    horizontal: AppTheme.spacing12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: order.isPaid
                                        ? AppColors.primaryColor
                                        : AppColors.error,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    order.isPaid ? 'Paid' : 'Unpaid',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
