import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:unshelf_seller/components/field_label.dart';
import 'package:unshelf_seller/viewmodels/product_viewmodel.dart';
import 'package:unshelf_seller/views/product_details_view.dart';

/// Add-product form, structured to the Phase 1 Quality Bar:
/// SafeArea + Center + SingleChildScrollView + maxWidth 420 + Form +
/// FieldLabel pattern, mirroring the auth screens.
class AddProductView extends ConsumerWidget {
  final VoidCallback onProductAdded;

  const AddProductView({super.key, required this.onProductAdded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Add product',
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
                      'List a new product',
                      style: tt.headlineMedium?.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add the basics now — you'll add batches with stock and expiry on the next step.",
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Product image
                    FieldLabel('Product image', color: cs.onSurface),
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

                    // Name
                    FieldLabel('Name', color: cs.onSurface),
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
                    FieldLabel('Description', color: cs.onSurface),
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
                                final added = await notifier
                                    .addProductWithValidation(context);
                                if (!added) return;
                                final newId = ref
                                    .read(productViewModelProvider)
                                    .selectedProductId;
                                onProductAdded();
                                notifier.clearData();
                                if (!context.mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsView(
                                      productId: newId,
                                      isNew: true,
                                    ),
                                  ),
                                );
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
                                'Add product',
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
// Image picker box
// ────────────────────────────────────────────────────────────────────────────

class _ImagePickerBox extends StatelessWidget {
  const _ImagePickerBox({
    required this.data,
    required this.error,
    required this.onPick,
    required this.onRemove,
  });

  final dynamic data; // Uint8List? — kept dynamic to avoid an extra import
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
// Field label (copied verbatim from auth screens)
// ────────────────────────────────────────────────────────────────────────────

