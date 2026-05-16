import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/order_card.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/inventory_product_model.dart';
import 'package:unshelf_seller/viewmodels/dashboard_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/inventory_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/order_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/store_viewmodel.dart';
import 'package:unshelf_seller/views/add_product_view.dart';
import 'package:unshelf_seller/views/inventory_view.dart';
import 'package:unshelf_seller/views/order_details_view.dart';
import 'package:unshelf_seller/views/orders_view.dart';
import 'package:unshelf_seller/views/store_analytics_view.dart';

/// Seller-led admin dashboard.
///
/// Layout (per plan 2026-05-16-seller-rebrand-implementation lines 1356–1364):
/// • Hero stats row — 4 KPI cards
/// • Today's orders — horizontal scroll of OrderCards
/// • Expiring batches — vertical list of batches with urgency badges
/// • Low stock — 3–5 product rows
/// • Quick actions — Add product / Inventory / Analytics
///
/// Bottom nav is owned by [HomeView]; this view is the body of tab 0.
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
      ref.read(inventoryViewModelProvider.notifier).fetchInventory();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(dashboardViewModelProvider.notifier).fetchDashboardData(),
      ref.read(orderViewModelProvider.notifier).fetchOrders(),
      ref.read(inventoryViewModelProvider.notifier).fetchInventory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final orderState = ref.watch(orderViewModelProvider);
    final storeState = ref.watch(storeViewModelProvider);
    final inventoryState = ref.watch(inventoryViewModelProvider);

    if (dashboardState.isLoading && dashboardState.totalOrders == 0) {
      return const Center(child: CircularProgressIndicator());
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
              _Greeting(storeName: storeState.storeDetails?.storeName),
              const SizedBox(height: 24),
              _HeroStats(
                dashboardState: dashboardState,
                orderState: orderState,
                inventoryState: inventoryState,
              ),
              const SizedBox(height: 32),
              _TodaysOrdersSection(orderState: orderState),
              const SizedBox(height: 32),
              _ExpiringBatchesSection(inventoryState: inventoryState),
              const SizedBox(height: 32),
              _LowStockSection(inventoryState: inventoryState),
              const SizedBox(height: 32),
              const _QuickActionsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Greeting header
// ────────────────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  const _Greeting({this.storeName});

  final String? storeName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final name = (storeName == null || storeName!.isEmpty) ? 'Seller' : storeName!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: theme.textTheme.headlineMedium?.copyWith(color: cs.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          today,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hero stats — 2x2 grid (revenue / orders / items sold / low stock)
// ────────────────────────────────────────────────────────────────────────────

class _HeroStats extends StatelessWidget {
  const _HeroStats({
    required this.dashboardState,
    required this.orderState,
    required this.inventoryState,
  });

  final DashboardState dashboardState;
  final OrderState orderState;
  final InventoryState inventoryState;

  @override
  Widget build(BuildContext context) {
    final earnings = NumberFormat.currency(symbol: '₱', decimalDigits: 0)
        .format(dashboardState.totalSales);

    // Derive "items sold today" locally from today's completed orders so we
    // don't fabricate a field the viewmodel doesn't expose.
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final itemsSoldToday = orderState.orders.where((o) {
      final created = o.createdAt.toDate();
      return created.isAfter(startOfDay) || created.isAtSameMomentAs(startOfDay);
    }).fold<int>(0, (sum, o) => sum + o.items.fold<int>(0, (s, i) => s + i.quantity));

    final lowStockCount = _lowStock(inventoryState.inventoryItems).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: "Today's revenue",
                value: earnings,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                label: 'Orders today',
                value: dashboardState.totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Items sold',
                value: itemsSoldToday.toString(),
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatCard(
                label: 'Low stock',
                value: lowStockCount.toString(),
                icon: Icons.inventory_2_outlined,
                iconColor: lowStockCount > 0
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Today's orders — horizontal scroll
// ────────────────────────────────────────────────────────────────────────────

class _TodaysOrdersSection extends StatelessWidget {
  const _TodaysOrdersSection({required this.orderState});

  final OrderState orderState;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final todaysOrders = orderState.orders
        .where((o) {
          final created = o.createdAt.toDate();
          return !created.isBefore(startOfDay);
        })
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final display = todaysOrders.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Today's orders",
          actionLabel: 'See all',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdersView()),
          ),
        ),
        if (orderState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (orderState.errorMessage != null)
          _InlineError(
            message: orderState.errorMessage!,
            onRetry: () =>
                ProviderScope.containerOf(context, listen: false)
                    .read(orderViewModelProvider.notifier)
                    .fetchOrders(),
          )
        else if (display.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders today',
            subtitle: 'New orders will appear here as they come in.',
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: display.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final order = display[index];
                return SizedBox(
                  width: 280,
                  child: OrderCard(
                    orderId: order.orderId,
                    buyerName: order.buyerName,
                    status: order.status,
                    totalPrice: order.totalPrice,
                    createdAt: order.createdAt.toDate(),
                    itemCount: order.items.length,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsView(orderId: order.id),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Expiring batches — vertical list of cards with urgency badges
// ────────────────────────────────────────────────────────────────────────────

class _ExpiringBatchesSection extends ConsumerWidget {
  const _ExpiringBatchesSection({required this.inventoryState});

  final InventoryState inventoryState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiring = _expiringBatches(inventoryState.inventoryItems).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Expiring batches',
          actionLabel: 'Inventory',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryView()),
          ),
        ),
        if (inventoryState.isLoading && inventoryState.inventoryItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (inventoryState.errorMessage != null)
          _InlineError(
            message: inventoryState.errorMessage!,
            onRetry: () => ref
                .read(inventoryViewModelProvider.notifier)
                .fetchInventory(),
          )
        else if (expiring.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Nothing expiring soon',
            subtitle: 'All batches are well within their expiry window.',
          )
        else
          Column(
            children: [
              for (final entry in expiring) ...[
                _BatchRow(
                  productName: entry.productName,
                  imageUrl: entry.imageUrl,
                  batch: entry.batch,
                ),
                if (entry != expiring.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({
    required this.productName,
    required this.imageUrl,
    required this.batch,
  });

  final String productName;
  final String imageUrl;
  final BatchModel batch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final daysLeft = batch.expiryDate.difference(DateTime.now()).inDays;
    final urgency = _urgencyFor(daysLeft);
    final dateLabel = DateFormat('MMM d').format(batch.expiryDate);

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ProductThumb(imageUrl: imageUrl, size: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${batch.stock} ${batch.quantifier} • expires $dateLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _UrgencyBadge(label: urgency.label, color: urgency.color(cs)),
        ],
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl, required this.size});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (imageUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: cs.surface,
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      );
    }
    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: cs.surface,
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Low stock — 3-5 product rows
// ────────────────────────────────────────────────────────────────────────────

class _LowStockSection extends ConsumerWidget {
  const _LowStockSection({required this.inventoryState});

  final InventoryState inventoryState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = _lowStock(inventoryState.inventoryItems).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Low stock',
          actionLabel: 'Inventory',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InventoryView()),
          ),
        ),
        if (inventoryState.isLoading && inventoryState.inventoryItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (inventoryState.errorMessage != null)
          _InlineError(
            message: inventoryState.errorMessage!,
            onRetry: () => ref
                .read(inventoryViewModelProvider.notifier)
                .fetchInventory(),
          )
        else if (lowStock.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Stock levels look healthy',
            subtitle: 'No products are running low right now.',
          )
        else
          Column(
            children: [
              for (final product in lowStock) ...[
                _LowStockRow(product: product),
                if (product != lowStock.last) const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product});

  final InventoryProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalStock =
        product.batches.fold<int>(0, (sum, b) => sum + b.stock);
    final quantifier = product.batches.isNotEmpty
        ? product.batches.first.quantifier
        : '';

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
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _ProductThumb(imageUrl: product.mainImageUrl, size: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalStock $quantifier left',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.error,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InventoryView(),
              ),
            ),
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Quick actions — 3 outlined pill buttons
// ────────────────────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick actions'),
        const SizedBox(height: 4),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddProductView(
                  onProductAdded: () => Navigator.pop(context),
                ),
              ),
            ),
            icon: const Icon(Icons.add_box_outlined, size: 20),
            label: const Text('Add product'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryView()),
            ),
            icon: const Icon(Icons.inventory_2_outlined, size: 20),
            label: const Text('Manage inventory'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreAnalyticsView()),
            ),
            icon: const Icon(Icons.bar_chart_outlined, size: 20),
            label: const Text('View analytics'),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Inline error widget
// ────────────────────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 32, color: cs.error),
          const SizedBox(height: 8),
          Text(
            "Couldn't load this section",
            style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Pure helpers
// ────────────────────────────────────────────────────────────────────────────

class _UrgencyTone {
  const _UrgencyTone(this.label, this._kind);
  final String label;
  final _UrgencyKind _kind;

  Color color(ColorScheme cs) {
    switch (_kind) {
      case _UrgencyKind.danger:
        return cs.error;
      case _UrgencyKind.warning:
        return cs.tertiary;
      case _UrgencyKind.calm:
        return cs.primary;
    }
  }
}

enum _UrgencyKind { danger, warning, calm }

_UrgencyTone _urgencyFor(int daysLeft) {
  if (daysLeft <= 1) return const _UrgencyTone('1 day', _UrgencyKind.danger);
  if (daysLeft <= 3) {
    return _UrgencyTone('$daysLeft days', _UrgencyKind.danger);
  }
  if (daysLeft <= 7) {
    return _UrgencyTone('$daysLeft days', _UrgencyKind.warning);
  }
  return _UrgencyTone('$daysLeft days', _UrgencyKind.calm);
}

class _ExpiringEntry {
  const _ExpiringEntry({
    required this.productName,
    required this.imageUrl,
    required this.batch,
  });
  final String productName;
  final String imageUrl;
  final BatchModel batch;
}

/// Flatten inventory into batch rows, keep those expiring in <= 7 days,
/// sort soonest first.
List<_ExpiringEntry> _expiringBatches(List<InventoryProductModel> items) {
  final now = DateTime.now();
  final cutoff = now.add(const Duration(days: 7));
  final entries = <_ExpiringEntry>[];
  for (final p in items) {
    for (final b in p.batches) {
      if (b.expiryDate.isBefore(cutoff) && b.stock > 0) {
        entries.add(_ExpiringEntry(
          productName: p.name,
          imageUrl: p.mainImageUrl,
          batch: b,
        ));
      }
    }
  }
  entries.sort((a, b) => a.batch.expiryDate.compareTo(b.batch.expiryDate));
  return entries;
}

/// Products whose combined batch stock is at or below the low-stock threshold.
List<InventoryProductModel> _lowStock(List<InventoryProductModel> items) {
  const threshold = 5;
  final list = items.where((p) {
    final total = p.batches.fold<int>(0, (sum, b) => sum + b.stock);
    return total > 0 && total <= threshold;
  }).toList();
  list.sort((a, b) {
    final aTotal = a.batches.fold<int>(0, (s, x) => s + x.stock);
    final bTotal = b.batches.fold<int>(0, (s, x) => s + x.stock);
    return aTotal.compareTo(bTotal);
  });
  return list;
}
