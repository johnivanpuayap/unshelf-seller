import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/section_header.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/viewmodels/product_summary_viewmodel.dart';
import 'package:unshelf_seller/views/add_batch_view.dart';
import 'package:unshelf_seller/views/edit_batch_view.dart';
import 'package:unshelf_seller/views/edit_product_view.dart';

/// Detail screen for a single product.
///
/// Layout: full-bleed hero image at the top, then a 24px-horizontal-padding
/// stack of:
/// • Title + category chip
/// • Description card
/// • KPI row (active batches / units in stock / soonest expiry)
/// • Active batches list (each with expiry urgency + edit / delete)
/// • Sticky bottom CTA row — "Add batch" primary + "Edit product" secondary
class ProductDetailsView extends ConsumerStatefulWidget {
  final String productId;
  final bool? isNew;

  const ProductDetailsView({
    super.key,
    required this.productId,
    this.isNew = false,
  });

  @override
  ConsumerState<ProductDetailsView> createState() =>
      _ProductDetailsViewState();
}

class _ProductDetailsViewState extends ConsumerState<ProductDetailsView> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productSummaryViewModelProvider.notifier)
          .fetchProductData(widget.productId);
    });
  }

  Future<void> _refresh() {
    return ref
        .read(productSummaryViewModelProvider.notifier)
        .fetchProductData(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productSummaryViewModelProvider);
    final notifier = ref.read(productSummaryViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (state.product != null && widget.isNew == true && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddBatchDialog(state.product!);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Product',
          style: theme.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.product == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.product == null) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Product not available',
              subtitle: state.errorMessage ??
                  'This product may have been removed or is unavailable.',
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
          final product = state.product!;
          final batches = state.batches ?? const <BatchModel>[];
          return RefreshIndicator(
            color: cs.primary,
            onRefresh: _refresh,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(imageUrl: product.mainImageUrl),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TitleBlock(product: product),
                          const SizedBox(height: 20),
                          _DescriptionCard(text: product.description),
                          const SizedBox(height: 24),
                          _KpiRow(batches: batches),
                          const SizedBox(height: 32),
                          SectionHeader(
                            title: 'Active batches',
                            actionLabel: batches.isEmpty ? null : 'Add batch',
                            onAction: batches.isEmpty
                                ? null
                                : () => _navigateAddBatch(product),
                          ),
                          if (batches.isEmpty)
                            _NoBatchesCard(
                              onAddBatch: () => _navigateAddBatch(product),
                            )
                          else
                            Column(
                              children: [
                                for (final batch in batches) ...[
                                  _BatchCard(
                                    batch: batch,
                                    onEdit: () =>
                                        _navigateEditBatch(batch.batchNumber),
                                    onDelete: () => _confirmDeleteBatch(
                                      notifier,
                                      batch.batchNumber,
                                    ),
                                  ),
                                  if (batch != batches.last)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: state.product == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateEditProduct(state.product!),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Edit'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _navigateAddBatch(state.product!),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add batch'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _navigateAddBatch(ProductModel product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddBatchView(product: product)),
    );
    if (result == true && mounted) {
      _refresh();
    }
  }

  Future<void> _navigateEditBatch(String batchNumber) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditBatchView(batchNumber: batchNumber),
      ),
    );
    if (result == true && mounted) {
      _refresh();
    }
  }

  Future<void> _navigateEditProduct(ProductModel product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProductView(
          product: product,
          onProductAdded: () {
            if (mounted) _refresh();
          },
        ),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _confirmDeleteBatch(
    ProductSummaryViewModel notifier,
    String batchNumber,
  ) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete batch?',
          style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
        ),
        content: Text(
          "This batch will be removed from your inventory. This can't be undone.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: theme.textTheme.labelLarge?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.deleteBatch(batchNumber);
    }
  }

  void _showAddBatchDialog(ProductModel product) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Add a batch?',
            style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
          ),
          content: Text(
            'Products need at least one batch before they can be listed for buyers. Add a batch now?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Skip',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _navigateAddBatch(product);
              },
              child: Text(
                'Add batch',
                style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Hero image
// ────────────────────────────────────────────────────────────────────────────

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: imageUrl.isEmpty
            ? Container(
                color: cs.surfaceContainerHighest,
                child: Icon(
                  Icons.image_outlined,
                  size: 56,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 56,
                    color: cs.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Title block
// ────────────────────────────────────────────────────────────────────────────

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: cs.onSurface,
          ),
        ),
        if (product.category.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              product.category,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Description card
// ────────────────────────────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final empty = text.trim().isEmpty;
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            empty ? 'No description yet.' : text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: empty
                  ? cs.onSurface.withValues(alpha: 0.55)
                  : cs.onSurface.withValues(alpha: 0.85),
              fontStyle: empty ? FontStyle.italic : null,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// KPI row
// ────────────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.batches});

  final List<BatchModel> batches;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = batches.where((b) => b.stock > 0).toList();
    final totalStock = batches.fold<int>(0, (sum, b) => sum + b.stock);
    final soonest = active.isEmpty
        ? null
        : (List<BatchModel>.from(active)
              ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)))
            .first
            .expiryDate;
    final daysLeft = soonest?.difference(DateTime.now()).inDays;
    final daysLabel = daysLeft == null
        ? '—'
        : daysLeft <= 0
            ? 'Today'
            : '$daysLeft d';

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Active batches',
            value: active.length.toString(),
            icon: Icons.layers_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Units in stock',
            value: totalStock.toString(),
            icon: Icons.inventory_2_outlined,
            iconColor: totalStock <= 0 ? cs.error : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Soonest expiry',
            value: daysLabel,
            icon: Icons.event_outlined,
            iconColor: (daysLeft != null && daysLeft <= 3) ? cs.error : null,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// No-batches card
