import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/order_card.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/dashboard_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/store_viewmodel.dart';
import 'package:unshelf_seller/views/add_product_view.dart';
import 'package:unshelf_seller/views/inventory_view.dart';
import 'package:unshelf_seller/views/order_details_view.dart';
import 'package:unshelf_seller/views/orders_view.dart';
import 'package:unshelf_seller/views/store_analytics_view.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider.notifier).fetchDashboardData();
      ref.read(orderViewModelProvider.notifier).fetchOrders();
      ref.read(storeViewModelProvider.notifier).fetchStoreDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final orderState = ref.watch(orderViewModelProvider);
    final storeVM = ref.watch(storeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                await Future.wait([
                  ref
                      .read(dashboardViewModelProvider.notifier)
                      .fetchDashboardData(),
                  ref.read(orderViewModelProvider.notifier).fetchOrders(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Welcome section ---
                    _buildWelcomeSection(theme, storeVM),
                    const SizedBox(height: AppTheme.spacing24),

                    // --- KPI Stats Grid ---
                    _buildKpiGrid(theme, dashboardState),
                    const SizedBox(height: AppTheme.spacing32),

                    // --- Recent Orders ---
                    _buildRecentOrdersSection(theme, orderState),
                    const SizedBox(height: AppTheme.spacing32),

                    // --- Quick Actions ---
                    _buildQuickActionsSection(theme),
                    const SizedBox(height: AppTheme.spacing16),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Welcome greeting ───
  Widget _buildWelcomeSection(ThemeData theme, StoreState storeVM) {
    final storeName = storeVM.storeDetails?.storeName ?? 'Seller';
    final greeting = _getGreeting();
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $storeName',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          today,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── KPI 2x2 grid ───
  Widget _buildKpiGrid(ThemeData theme, DashboardState state) {
    final earningsFormatted = NumberFormat.currency(
      symbol: '\u20B1',
      decimalDigits: 2,
    ).format(state.totalSales);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: "Today's Orders",
                value: state.totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: StatCard(
                label: 'Pending',
                value: state.pendingOrders.toString(),
                icon: Icons.pending_actions_outlined,
                iconColor: AppColors.statusPendingText,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: "Monthly Earnings",
                value: earningsFormatted,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: StatCard(
                label: 'Completed',
                value: state.completedOrders.toString(),
                icon: Icons.check_circle_outline,
                iconColor: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Recent orders section ───
  Widget _buildRecentOrdersSection(ThemeData theme, OrderState orderState) {
    // Take the latest 5 orders sorted by date descending
    final recentOrders = orderState.orders.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final displayOrders = recentOrders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Orders',
          actionLabel: 'See all',
          onAction: () {
            // Navigate to orders tab — parent HomeView manages tabs,
            // so push directly to OrdersView as a standalone page.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrdersView()),
            );
          },
        ),
        if (orderState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing24),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          )
        else if (displayOrders.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders today',
            subtitle: 'New orders will appear here as they come in.',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: displayOrders.length,
            itemBuilder: (context, index) {
              final order = displayOrders[index];
              return OrderCard(
                orderId: order.orderId,
                buyerName: order.buyerName,
                status: order.status,
                totalPrice: order.totalPrice,
                createdAt: order.createdAt.toDate(),
                itemCount: order.items.length,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderDetailsView(orderId: order.id),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // ─── Quick actions section ───
  Widget _buildQuickActionsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: AppTheme.spacing4),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: [
            _QuickActionChip(
              icon: Icons.add_box_outlined,
              label: 'Add Product',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductView(
                      onProductAdded: () => Navigator.pop(context),
                    ),
                  ),
                );
              },
            ),
            _QuickActionChip(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryView(),
                  ),
                );
              },
            ),
            _QuickActionChip(
              icon: Icons.bar_chart_outlined,
              label: 'Analytics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoreAnalyticsView(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // ─── Time-based greeting ───
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

/// A compact action chip with an icon and label.
/// Uses InkWell for proper tap feedback (rule: press-feedback).
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      elevation: AppTheme.elevationLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
