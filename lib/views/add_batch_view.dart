import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/field_label.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/viewmodels/batch_viewmodel.dart';

/// Add-batch form, structured to the Phase 1 Quality Bar:
/// SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form +
/// FieldLabel pattern, mirroring the auth screens.
class AddBatchView extends ConsumerStatefulWidget {
  final ProductModel product;

  const AddBatchView({super.key, required this.product});

  @override
  ConsumerState<AddBatchView> createState() => _AddBatchViewState();
}

class _AddBatchViewState extends ConsumerState<AddBatchView> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickExpiry() async {
    final notifier = ref.read(batchViewModelProvider.notifier);
    final initial =
        ref.read(batchViewModelProvider).expiryDate ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      notifier.expiryDate = date;
    }
  }

  void _adjustStock(int delta) {
    final notifier = ref.read(batchViewModelProvider.notifier);
    final current = int.tryParse(notifier.stockController.text) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    notifier.stockController.text = next.toString();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      _snack('Please fill in all required fields');
      return;
    }
    if (ref.read(batchViewModelProvider).expiryDate == null) {
      _snack('Expiry date is required');
      return;
    }
    setState(() => _submitting = true);
    final notifier = ref.read(batchViewModelProvider.notifier);
    final ok = await notifier.addBatch(widget.product.id);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _snack('Batch added.');
      notifier.clearData();
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      _snack('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(batchViewModelProvider);
    final notifier = ref.read(batchViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final expiryLabel = state.expiryDate != null
        ? DateFormat('MMM d, y').format(state.expiryDate!)
        : 'Tap to choose a date';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            notifier.clearData();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Add batch',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New batch',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stock, price, and expiry for a fresh batch of ${widget.product.name}.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _ProductHeader(product: widget.product),
                    const SizedBox(height: 32),

                    // Batch number (optional)
                    FieldLabel('Batch number (optional)', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.batchNumberController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Leave blank to auto-generate',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Expiry date
                    FieldLabel('Expiry date', color: cs.onSurface),
                    const SizedBox(height: 8),
                    _DatePickerField(
                      label: expiryLabel,
                      hasValue: state.expiryDate != null,
                      onTap: _pickExpiry,
                    ),
                    const SizedBox(height: 20),

                    // Stock with stepper
                    FieldLabel('Stock', color: cs.onSurface),
                    const SizedBox(height: 8),
                    _StockStepper(
                      controller: notifier.stockController,
                      onDecrement: () => _adjustStock(-1),
                      onIncrement: () => _adjustStock(1),
                    ),
                    const SizedBox(height: 20),

                    // Quantifier
                    FieldLabel('Quantifier', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.quantifierController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. kilogram, can, pack',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Quantifier is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Price
                    FieldLabel('Price', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*$'),
                        ),
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 120',
                        prefixText: '₱ ',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Price is required';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Discount
                    FieldLabel('Discount (%)', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: '0 for no discount',
                        suffixText: '%',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter 0 if no discount applies';
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null || parsed < 0 || parsed > 100) {
                          return 'Discount must be between 0 and 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Primary CTA
                    SizedBox(
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
                                'Add batch',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onPrimary),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Product header (image + name preview)
// ────────────────────────────────────────────────────────────────────────────

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
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
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: product.mainImageUrl.isEmpty
                  ? Container(
                      color: cs.surface,
                      child: Icon(
                        Icons.image_outlined,
                        color: cs.onSurface.withValues(alpha: 0.35),
                      ),
                    )
                  : Image.network(
                      product.mainImageUrl,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Batch for',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
  const _DatePickerField({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
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
                  color: hasValue
                      ? cs.onSurface
                      : cs.onSurface.withValues(alpha: 0.45),
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
// Stock stepper — numeric field flanked by −/+ buttons
// ────────────────────────────────────────────────────────────────────────────

class _StockStepper extends StatelessWidget {
  const _StockStepper({
    required this.controller,
    required this.onDecrement,
    required this.onIncrement,
  });

  final TextEditingController controller;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperButton(icon: Icons.remove, onTap: onDecrement),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: '0'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Stock is required';
              }
              final parsed = int.tryParse(value);
              if (parsed == null || parsed <= 0) {
                return 'Enter a valid stock quantity';
              }
              return null;
            },
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
      width: 48,
      height: 48,
      child: Material(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Icon(icon, color: cs.primary),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Field label (copied verbatim from auth screens)
// ────────────────────────────────────────────────────────────────────────────

