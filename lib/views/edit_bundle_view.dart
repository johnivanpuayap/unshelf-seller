import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/image_delete.dart';

class EditBundleView extends ConsumerStatefulWidget {
  final String bundleId;

  const EditBundleView({super.key, required this.bundleId});

  @override
  ConsumerState<EditBundleView> createState() => _EditBundleViewState();
}

class _EditBundleViewState extends ConsumerState<EditBundleView> {
  final Map<String, Map<String, dynamic>> productDetails = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(bundleViewModelProvider.notifier)
          .initializeBundle(widget.bundleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bundleViewModelProvider);
    final notifier = ref.read(bundleViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit Bundle Details',
          onBackPressed: () {
            notifier.clearSelection();
            Navigator.pop(context);
          }),
      body: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Form(
                    key: notifier.formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Image Section
                          GestureDetector(
                            onTap: () => notifier.pickImage(),
                            child: Container(
                              width: double.infinity,
                              height: 300,
                              color: AppColors.darkColor,
                              child: state.mainImageData != null
                                  ? ImageWithDelete(
                                      imageData: state.mainImageData!,
                                      onDelete: notifier.deleteImage,
                                      width: 400.0,
                                      height: 400.0,
                                      margin: const EdgeInsets.all(0),
                                    )
                                  : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_a_photo,
                                              color: Colors.white),
                                          Text('Add Main Image',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                      color: Colors.white)),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Bundle Name Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Name',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          TextFormField(
                            controller: notifier.bundleNameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing8,
                                  horizontal: AppTheme.spacing8),
                              labelStyle: theme.textTheme.bodyMedium,
                              errorStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter bundle name';
                              }
                              return null;
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Bundle Description Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Description',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          TextFormField(
                            controller: notifier.bundleDescriptionController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing8,
                                  horizontal: AppTheme.spacing8),
                              labelStyle: theme.textTheme.bodyMedium,
                              errorStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.error),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a bundle name';
                              }
                              return null;
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Category Dropdown Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Category',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          DropdownButtonFormField<String>(
                            initialValue: state.selectedCategory.isEmpty
                                ? null
                                : state.selectedCategory,
                            items:
                                notifier.categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing12,
                                  horizontal: AppTheme.spacing12),
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            onChanged: (String? newValue) {
                              notifier.selectedCategory = newValue!;
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Price Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Price',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          TextFormField(
                            controller: notifier.bundlePriceController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing12,
                                  horizontal: AppTheme.spacing12),
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*$'))
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a price';
                              }
                              try {
                                double.parse(value);
                              } catch (e) {
                                return 'Invalid price format';
                              }
                              return null;
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Quantity Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Quantity',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          TextFormField(
                            controller: notifier.bundleStockController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing12,
                                  horizontal: AppTheme.spacing12),
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the bundle stock';
                              }
                              final stock = int.tryParse(value);
                              if (stock == null || stock <= 0) {
                                return 'Please enter a valid stock number';
                              }
                              return null;
                            },
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                          // Discount Field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Discount (%)',
                                style:
                                    Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          TextFormField(
                            controller: notifier.bundleDiscountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacing12,
                                  horizontal: AppTheme.spacing12),
                              labelStyle: theme.textTheme.bodyMedium,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacing48),

                          CustomButton(
                            text: 'Update Bundle',
                            onPressed: () async {
                              if (notifier.formKey.currentState
                                      ?.validate() ??
                                  false) {
                                await notifier.updateBundle();
                                notifier.clearSelection();
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                          ),
                          const SizedBox(height: AppTheme.spacing24),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }
}
