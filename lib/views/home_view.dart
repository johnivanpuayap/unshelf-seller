import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:unshelf_seller/components/chat_screen.dart';
import 'package:unshelf_seller/viewmodels/home_viewmodel.dart';
import 'package:unshelf_seller/views/dashboard_view.dart';
import 'package:unshelf_seller/views/listings_view.dart';
import 'package:unshelf_seller/views/notifications_view.dart';
import 'package:unshelf_seller/views/orders_view.dart';
import 'package:unshelf_seller/views/store_view.dart';

/// Bottom-nav shell for the seller app.
///
/// Thin: hosts the top app bar (store logo + chat + notifications) and the
/// bottom nav. Each tab body owns its own scaffold-level content.
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    DashboardView(),
    OrdersView(),
    ListingsView(),
    StoreView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final unseenCount = ref.watch(
      homeViewModelProvider.select((s) => s.unseenCount),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logos/logo-wordmark.svg',
              height: 28,
              semanticsLabel: 'Unshelf',
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen()),
            ),
            icon: const Icon(Icons.chat_outlined),
            color: cs.onSurface.withValues(alpha: 0.65),
            tooltip: 'Chat',
            iconSize: 24,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsView(),
                  ),
                ),
                icon: const Icon(Icons.notifications_outlined),
                color: cs.onSurface.withValues(alpha: 0.65),
                tooltip: 'Notifications',
                iconSize: 24,
              ),
              if (unseenCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cs.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: _screens[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withValues(alpha: 0.55),
        selectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          color: cs.primary,
        ),
        unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.55),
        ),
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Store',
          ),
        ],
      ),
    );
  }
}
