import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/viewmodels/product_viewmodel.dart';

/// Edit-product form, structured to the Phase 1 Quality Bar:
/// SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form +
/// _FieldLabel pattern.
class EditProductView extends ConsumerStatefulWidget {
  final VoidCallback onProductAdded;
  final ProductModel product;

  const EditProductView({
    super.key,
    required this.onProductAdded,
    required this.product,
  });

  @override
  ConsumerState<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends ConsumerState<EditProductView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productViewModelProvider.notifier)
          .loadProduct(widget.product);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productViewModelProvider);
    final notifier = ref.read(productViewModelProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

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
          'Edit product',
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
                      'Update product details',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Changes will apply to all current and future listings of this product.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Main image
                    _FieldLabel('Product image', color: cs.onSurface),
                    const SizedBox(height: 8),
                    _ImagePickerBox(
                      data: state.mainImageState.data,
                      error: state.errorFound,
                      onPick: () => notifier.pickImage(true),
                      onRemove: state.mainImageState.data == null
                          ? null
                          : () => notifier.deleteImage(true, null),
                    ),
                    if (state.errorFound) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Product image is required',
                        style: tt.bodySmall?.copyWith(color: cs.error),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Gallery
                    _FieldLabel('Photo gallery', color: cs.onSurface),
                    const SizedBox(height: 4),
                    Text(
                      'Add up to 4 supporting photos.',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GalleryGrid(
                      images: state.additionalImages
                          .map((s) => s.data)
                          .toList(),
                      onRemove: (index) => notifier.deleteImage(false, index),
                      onAdd: state.additionalImages.length >= 4
                          ? null
                          : () => notifier.pickImage(false),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    _FieldLabel('Name', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Whole-wheat bread',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _FieldLabel('Description', color: cs.onSurface),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notifier.descriptionController,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText:
                            "What's inside, ingredients, allergens, anything buyers should know…",
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
                          notifier.setSelectedCategory(value);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Category is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Primary CTA
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                final ok =
                                    await notifier.updateProduct(context);
                                if (!ok) return;
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product updated.'),
                                  ),
                                );
                                notifier.clearData();
                                widget.onProductAdded();
                                if (!context.mounted) return;
                                Navigator.pop(context, true);
                              },
                        child: state.isLoading
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(
                                'Save changes',
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
// Main image picker (shared visual with add-product)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        if (onRemove != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              label: Text(
                'Remove image',
                style: theme.textTheme.labelLarge?.copyWith(color: cs.error),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Gallery grid
// ────────────────────────────────────────────────────────────────────────────

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid({
    required this.images,
    required this.onRemove,
    required this.onAdd,
  });

  final List<Uint8List?> images;
  final ValueChanged<int> onRemove;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entries = <Widget>[];

    for (var i = 0; i < images.length; i++) {
      final data = images[i];
      entries.add(
        _GalleryTile(
          data: data,
          onRemove: () => onRemove(i),
        ),
      );
    }
    if (onAdd != null) {
      entries.add(
        GestureDetector(
          onTap: onAdd,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
            ),
            child: Icon(
              Icons.add,
              color: cs.primary,
            ),
          ),
        ),
      );
    }

    if (entries.isEmpty) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: Text(
            'No additional photos yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: entries,
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.data, required this.onRemove});

  final Uint8List? data;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (data != null)
            Image.memory(data!, fit: BoxFit.cover)
          else
            Icon(
              Icons.image_outlined,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: cs.surface.withValues(alpha: 0.85),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: cs.error,
                  ),
                ),
              ),
            ),
          ),
        ],
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
