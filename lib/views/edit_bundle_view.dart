import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';

/// Edit-bundle form, structured to the Phase 1 Quality Bar:
/// SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form +
/// _FieldLabel pattern.
class EditBundleView extends ConsumerStatefulWidget {
  final String bundleId;

  const EditBundleView({super.key, required this.bundleId});

  @override
  ConsumerState<EditBundleView> createState() => _EditBundleViewState();
}

class _EditBundleViewState extends ConsumerState<EditBundleView> {
  bool _submitting = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(bundleViewModelProvider.notifier)
          .initializeBundle(widget.bundleId);
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final notifier = ref.read(bundleViewModelProvider.notifier);
    final state = ref.read(bundleViewModelProvider);
    final formOk = notifier.formKey.currentState?.validate() ?? false;
    final missingImage = state.mainImageData == null;
    setState(() => _imageError = missingImage);
    if (!formOk || missingImage) {
      _snack('Please fix the errors above');
      return;
    }
    setState(() => _submitting = true);
    await notifier.updateBundle();
    if (!mounted) return;
    setState(() => _submitting = false);
    _snack('Bundle updated.');
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
          'Edit bundle',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: false,
      ),
      body: state.isLoading && state.bundle == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: notifier.formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Update bundle',
                            style: tt.headlineMedium
                                ?.copyWith(color: cs.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adjust pricing, stock, or description. Composition is fixed.',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Image
                          _FieldLabel('Bundle image', color: cs.onSurface),
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
                          _FieldLabel('Bundle name', color: cs.onSurface),
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
                          _FieldLabel('Description', color: cs.onSurface),
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
                          _FieldLabel('Category', color: cs.onSurface),
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
                          _FieldLabel('Price', color: cs.onSurface),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: notifier.bundlePriceController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
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
                          _FieldLabel('Stock', color: cs.onSurface),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: notifier.bundleStockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText:
                                  'How many bundles can buyers order?',
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
                          _FieldLabel('Discount (%)', color: cs.onSurface),
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
                              if (parsed == null ||
                                  parsed < 0 ||
                                  parsed > 100) {
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
                                      'Update bundle',
                                      style: tt.labelLarge?.copyWith(
                                        color: cs.onPrimary,
                                      ),
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

  final dynamic data;
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
                ? Image.memory(data, fit: BoxFit.cover)
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
