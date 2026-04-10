import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:unshelf_seller/core/interfaces/i_product_service.dart';
import 'package:unshelf_seller/core/service_locator.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/product_viewmodel.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/views/product_details_view.dart';

class AddProductView extends StatelessWidget {
  final VoidCallback onProductAdded;

  const AddProductView({super.key, required this.onProductAdded});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductViewModel(
        productService: locator<IProductService>(),
      ),
      child: Consumer<ProductViewModel>(builder: (context, viewModel, child) {
        return Scaffold(
          appBar: CustomAppBar(
              title: 'Enter Product Details',
              onBackPressed: () {
                viewModel.clearData();
                Navigator.pop(context);
              }),
          body: viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              : SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    children: [
                      Form(
                        key: viewModel.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Image',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                                const SizedBox(height: AppTheme.spacing8),
                                GestureDetector(
                                  onTap: () => viewModel.pickImage(true),
                                  child: Container(
                                    width: double.infinity,
                                    height: 350,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: viewModel.errorFound
                                            ? AppColors.error
                                            : AppColors.lightColor,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall),
                                    ),
                                    child: viewModel.mainImageState.data != null
                                        ? Stack(
                                            children: [
                                              Center(
                                                child: Image.memory(
                                                  viewModel
                                                      .mainImageState.data!,
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
                                                    color: AppColors
                                                        .textPrimary),
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
                                if (viewModel.mainImageState.data != null)
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
                                          viewModel.deleteImage(true, null);
                                        },
                                        child: Text(
                                          'Remove',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                  color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppTheme.spacing8),
                                      Text(
                                        'You can change the main image by clicking on the image',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            if (viewModel.errorFound)
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: AppTheme.spacing8),
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
                              controller: viewModel.nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a product name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: AppTheme.spacing16),

                            TextFormField(
                              controller: viewModel.descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            DropdownButtonFormField<String>(
                              initialValue: viewModel.selectedCategory.isEmpty
                                  ? null
                                  : viewModel.selectedCategory,
                              items:
                                  viewModel.categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              onChanged: (String? newValue) {
                                viewModel.selectedCategory = newValue!;
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacing16),
                            Align(
                              alignment: Alignment.center,
                              child: CustomButton(
                                text: 'Add Product',
                                onPressed: () async {
                                  bool success = await viewModel
                                      .addProductWithValidation(context);
                                  if (success) {
                                    onProductAdded();
                                    viewModel.clearData();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ProductDetailsView(
                                                  productId: viewModel
                                                      .selectedProductId,
                                                  isNew: true)),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      }),
    );
  }
}
