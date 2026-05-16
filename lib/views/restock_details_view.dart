import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/empty_state.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/viewmodels/restock_viewmodel.dart';

/// Restock details screen.
///
/// Per-product editable stock + expiry inside a single Quality-Bar form
/// shell. Submitting calls `batchRestock` on every selected product.
class RestockDetailsView extends ConsumerStatefulWidget {
  const RestockDetailsView({super.key});

  @override
  ConsumerState<RestockDetailsView> createState() =>
      _RestockDetailsViewState();
}

class _RestockDetailsViewState extends ConsumerState<RestockDetailsView> {
  final Map<String, TextEditingController> _controllers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Seed a controller per selected product so we can drive the stepper.
    final selected = ref.read(restockViewModelProvider).selectedProducts;
    for (final p in selected) {
      _controllers[p.batchNumber] =
          TextEditingController(text: p.stock > 0 ? p.stock.toString() : '');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(BatchModel product) {
    return _controllers.putIfAbsent(
      product.batchNumber,
      () => TextEditingController(
        text: product.stock > 0 ? product.stock.toString() : '',
      ),
    );
  }

  void _adjust(BatchModel product, int delta) {
    final controller = _controllerFor(product);
    final current = int.tryParse(controller.text) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    controller.text = next.toString();
    product.stock = next;
  }

  void _setStock(BatchModel product, String value) {
    product.stock = int.tryParse(value) ?? 0;
  }

  Future<void> _pickExpiry(BatchModel product) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: product.expiryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      ref
          .read(restockViewModelProvider.notifier)
          .updateExpiryDate(product, picked);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final state = ref.read(restockViewModelProvider);
    final notifier = ref.read(restockViewModelProvider.notifier);
    final invalid = state.selectedProducts.any((p) => p.stock <= 0);
    if (invalid) {
      _snack('Each product needs a restock quantity greater than zero.');
      return;
    }
    setState(() => _submitting = true);
    await notifier.batchRestock(state.selectedProducts);
    if (!mounted) return;
    setState(() => _submitting = false);
    _snack('Restock submitted.');
    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restockViewModelProvider);
    final products = state.selectedProducts;
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
          'Restock details',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: products.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Nothing selected',
              subtitle: 'Go back and pick at least one product to restock.',
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Restock',
                                style: tt.headlineMedium
                                    ?.copyWith(color: cs.onSurface),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Set the restock quantity and new expiry for each batch.',
                                style: tt.bodyMedium?.copyWith(
                                  color:
                                      cs.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                              const SizedBox(height: 24),
                              for (var i = 0; i < products.length; i++) ...[
                                _ProductCard(
                                  product: products[i],
                                  controller:
                                      _controllerFor(products[i]),
                                  onDecrement: () =>
                                      _adjust(products[i], -1),
                                  onIncrement: () =>
                                      _adjust(products[i], 1),
                                  onStockChanged: (v) =>
                                      _setStock(products[i], v),
                                  onPickExpiry: () =>
                                      _pickExpiry(products[i]),
                                ),
                                if (i < products.length - 1)
                                  const SizedBox(height: 16),
                              ],
                              if (state.error.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  state.error,
                                  style: tt.bodySmall
                                      ?.copyWith(color: cs.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Restock ${products.length} '
                                '${products.length == 1 ? "product" : "products"}',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Product card with stepper + expiry picker
// ────────────────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.onStockChanged,
    required this.onPickExpiry,
  });

  final BatchModel product;
  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onStockChanged;
  final VoidCallback onPickExpiry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final expiryLabel = DateFormat('MMM d, y').format(product.expiryDate);
    final imageUrl = product.product?.mainImageUrl ?? '';

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
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                  product.product?.name ?? 'Batch ${product.batchNumber}',
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FieldLabel('Restock quantity', color: cs.onSurface),
          const SizedBox(height: 8),
          _StockStepper(
            controller: controller,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
            onChanged: onStockChanged,
          ),
          const SizedBox(height: 16),
          _FieldLabel('New expiry date', color: cs.onSurface),
          const SizedBox(height: 8),
          _DatePickerField(
            label: expiryLabel,
            onTap: onPickExpiry,
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Date picker tile
// ────────────────────────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Stock stepper
// ────────────────────────────────────────────────────────────────────────────

class _StockStepper extends StatelessWidget {
  const _StockStepper({
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperButton(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '0'),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        _StepperButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(icon, color: cs.primary, size: 18),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Field label (copied verbatim from auth screens)
// ────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      );
}
