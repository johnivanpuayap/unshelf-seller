import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:flutter/services.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';
import 'package:unshelf_seller/models/batch_model.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';

class AddBundleView extends ConsumerStatefulWidget {
  final Map<String, BatchModel> products;

  const AddBundleView({super.key, required this.products});

  @override
  ConsumerState<AddBundleView> createState() => _AddBundleViewState();
}

class _AddBundleViewState extends ConsumerState<AddBundleView> {
  final Map<String, Map<String, dynamic>> productDetails = {};

  @override
  void initState() {
    super.initState();

    widget.products.forEach((productId, product) {
      productDetails[productId] = {
        'quantity': 1,
        'quantifier': product.quantifier,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bundleViewModelProvider);
    final notifier = ref.read(bundleViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Enter Bundle Details',
          onBackPressed: () {
            notifier.clearSelection();
            Navigator.pop(context);
          }),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Form(
          key: notifier.formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bundle Image',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    GestureDetector(
                      onTap: () => notifier.pickImage(),
                      child: Container(
                        width: double.infinity,
                        height: 350,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: state.errorFound
                                ? AppColors.error
                                : AppColors.lightColor,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: state.mainImageData != null
                            ? Stack(
                                children: [
                                  Center(
                                    child: Image.memory(
                                      state.mainImageData!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        color: AppColors.textPrimary),
                                    Text(
                                      'Click to Add Main Image',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    if (state.mainImageData != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              alignment: Alignment.center,
                              minimumSize: const Size(50, 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall),
                              ),
                            ),
                            onPressed: () {
                              notifier.deleteImage();
                            },
                            child: Text(
                              'Remove',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            'You can change the main image by clicking on the image',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                  ],
                ),
                if (state.errorFound)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing8),
                    child: Text(
                      'Main image is required',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacing16),
                TextFormField(
                  controller: notifier.bundleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bundle Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a bundle name';
                    }
                    return null;
                  },
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacing16),
                TextFormField(
                  controller: notifier.bundleDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
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
                const SizedBox(height: AppTheme.spacing16),
                DropdownButtonFormField<String>(
                  initialValue: state.selectedCategory.isEmpty
                      ? null
                      : state.selectedCategory,
                  items: notifier.categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
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
                const SizedBox(height: AppTheme.spacing16),
                TextFormField(
                  controller: notifier.bundlePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price of the bundle';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacing24),
                TextFormField(
                  controller: notifier.bundleStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the bundle stock';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock <= 0) {
                      return 'Please enter a valid stock quantity';
                    }
                    return null;
                  },
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacing24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Discount (%)',
                    hintText: 'e.g. 10 for 10%, 0 for no discount',
                  ),
                  controller: notifier.bundleDiscountController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the discount percentage';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid discount percentage';
                    }
                    if (int.parse(value) < 0 || int.parse(value) > 100) {
                      return 'Please enter a valid discount percentage';
                    }

                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppTheme.spacing24),
                Text(
                  'Enter the quantity of each product in the bundle',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                ...widget.products.entries.map((entry) {
                  final productId = entry.key;
                  final product = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.product!.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                              Text(
                                'Batch: ${product.batchNumber}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date:',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${product.expiryDate.day.toString().padLeft(2, '0')}/${product.expiryDate.month.toString().padLeft(2, '0')}/${product.expiryDate.year}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (productDetails[productId]![
                                            'quantity'] >
                                        1) {
                                      productDetails[productId]![
                                          'quantity'] -= 1;
                                    }
                                  });
                                },
                              ),
                              Text(
                                productDetails[productId]!['quantity']
                                    .toString(),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    productDetails[productId]![
                                        'quantity'] += 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: AppTheme.spacing16),
                CustomButton(
                  text: 'Create Bundle',
                  onPressed: () async {
                    final form = notifier.formKey.currentState;

                    if (form != null && form.validate()) {
                      await notifier.createBundle(productDetails);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bundle created successfully'),
                        ),
                      );
                      notifier.clearSelection();
                      Navigator.pop(context, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please fill in all required fields'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
