import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/models/store_model.dart';
import 'package:unshelf_seller/viewmodels/analytics_viewmodel.dart';
import 'package:unshelf_seller/viewmodels/store_viewmodel.dart';

import 'package:unshelf_seller/authentication/views/login_view.dart';
import 'package:unshelf_seller/views/balance_overview_view.dart';
import 'package:unshelf_seller/views/edit_store_location_view.dart';
import 'package:unshelf_seller/views/edit_store_profile_view.dart';
import 'package:unshelf_seller/views/edit_store_schedule_view.dart';
import 'package:unshelf_seller/views/edit_user_profile_view.dart';
import 'package:unshelf_seller/views/inventory_view.dart';
import 'package:unshelf_seller/views/order_history_view.dart';
import 'package:unshelf_seller/views/product_analytics_view.dart';
import 'package:unshelf_seller/views/report_view.dart';
import 'package:unshelf_seller/views/settings_view.dart';
import 'package:unshelf_seller/views/store_analytics_view.dart';

/// Seller store profile screen.
///
/// Layout: full-bleed cover hero with overlapping avatar → name + rating row →
/// KPI row (revenue / followers / orders / rating) → "Store management" action
/// tiles → "Account" action tiles → sign-out button.
class StoreView extends ConsumerStatefulWidget {
  const StoreView({super.key});

  @override
  ConsumerState<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends ConsumerState<StoreView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(storeViewModelProvider.notifier);
      notifier.fetchStoreDetails();
      notifier.fetchUserProfile();
      ref.read(analyticsViewModelProvider.notifier).fetchAnalyticsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storeViewModelProvider);
    final analytics = ref.watch(analyticsViewModelProvider);
    final cs = Theme.of(context).colorScheme;

    if (state.isLoading ||
        state.storeDetails == null ||
        state.userProfile == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    final store = state.storeDetails!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(store: store),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _KpiRow(store: store, analytics: analytics),
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _SectionLabel('Store management'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ActionTiles(
                  tiles: [
                    _TileSpec(
                      icon: Icons.edit_outlined,
                      label: 'Edit profile',
                      onTap: () => _push(EditStoreProfileView(
                        storeDetails: store,
                      )),
                    ),
                    _TileSpec(
                      icon: Icons.access_time_rounded,
                      label: 'Manage schedule',
                      onTap: () => _push(EditStoreScheduleView(
                        storeDetails: store,
                      )),
                    ),
                    _TileSpec(
                      icon: Icons.location_on_outlined,
                      label: 'Manage location',
                      onTap: () => _push(EditStoreLocationView(
                        storeDetails: store,
                      )),
                    ),
                    _TileSpec(
                      icon: Icons.bar_chart_outlined,
                      label: 'Store analytics',
                      onTap: () => _push(const StoreAnalyticsView()),
                    ),
                    _TileSpec(
                      icon: Icons.insights_outlined,
                      label: 'Product analytics',
                      onTap: () => _push(const ProductAnalyticsView()),
                    ),
                    _TileSpec(
                      icon: Icons.receipt_long_outlined,
                      label: 'Order history',
                      onTap: () => _push(const OrderHistoryView()),
                    ),
                    _TileSpec(
                      icon: Icons.inventory_2_outlined,
                      label: 'Inventory',
                      onTap: () => _push(const InventoryView()),
                    ),
                    _TileSpec(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Wallet',
                      onTap: () => _push(const BalanceOverviewView()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _SectionLabel('Account'),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ActionTiles(
                  tiles: [
                    _TileSpec(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit profile',
                      onTap: () => _push(EditUserProfileView(
                        userProfile: state.userProfile!,
                      )),
                    ),
                    _TileSpec(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _push(const SettingsView()),
                    ),
                    _TileSpec(
                      icon: Icons.flag_outlined,
                      label: 'Report an issue',
                      onTap: () => _push(ReportFormView()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      'Sign out',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.error,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hero — cover band + overlapping avatar + name + rating row
// ────────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero({required this.store});

  final StoreModel store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final rating = store.storeRating ?? 0.0;
    final followers = store.storeFollowers ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover band — primary tint, rounded bottom corners.
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withValues(alpha: 0.18),
                  cs.tertiary.withValues(alpha: 0.16),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -20,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  bottom: 20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.tertiary.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Avatar — overlaps the bottom of the cover band.
        Positioned(
          left: 24,
          top: 144,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F2A20).withValues(alpha: .12),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: (store.storeImageUrl != null &&
                      store.storeImageUrl!.isNotEmpty)
                  ? NetworkImage(store.storeImageUrl!)
                  : null,
              child: (store.storeImageUrl == null ||
                      store.storeImageUrl!.isEmpty)
                  ? Icon(
                      Icons.storefront_outlined,
                      size: 36,
                      color: cs.primary,
                    )
                  : null,
            ),
          ),
        ),
        // Title + meta row — positioned below the cover.
        Padding(
          padding: const EdgeInsets.only(top: 240),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName.isNotEmpty ? store.storeName : 'My store',
                  style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$followers ${followers == 1 ? 'follower' : 'followers'}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (store.storeAddress != null &&
                    store.storeAddress!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          store.storeAddress!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// KPI row — lifetime revenue / orders / rating / followers
// ────────────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.store, required this.analytics});

  final StoreModel store;
  final AnalyticsState analytics;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Lifetime revenue',
                value: money.format(analytics.totalSales),
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Orders',
                value: analytics.totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Rating',
                value: (store.storeRating ?? 0.0).toStringAsFixed(1),
                icon: Icons.star_outline_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Followers',
                value: (store.storeFollowers ?? 0).toString(),
                icon: Icons.favorite_outline_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Section label — small uppercase eyebrow
// ────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: cs.onSurface.withValues(alpha: 0.55),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Action tiles — vertical stack of tappable rows on one shared card
// ────────────────────────────────────────────────────────────────────────────

class _TileSpec {
  const _TileSpec({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ActionTiles extends StatelessWidget {
  const _ActionTiles({required this.tiles});

  final List<_TileSpec> tiles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            _ActionTile(spec: tiles[i]),
            if (i < tiles.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: cs.onSurface.withValues(alpha: 0.06),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.spec});

  final _TileSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(spec.icon, size: 20, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  spec.label,
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
