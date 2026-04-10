import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:unshelf_seller/components/chat_screen.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/views/dashboard_view.dart';
import 'package:unshelf_seller/views/orders_view.dart';
import 'package:unshelf_seller/views/listings_view.dart';
import 'package:unshelf_seller/views/store_view.dart';
import 'package:unshelf_seller/views/notifications_view.dart';
import 'package:unshelf_seller/viewmodels/home_viewmodel.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardView(),
    const OrdersView(),
    ListingsView(),
    const StoreView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: AppTheme.elevationNone,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: AppTheme.spacing16,
        title: Text(
          'Unshelf Seller',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Chat icon
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen()),
              );
            },
            icon: const Icon(Icons.chat_outlined),
            color: AppColors.textSecondary,
            tooltip: 'Chat',
            iconSize: 24,
            constraints: const BoxConstraints(
              minWidth: AppTheme.minTouchTarget,
              minHeight: AppTheme.minTouchTarget,
            ),
          ),
          // Notification bell with red dot
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsView(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textSecondary,
                tooltip: 'Notifications',
                iconSize: 24,
                constraints: const BoxConstraints(
                  minWidth: AppTheme.minTouchTarget,
                  minHeight: AppTheme.minTouchTarget,
                ),
              ),
              if (viewModel.unseenCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppTheme.spacing8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: AppTheme.elevationHigh,
        shadowColor: Colors.black26,
        indicatorColor: AppColors.primaryColor.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primaryColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long, color: AppColors.primaryColor),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon:
                Icon(Icons.inventory_2, color: AppColors.primaryColor),
            label: 'Listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: AppColors.primaryColor),
            label: 'Store',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
