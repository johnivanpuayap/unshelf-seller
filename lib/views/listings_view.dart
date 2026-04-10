import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/product_card.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/listing_viewmodel.dart';
import 'package:unshelf_seller/views/add_product_view.dart';
import 'package:unshelf_seller/views/bundle_details_view.dart';
import 'package:unshelf_seller/views/edit_bundle_view.dart';
import 'package:unshelf_seller/views/edit_product_view.dart';
import 'package:unshelf_seller/views/product_details_view.dart';
import 'package:unshelf_seller/views/select_products_view.dart';

class ListingsView extends StatefulWidget {
  const ListingsView({super.key});

  @override
  State<ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends State<ListingsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<ListingViewModel>(context, listen: false)
        .updateSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            onClear: () {
              _searchController.clear();
              _onSearchChanged();
            },
          ),
          _FilterRow(),
          Expanded(
            child: Consumer<ListingViewModel>(
              builder: (context, viewModel, _) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (viewModel.filteredItems.isEmpty) {
                  return _buildEmptyState(context, viewModel.filter);
                }

                return RefreshIndicator(
                  onRefresh: () => viewModel.fetchItems(),
                  color: AppColors.primaryColor,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    itemCount: viewModel.filteredItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacing8),
                    itemBuilder: (context, index) {
                      final item = viewModel.filteredItems[index];
                      return _buildProductCard(context, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
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
      actionLabel: 'Add Product',
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
                  Provider.of<ListingViewModel>(context, listen: false)
                      .fetchItems();
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await Provider.of<ListingViewModel>(context, listen: false)
          .deleteItem(itemId, isProduct);
    }
  }

  void _showAddItemSheet(BuildContext context) {
    final viewModel = Provider.of<ListingViewModel>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacing24,
              right: AppTheme.spacing24,
              bottom: AppTheme.spacing24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: AppTheme.spacing12,
                      bottom: AppTheme.spacing24,
                    ),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),

                Text(
                  'What would you like to add?',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppTheme.spacing16),

                // Add Product option
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
                          onProductAdded: () => viewModel.fetchItems(),
                        ),
                      ),
                    );
                    viewModel.fetchItems();
                  },
                ),
                const SizedBox(height: AppTheme.spacing8),

                // Add Bundle option
                _AddOptionTile(
                  icon: CupertinoIcons.gift,
                  title: 'Product Bundle',
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
                    viewModel.fetchItems();
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

// ─── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: SizedBox(
        height: AppTheme.minTouchTarget,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextField(
              controller: controller,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search listings...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(
                    color: AppColors.primaryColor,
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Filter Row ─────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  static const _filters = ['All', 'Products', 'Bundles'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ListingViewModel>(
      builder: (context, viewModel, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppTheme.spacing8,
                  children: _filters.map((label) {
                    final selected = viewModel.filter == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) => viewModel.setFilter(label),
                      selectedColor:
                          AppColors.primaryColor.withValues(alpha: 0.15),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: selected
                            ? AppColors.primaryColor
                            : AppColors.textSecondary,
                      ),
                      showCheckmark: false,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
              Text(
                '(${viewModel.filteredItems.length} '
                '${viewModel.filteredItems.length == 1 ? 'item' : 'items'})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Add Option Tile ────────────────────────────────────────────────────────

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

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing8,
          vertical: AppTheme.spacing12,
        ),
        child: Row(
          children: [
            Container(
              width: AppTheme.spacing48,
              height: AppTheme.spacing48,
              decoration: BoxDecoration(
                color: AppColors.lightColor,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: AppColors.primaryColor),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
