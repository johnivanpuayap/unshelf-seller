import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/components/stat_card.dart';
import 'package:unshelf_seller/core/providers/services.dart';
import 'package:unshelf_seller/models/bundle_model.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';
import 'package:unshelf_seller/views/edit_bundle_view.dart';

/// Detail screen for a single bundle.
///
/// Layout: full-bleed hero image at the top, then a 24px-horizontal-padding
/// stack of:
/// • Title + category chip
/// • Description card
/// • KPI row (price / stock / discount)
/// • Items in bundle list (each with quantity)
/// • Sticky bottom CTA row — "Edit" + "Delete"
class BundleDetailsView extends ConsumerStatefulWidget {
  final String bundleId;

  const BundleDetailsView({super.key, required this.bundleId});

  @override
  ConsumerState<BundleDetailsView> createState() => _BundleDetailsViewState();
}

class _BundleDetailsViewState extends ConsumerState<BundleDetailsView> {
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(bundleViewModelProvider.notifier)
          .getBundleDetails(widget.bundleId);
    });
  }

  Future<void> _refresh() => ref
      .read(bundleViewModelProvider.notifier)
      .getBundleDetails(widget.bundleId);

  Future<void> _confirmDelete(BundleModel bundle) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete this bundle?',
          style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
        ),
        content: Text(
          "Buyers will no longer see this bundle on your store. This can't be undone.",
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
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(bundleServiceProvider).deleteBundle(bundle.id);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bundle deleted.')),
    );
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBundleView(bundleId: widget.bundleId),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bundleViewModelProvider);
    final BundleModel? bundle = state.bundle;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bundle',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && bundle == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (bundle == null) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Bundle not available',
              subtitle: state.errorMessage ??
                  'This bundle may have been removed or is unavailable.',
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }
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
                    _HeroImage(imageUrl: bundle.mainImageUrl),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TitleBlock(bundle: bundle),
                          const SizedBox(height: 20),
                          _DescriptionCard(text: bundle.description),
                          const SizedBox(height: 24),
                          _KpiRow(bundle: bundle),
                          const SizedBox(height: 32),
                          Text(
                            'Items in bundle',
                            style:
                                tt.titleMedium?.copyWith(color: cs.onSurface),
                          ),
                          const SizedBox(height: 16),
                          if (bundle.items.isEmpty)
                            const EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No items yet',
                              subtitle:
                                  'Edit this bundle to add batches into it.',
                            )
                          else
                            Column(
                              children: [
                                for (var i = 0; i < bundle.items.length; i++) ...[
                                  _CompositionRow(item: bundle.items[i]),
                                  if (i < bundle.items.length - 1)
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
      bottomNavigationBar: bundle == null
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
                          onPressed:
                              _deleting ? null : () => _confirmDelete(bundle),
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: cs.error,
                          ),
                          label: Text(
                            'Delete',
                            style: tt.labelLarge?.copyWith(color: cs.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: cs.error.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _deleting ? null : _openEdit,
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          label: const Text('Edit'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  const _TitleBlock({required this.bundle});

  final BundleModel bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          bundle.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: cs.onSurface,
          ),
        ),
        if (bundle.category.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              bundle.category,
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
  const _KpiRow({required this.bundle});

  final BundleModel bundle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priceLabel = bundle.price == null
        ? '—'
        : NumberFormat.currency(symbol: '₱', decimalDigits: 2)
            .format(bundle.price);
    final stockLabel = (bundle.stock ?? 0).toString();
    final discountLabel = '${bundle.discount ?? 0}%';
    final lowStock = (bundle.stock ?? 0) <= 0;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Price',
            value: priceLabel,
            icon: Icons.sell_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'In stock',
            value: stockLabel,
            icon: Icons.inventory_2_outlined,
            iconColor: lowStock ? cs.error : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Discount',
            value: discountLabel,
            icon: Icons.discount_outlined,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Composition row
// ────────────────────────────────────────────────────────────────────────────

class _CompositionRow extends StatelessWidget {
  const _CompositionRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final name = (item['name'] ?? 'Unknown item').toString();
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final quantifier = (item['quantifier'] ?? '').toString();

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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
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
            child: Text(
              name,
              style: tt.titleSmall?.copyWith(color: cs.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '×$quantity${quantifier.isEmpty ? '' : ' $quantifier'}',
              style: tt.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
