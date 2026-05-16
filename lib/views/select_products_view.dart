import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/viewmodels/select_products_viewmodel.dart';
import 'package:unshelf_seller/views/add_bundle_view.dart';

/// Multi-select product picker for bundle composition.
///
/// Sticky search bar at top, scrollable list of selectable batches, sticky
/// bottom CTA "Add N products" that opens the bundle form.
class SelectProductsView extends ConsumerStatefulWidget {
  const SelectProductsView({super.key});

  @override
  ConsumerState<SelectProductsView> createState() =>
      _SelectProductsViewState();
}

class _SelectProductsViewState extends ConsumerState<SelectProductsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectProductsViewModelProvider.notifier).fetchAllBatches();
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
        .read(selectProductsViewModelProvider.notifier)
        .updateSearchQuery(_searchController.text);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onAdd(Map<String, BatchModel> selected) async {
    if (selected.length < 2) {
      _snack('Pick at least two products for a bundle.');
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBundleView(products: selected),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ref.read(selectProductsViewModelProvider.notifier).clearSelection();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectProductsViewModelProvider);
    final notifier = ref.read(selectProductsViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final selectedCount = state.selectedItems.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.clearSelection();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Pick products',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: _SearchField(controller: _searchController),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Long-press a tile to unselect.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SortMenu(
                    sortBy: state.sortBy,
                    onSelect: notifier.sortItems,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.errorMessage != null && state.items.isEmpty) {
                    return _PickerError(
                      message: state.errorMessage!,
                      onRetry: () => notifier.fetchAllBatches(),
                    );
                  }
                  if (state.filteredItems.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No products found',
                      subtitle:
                          'Try a different search or add a new product first.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    itemCount: state.filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final batch = state.filteredItems[index];
                      final selected = state.selectedItems.keys
                          .contains(batch.batchNumber);
                      return _ProductRow(
                        batch: batch,
                        selected: selected,
                        onTap: () =>
                            notifier.addProductToBundle(batch.batchNumber),
                        onLongPress: () => notifier
                            .removeProductFromBundle(batch.batchNumber),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: selectedCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _onAdd(state.selectedItems),
                    child: Text(
                      'Add $selectedCount '
                      '${selectedCount == 1 ? "product" : "products"}',
                      style: tt.labelLarge?.copyWith(color: cs.onPrimary),
                    ),
                  ),
                ),
              ),
            ),
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
            hintText: 'Search products…',
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
// Sort menu
// ────────────────────────────────────────────────────────────────────────────

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sortBy, required this.onSelect});

  final String sortBy;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label =
        sortBy == 'name' ? 'Sort: Name' : 'Sort: Expiry date';
    return PopupMenuButton<String>(
      onSelected: onSelect,
      tooltip: 'Sort',
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'expiryDate', child: Text('Expiry date')),
        PopupMenuItem(value: 'name', child: Text('Name')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
          ),
          Icon(Icons.expand_more, color: cs.primary, size: 20),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Product row
// ────────────────────────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.batch,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final BatchModel batch;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final imageUrl = batch.product?.mainImageUrl ?? '';
    final name = batch.product?.name ?? 'Batch ${batch.batchNumber}';
    final expiryLabel = DateFormat('MMM d, y').format(batch.expiryDate);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: selected
            ? Border.all(color: cs.primary.withValues(alpha: 0.4), width: 1.5)
            : null,
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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: imageUrl.isEmpty
                        ? Container(
                            color: cs.surface,
                            child: Icon(
                              Icons.image_outlined,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: cs.surface,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: cs.onSurface.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: tt.titleSmall?.copyWith(
                          color: selected ? cs.primary : cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expires $expiryLabel',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CheckIndicator(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckIndicator extends StatelessWidget {
  const _CheckIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? cs.primary : cs.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? cs.primary
              : cs.onSurface.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 18, color: cs.onPrimary)
          : null,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Error
// ────────────────────────────────────────────────────────────────────────────

class _PickerError extends StatelessWidget {
  const _PickerError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              "Couldn't load products",
              style:
                  theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
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
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
