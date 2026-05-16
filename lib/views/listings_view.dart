import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/product_card.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/viewmodels/listing_viewmodel.dart';
import 'package:unshelf_seller/views/add_product_view.dart';
import 'package:unshelf_seller/views/bundle_details_view.dart';
import 'package:unshelf_seller/views/edit_bundle_view.dart';
import 'package:unshelf_seller/views/edit_product_view.dart';
import 'package:unshelf_seller/views/product_details_view.dart';
import 'package:unshelf_seller/views/select_products_view.dart';

/// Seller-side listings catalogue (products + bundles).
///
/// Full-width layout (no AppBar — this is a tab body in HomeView):
/// • Header with title + count + "Add" CTA
/// • Search field
/// • Filter chips (All / Products / Bundles)
/// • Vertical list of [ProductCard] entries
class ListingsView extends ConsumerStatefulWidget {
  const ListingsView({super.key});

  @override
  ConsumerState<ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends ConsumerState<ListingsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(listingViewModelProvider.notifier).fetchItems();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref
        .read(listingViewModelProvider.notifier)
        .updateSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingViewModelProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () =>
            ref.read(listingViewModelProvider.notifier).fetchItems(),
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    count: state.filteredItems.length,
                    onAdd: () => _showAddItemSheet(context),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(controller: _searchController),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
                sliver: SliverToBoxAdapter(child: _FilterChips()),
              ),
              if (state.isLoading && state.items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null && state.items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ListingsError(
                    message: state.errorMessage!,
                    onRetry: () => ref
                        .read(listingViewModelProvider.notifier)
                        .fetchItems(),
                  ),
                )
              else if (state.filteredItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, state.filter),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList.separated(
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.filteredItems[index];
                      return _buildProductCard(context, item);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    final String title;
    final String subtitle;

    switch (filter) {
      case 'Products':
        title = 'No products yet';
        subtitle = 'Add your first product to start selling.';
      case 'Bundles':
        title = 'No bundles yet';
        subtitle = 'Create a bundle to offer grouped discounts.';
      default:
        title = 'No listings yet';
        subtitle = 'Add your first product to start selling.';
    }

    return EmptyState(
      icon: Icons.storefront_outlined,
      title: title,
      subtitle: subtitle,
      actionLabel: 'Add product',
      onAction: () => _showAddItemSheet(context),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic item) {
    final isProduct = item is ProductModel;

    return ProductCard(
      name: item.name,
      imageUrl: item.mainImageUrl,
      category: item.category,
      onTap: () {
        if (item is BundleModel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BundleDetailsView(bundleId: item.id),
            ),
          );
        } else if (item is ProductModel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsView(productId: item.id),
            ),
          );
        }
      },
      onEdit: () {
        if (item is ProductModel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditProductView(
                product: item,
                onProductAdded: () {
                  ref.read(listingViewModelProvider.notifier).fetchItems();
                },
              ),
            ),
          );
        } else if (item is BundleModel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditBundleView(bundleId: item.id),
            ),
          );
        }
      },
      onDelete: () => _confirmDelete(context, item.id, isProduct),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String itemId,
    bool isProduct,
  ) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete this listing?',
            style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
          ),
          content: Text(
            "This can't be undone. Buyers will no longer see it on your store.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: theme.textTheme.labelLarge?.copyWith(color: cs.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(listingViewModelProvider.notifier)
          .deleteItem(itemId, isProduct);
    }
  }

  void _showAddItemSheet(BuildContext context) {
    final notifier = ref.read(listingViewModelProvider.notifier);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'What would you like to add?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _AddOptionTile(
                  icon: Icons.add_circle_outline,
                  title: 'Product',
                  description: 'A single item with batches and pricing.',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductView(
                          onProductAdded: () => notifier.fetchItems(),
                        ),
                      ),
                    );
                    notifier.fetchItems();
                  },
                ),
                const SizedBox(height: 8),
                _AddOptionTile(
                  icon: CupertinoIcons.gift,
                  title: 'Product bundle',
                  description:
                      'Group multiple products into a discounted pack.',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelectProductsView(),
                      ),
                    );
                    notifier.fetchItems();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Header
// ────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Listings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count ${count == 1 ? "item" : "items"} on your store',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Search field
// ────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search listings…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => controller.clear(),
                  ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Filter chips
// ────────────────────────────────────────────────────────────────────────────

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  static const _filters = ['All', 'Products', 'Bundles'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(listingViewModelProvider);
    final notifier = ref.read(listingViewModelProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (final label in _filters) ...[
            ChoiceChip(
              label: Text(label),
              selected: state.filter == label,
              onSelected: (_) => notifier.setFilter(label),
              showCheckmark: false,
              selectedColor: cs.primary.withValues(alpha: 0.14),
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: state.filter == label
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: state.filter == label
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            if (label != _filters.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Add-item bottom-sheet tile
// ────────────────────────────────────────────────────────────────────────────

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cs.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Error
// ────────────────────────────────────────────────────────────────────────────

class _ListingsError extends StatelessWidget {
  const _ListingsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text(
            "Couldn't load listings",
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
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