// ────────────────────────────────────────────────────────────────────────────

class _NoBatchesCard extends StatelessWidget {
  const _NoBatchesCard({required this.onAddBatch});

  final VoidCallback onAddBatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.layers_outlined,
            size: 40,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No batches yet',
            style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least one batch with stock, price, and expiry to list this product.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAddBatch,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add batch'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Batch card
// ────────────────────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onEdit,
    required this.onDelete,
  });

  final BatchModel batch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final daysLeft = batch.expiryDate.difference(DateTime.now()).inDays;
    final tone = _UrgencyTone.from(daysLeft);
    final dateLabel = DateFormat('MMM d, y').format(batch.expiryDate);
    final priceLabel = NumberFormat.currency(symbol: '₱', decimalDigits: 2)
        .format(batch.price);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      '${batch.stock} ${batch.quantifier} · $priceLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              _UrgencyBadge(tone: tone),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.event_outlined,
                size: 16,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              Text(
                'Expires $dateLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit batch',
                icon: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete batch',
                icon:
                    Icon(Icons.delete_outline, size: 20, color: cs.error),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.tone});

  final _UrgencyTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (bg, fg) = switch (tone.kind) {
      _UrgencyKind.danger => (cs.error.withValues(alpha: 0.15), cs.error),
      _UrgencyKind.warning => (
          cs.tertiary.withValues(alpha: 0.15),
          cs.tertiary,
        ),
      _UrgencyKind.calm => (cs.primary.withValues(alpha: 0.14), cs.primary),
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

enum _UrgencyKind { danger, warning, calm }

class _UrgencyTone {
  const _UrgencyTone(this.label, this.kind);
  final String label;
  final _UrgencyKind kind;

  static _UrgencyTone from(int daysLeft) {
    if (daysLeft <= 1) return const _UrgencyTone('1 day', _UrgencyKind.danger);
    if (daysLeft <= 3) {
      return _UrgencyTone('$daysLeft days', _UrgencyKind.danger);
    }
    if (daysLeft <= 7) {
      return _UrgencyTone('$daysLeft days', _UrgencyKind.warning);
    }
    return _UrgencyTone('$daysLeft days', _UrgencyKind.calm);
  }
}
