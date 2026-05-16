import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:unshelf_seller/components/field_label.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';

/// Add-bundle form, structured to the Phase 1 Quality Bar:
/// SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form +
/// FieldLabel pattern. Composition section uses inline quantity steppers
/// per selected product.
class AddBundleView extends ConsumerStatefulWidget {
  final Map<String, BatchModel> products;

  const AddBundleView({super.key, required this.products});

  @override
  ConsumerState<AddBundleView> createState() => _AddBundleViewState();
}

class _AddBundleViewState extends ConsumerState<AddBundleView> {
  final Map<String, Map<String, dynamic>> _productDetails = {};
  bool _submitting = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    widget.products.forEach((productId, product) {
      _productDetails[productId] = {
        'quantity': 1,
        'quantifier': product.quantifier,
      };
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _adjustQuantity(String productId, int delta) {
    setState(() {
      final next = ((_productDetails[productId]!['quantity'] as int) + delta)
          .clamp(1, 999);
      _productDetails[productId]!['quantity'] = next;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final notifier = ref.read(bundleViewModelProvider.notifier);
    final state = ref.read(bundleViewModelProvider);
    final formOk = notifier.formKey.currentState?.validate() ?? false;
    final missingImage = state.mainImageData == null;
    setState(() => _imageError = missingImage);
    if (!formOk || missingImage) {
      _snack('Please fill in all required fields');
      return;
    }
    setState(() => _submitting = true);
    await notifier.createBundle(_productDetails);
    if (!mounted) return;
    setState(() => _submitting = false);
    _snack('Bundle created.');
    notifier.clearSelection();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bundleViewModelProvider);
    final notifier = ref.read(bundleViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

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
          'New bundle',
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
                key: notifier.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create a bundle',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Group multiple batches into one discounted pack.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Image
                    FieldLabel('Bundle image', color: cs.onSurface),
                    const SizedBox(height: 8),
                    _ImagePickerBox(
                      data: state.mainImageData,
                      error: _imageError,
                      onPick: () async {
                        await notifier.pickImage();
                        if (mounted &&
                            ref
                                    .read(bundleViewModelProvider)
                                    .mainImageData !=
                                null) {
                          setState(() => _imageError = false);
                        }
                      },
                      onRemove: state.mainImageData == null
                          ? null
                          : () => notifier.deleteImage(),
                    ),
                    if (_imageError) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Bundle image is required',
                        style: tt.bodySmall?.copyWith(color: cs.error),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Name
                    FieldLabel('Bundle name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.bundleNameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Weekend brunch box',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Bundle name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    FieldLabel('Description', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.bundleDescriptionController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText:
                            "What's in the bundle, who it's for, suggested use…",
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category
                    FieldLabel('Category', color: cs.onSurface),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: state.selectedCategory.isEmpty
                          ? null
                          : state.selectedCategory,
                      items: notifier.categories
                          .map(
                            (cat) => DropdownMenuItem<String>(
                              value: cat,
                              child: Text(cat),
                            ),
                          )
                          .toList(),
                      decoration: const InputDecoration(
                        hintText: 'Select a category',
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          notifier.selectedCategory = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Category is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Price
                    FieldLabel('Price', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.bundlePriceController,
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
                        hintText: 'e.g. 250',
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

                    // Stock
                    FieldLabel('Stock', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.bundleStockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'How many bundles can buyers order?',
                      ),
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
                    const SizedBox(height: 20),

                    // Discount
                    FieldLabel('Discount (%)', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.bundleDiscountController,
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

                    // Composition
                    Text(
                      'Composition',
                      style: tt.titleMedium?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose how many of each batch goes into one bundle.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final entry in widget.products.entries) ...[
                      _CompositionRow(
                        batch: entry.value,
                        quantity:
                            _productDetails[entry.key]!['quantity'] as int,
                        onDecrement: () => _adjustQuantity(entry.key, -1),
                        onIncrement: () => _adjustQuantity(entry.key, 1),
                      ),
                      if (entry.key != widget.products.entries.last.key)
                        const SizedBox(height: 12),
                    ],
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
                                'Create bundle',
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
// Image picker box (in-tile close, no `image_delete.dart` dependency)
// ────────────────────────────────────────────────────────────────────────────

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    required this.data,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? data;
  final bool error;
  final VoidCallback onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final borderColor = error
        ? cs.error
        : cs.onSurface.withValues(alpha: 0.12);

    return Stack(
      children: [
        GestureDetector(
          onTap: onPick,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: error ? 1.5 : 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: data != null
                ? Image.memory(data!, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            Icons.add_a_photo_outlined,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add a photo',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG or PNG, ideally square',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (data != null && onRemove != null)
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: cs.surface.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: cs.error,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Composition row (per-batch quantity stepper)
// ────────────────────────────────────────────────────────────────────────────

class _CompositionRow extends StatelessWidget {
  const _CompositionRow({
    required this.batch,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final BatchModel batch;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final expiryLabel = DateFormat('MMM d').format(batch.expiryDate);

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  batch.product?.name ?? 'Batch ${batch.batchNumber}',
                  style: tt.titleSmall?.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires $expiryLabel · ${batch.quantifier}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          SizedBox(
            width: 40,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(color: cs.onSurface),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
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
      width: 36,
      height: 36,
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

