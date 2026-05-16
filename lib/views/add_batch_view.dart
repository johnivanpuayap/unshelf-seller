import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/viewmodels/batch_viewmodel.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/models/product_model.dart';

class AddBatchView extends ConsumerWidget {
  final ProductModel product;
  final _formKey = GlobalKey<FormState>();

  AddBatchView({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batchViewModelProvider);
    final notifier = ref.read(batchViewModelProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Enter Batch Details',
        onBackPressed: () {
          notifier.clearData();
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            _buildProductHeader(context, product),
            const SizedBox(height: AppTheme.spacing16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Batch Number (Optional)',
                    ),
                    controller: notifier.batchNumberController,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Expiration Date',
                    ),
                    controller: TextEditingController(
                      text: state.expiryDate != null
                          ? "${state.expiryDate!.month}-${state.expiryDate!.day}-${state.expiryDate!.year}"
                          : '',
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        notifier.expiryDate = date;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Expiration date is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Price',
                    ),
                    keyboardType: TextInputType.number,
                    controller: notifier.priceController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price of the batch';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                    ),
                    keyboardType: TextInputType.number,
                    controller: notifier.stockController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      if (int.tryParse(value) == null ||
                          int.parse(value) <= 0) {
                        return 'Please enter a valid stock quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Quantifier',
                      hintText: 'e.g. kilogram, can, pack',
                    ),
                    controller: notifier.quantifierController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Quantifier is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Discount (%)',
                      hintText: 'e.g. 10 for 10%, 0 for no discount',
                    ),
                    keyboardType: TextInputType.number,
                    controller: notifier.discountController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Discount is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid discount percentage';
                      }
                      if (int.parse(value) < 0 || int.parse(value) > 100) {
                        return 'Discount percentage must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  CustomButton(
                      text: 'Add Product Batch',
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          bool isSuccessful =
                              await notifier.addBatch(product.id);

                          if (isSuccessful) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Product batch added successfully!')),
                            );
                            notifier.clearData();
                            Navigator.pop(context, true);
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'An error occurred. Please try again later')),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please fill in all required fields')),
                          );
                        }
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader(BuildContext context, ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Batch Details for:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Image.network(
            product.mainImageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
      ],
    );
  }
}
