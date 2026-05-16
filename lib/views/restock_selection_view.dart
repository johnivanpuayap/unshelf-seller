import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/viewmodels/restock_viewmodel.dart';
import 'restock_details_view.dart';

/// Restock selection screen.
///
/// Full-width multi-select list of batches that may need restocking. Filter
/// chips narrow by stock urgency; a sticky bottom bar carries the
/// "Restock N products" CTA.
class RestockSelectionView extends ConsumerStatefulWidget {
  const RestockSelectionView({super.key});

  @override
  ConsumerState<RestockSelectionView> createState() =>
      _RestockSelectionViewState();
}

class _RestockSelectionViewState extends ConsumerState<RestockSelectionView> {
  static const _filters = ['All', 'Low stock', 'Expiring soon'];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restockViewModelProvider.notifier).fetchProducts();
    });
  }

  Future<void> _refresh() =>
      ref.read(restockViewModelProvider.notifier).fetchProducts();

  List<BatchModel> _applyFilter(List<BatchModel> products) {
    final now = DateTime.now();
    switch (_filter) {
      case 'Low stock':
        return products.where((p) => p.stock <= 5).toList();
      case 'Expiring soon':
        return products.where((p) {
          final days = p.expiryDate.difference(now).inDays;
          return days <= 7;
        }).toList();
      default:
        return products;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restockViewModelProvider);
    final notifier = ref.read(restockViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final filtered = _applyFilter(state.products);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select to restock',
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
              child: _FilterChipsRow(
                filters: _filters,
                selected: _filter,
                onSelect: (label) => setState(() => _filter = label),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.isLoading && state.products.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.error.isNotEmpty && state.products.isEmpty) {
                    return _SelectionError(
                      message: state.error,
                      onRetry: _refresh,
                    );
                  }
                  if (filtered.isEmpty) {
                    final emptyTitle = switch (_filter) {
                      'Low stock' => 'No low-stock batches',
                      'Expiring soon' => 'No batches expiring soon',
                      _ => "You're all stocked up",
                    };
                    return EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: emptyTitle,
                      subtitle:
                          'Pull down to refresh or change the filter above.',
                    );
                  }
                  return RefreshIndicator(
                    color: cs.primary,
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final selected = notifier.contain(product);
                        return _ProductRow(
                          product: product,
                          selected: selected,
                          onToggle: () {
                            if (selected) {
                              notifier.removeSelectedProduct(product);
                            } else {
                              notifier.addSelectedProduct(product);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: state.selectedProducts.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RestockDetailsView(),
                      ),
                    ),
                    child: Text(
                      'Restock ${state.selectedProducts.length} '
                      '${state.selectedProducts.length == 1 ? "product" : "products"}',
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
// Filter chips row
// ────────────────────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final label in filters) ...[
            ChoiceChip(
              label: Text(label),
              selected: selected == label,
              onSelected: (_) => onSelect(label),
              showCheckmark: false,
              selectedColor: cs.primary.withValues(alpha: 0.14),
              backgroundColor: cs.surfaceContainerHighest,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: selected == label
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected == label
                      ? cs.primary.withValues(alpha: 0.4)
                      : cs.onSurface.withValues(alpha: 0.08),
                ),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            if (label != filters.last) const SizedBox(width: 8),
          ],
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
    required this.product,
    required this.selected,
    required this.onToggle,
  });

  final BatchModel product;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final imageUrl = product.product?.mainImageUrl ?? '';
    final name = product.product?.name ?? 'Batch ${product.batchNumber}';
    final daysLeft = product.expiryDate.difference(DateTime.now()).inDays;

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
          onTap: onToggle,
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
                        style: tt.titleSmall?.copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock ${product.stock} · '
                        '${daysLeft <= 0 ? "Expired" : "$daysLeft d left"}',
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

class _SelectionError extends StatelessWidget {
  const _SelectionError({required this.message, required this.onRetry});

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
