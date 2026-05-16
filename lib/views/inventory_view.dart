import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/inventory_product_model.dart';
import 'package:unshelf_seller/viewmodels/inventory_viewmodel.dart';
import 'package:unshelf_seller/views/batch_history_view.dart';

/// Seller-side inventory list.
///
/// Layout: AppBar with back action + full-width vertical list of rows.
/// Each row: 64px thumb | name + total stock + soonest expiry | status badge
/// | chevron. Top filter chips: All / In stock / Low / Out of stock.
class InventoryView extends ConsumerStatefulWidget {
  const InventoryView({super.key});

  @override
  ConsumerState<InventoryView> createState() => _InventoryViewState();
}

enum _StockFilter { all, inStock, low, outOfStock }

class _InventoryViewState extends ConsumerState<InventoryView> {
  final TextEditingController _searchController = TextEditingController();
  _StockFilter _filter = _StockFilter.all;

  static const _lowStockThreshold = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryViewModelProvider.notifier).fetchInventory();
    });
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return ref.read(inventoryViewModelProvider.notifier).fetchInventory();
  }

  List<InventoryProductModel> _applyFilters(
    List<InventoryProductModel> items,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      if (query.isNotEmpty &&
          !item.name.toLowerCase().contains(query)) {
        return false;
      }
      final total = item.batches.fold<int>(0, (sum, b) => sum + b.stock);
      switch (_filter) {
        case _StockFilter.all:
          return true;
        case _StockFilter.inStock:
          return total > _lowStockThreshold;
        case _StockFilter.low:
          return total > 0 && total <= _lowStockThreshold;
        case _StockFilter.outOfStock:
          return total == 0;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(inventoryViewModelProvider);
    final filtered = _applyFilters(state.inventoryItems);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(inventoryViewModelProvider.notifier).clearData();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Inventory',
          style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: _refresh,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: _SearchField(controller: _searchController),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: _StockFilterChips(
                    selected: _filter,
                    onSelected: (next) => setState(() => _filter = next),
                  ),
                ),
              ),
              if (state.isLoading && state.inventoryItems.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.errorMessage != null &&
                  state.inventoryItems.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _InventoryError(
                    message: state.errorMessage!,
                    onRetry: _refresh,
                  ),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _emptyTitle(),
                    subtitle: _emptySubtitle(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _InventoryRow(item: item);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyTitle() {
    switch (_filter) {
      case _StockFilter.inStock:
        return 'No well-stocked products';
      case _StockFilter.low:
        return 'No low-stock products';
      case _StockFilter.outOfStock:
        return 'Nothing out of stock';
      case _StockFilter.all:
        return _searchController.text.isEmpty
            ? 'No inventory yet'
            : 'No matches for your search';
    }
  }

  String _emptySubtitle() {
    switch (_filter) {
      case _StockFilter.inStock:
        return 'Products with stock above the low-stock threshold will appear here.';
      case _StockFilter.low:
        return 'Products at or below the low-stock threshold will appear here.';
      case _StockFilter.outOfStock:
        return 'Products with zero stock will appear here.';
      case _StockFilter.all:
        return _searchController.text.isEmpty
            ? 'Add products to start tracking batches and stock.'
            : 'Try a different name or clear the search.';
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Search + filter chrome
// ────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search inventory…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => controller.clear(),
              ),
      ),
    );
  }
}

class _StockFilterChips extends StatelessWidget {
  const _StockFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final _StockFilter selected;
  final ValueChanged<_StockFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    const filters = <_StockFilter, String>{
      _StockFilter.all: 'All',
      _StockFilter.inStock: 'In stock',
      _StockFilter.low: 'Low',
      _StockFilter.outOfStock: 'Out of stock',
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (final entry in filters.entries) ...[
            ChoiceChip(
              label: Text(entry.value),
              selected: selected == entry.key,
              onSelected: (_) => onSelected(entry.key),
              showCheckmark: false,
              selectedColor: cs.primary.withValues(alpha: 0.14),
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: selected == entry.key
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected == entry.key
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            if (entry.key != filters.keys.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Inventory row
// ────────────────────────────────────────────────────────────────────────────

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item});

  final InventoryProductModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totalStock = item.batches.fold<int>(0, (sum, b) => sum + b.stock);
    final stockLabel = _StockTone.from(totalStock);
    final quantifier = item.batches.isNotEmpty
        ? item.batches.first.quantifier
        : '';
    final soonest = _soonestExpiry(item.batches);

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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showBatchesSheet(context, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _Thumb(imageUrl: item.mainImageUrl, size: 64),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalStock ${quantifier.isEmpty ? "in stock" : "$quantifier in stock"}'
                        '${item.batches.isEmpty ? "" : " • ${item.batches.length} ${item.batches.length == 1 ? "batch" : "batches"}"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (soonest != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Soonest expiry · ${DateFormat('MMM d, y').format(soonest)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StockPill(tone: stockLabel),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _soonestExpiry(List<BatchModel> batches) {
    if (batches.isEmpty) return null;
    final withStock = batches.where((b) => b.stock > 0).toList();
    if (withStock.isEmpty) return null;
    withStock.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return withStock.first.expiryDate;
  }

  void _showBatchesSheet(
    BuildContext context,
    InventoryProductModel item,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _BatchesSheet(item: item),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl, required this.size});

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
          size: 28,
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
          size: 28,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.tone});

  final _StockTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg) = switch (tone) {
      _StockTone.inStock => (
          cs.primary.withValues(alpha: 0.14),
          cs.primary,
        ),
      _StockTone.low => (
          cs.error.withValues(alpha: 0.15),
          cs.error,
        ),
      _StockTone.outOfStock => (
          cs.error.withValues(alpha: 0.18),
          cs.error,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tone.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

enum _StockTone {
  inStock('In stock'),
  low('Low'),
  outOfStock('Out of stock');

  const _StockTone(this.label);
  final String label;

  static _StockTone from(int total) {
    if (total <= 0) return _StockTone.outOfStock;
    if (total <= 5) return _StockTone.low;
    return _StockTone.inStock;
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Batches bottom sheet
// ────────────────────────────────────────────────────────────────────────────

class _BatchesSheet extends StatelessWidget {
  const _BatchesSheet({required this.item});

  final InventoryProductModel item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final batches = List<BatchModel>.from(item.batches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
              item.name,
              style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              '${batches.length} ${batches.length == 1 ? "batch" : "batches"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 16),
            if (batches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No batches yet for this product.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: batches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final batch = batches[index];
                    return _BatchTile(batch: batch);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.batch});

  final BatchModel batch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateLabel = DateFormat('MMM d, y').format(batch.expiryDate);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BatchHistoryView(batchId: batch.batchNumber),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch ${batch.batchNumber}',
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
                Icon(
                  Icons.chevron_right,
                  size: 20,
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

class _InventoryError extends StatelessWidget {
  const _InventoryError({required this.message, required this.onRetry});

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
            "Couldn't load inventory",
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
