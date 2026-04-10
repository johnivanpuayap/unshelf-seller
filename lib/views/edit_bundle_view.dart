import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/viewmodels/bundle_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/components/image_delete.dart';

class EditBundleView extends StatefulWidget {
  final String bundleId;

  EditBundleView({required this.bundleId});

  @override
  State<EditBundleView> createState() => _EditBundleViewState();
}

class _EditBundleViewState extends State<EditBundleView> {
  final Map<String, Map<String, dynamic>> productDetails = {};
  late BundleViewModel viewModel;

  @override
  void initState() {
    super.initState();

    viewModel = Provider.of<BundleViewModel>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await viewModel.initializeBundle(widget.bundleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Edit Bundle Details',
          onBackPressed: () {
            Provider.of<BundleViewModel>(context, listen: false)
                .clearSelection();
            Navigator.pop(context);
          }),
      body: Consumer<BundleViewModel>(
        builder: (context, viewModel, child) {
          return viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Form(
                    key: viewModel.formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Image Section
                          GestureDetector(
                            onTap: () => viewModel.pickImage(),
                            child: Container(
                              width: double.infinity,
                              height: 300,
                              color: AppColors.darkColor,
                              child: viewModel.mainImageData != null
                                  ? ImageWithDelete(
                                      imageData: viewModel.mainImageData!,
                                      onDelete: viewModel.deleteImage,
                                      width: 400.0,
                                      height: 400.0,
                                      margin: EdgeInsets.all(0),
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
                            controller: viewModel.bundleNameController,
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
                              labelStyle:
                                  TextStyle(color: AppColors.textPrimary),
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
                            controller: viewModel.bundleDescriptionController,
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
                              labelStyle:
                                  TextStyle(color: AppColors.textPrimary),
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
                            initialValue: viewModel.selectedCategory.isEmpty
                                ? null
                                : viewModel.selectedCategory,
                            items: viewModel.categories.map((String category) {
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
                              labelStyle:
                                  TextStyle(color: AppColors.textPrimary),
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
                            controller: viewModel.bundlePriceController,
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
                              labelStyle:
                                  TextStyle(color: AppColors.textPrimary),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
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
                            controller: viewModel.bundleStockController,
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
                              labelStyle:
                                  TextStyle(color: AppColors.textPrimary),
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
                            controller: viewModel.bundleDiscountController,
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
                              labelStyle:
                                  TextStyle(color: AppColors.textPrimary),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppTheme.spacing48),

                          CustomButton(
                            text: 'Update Bundle',
                            onPressed: () async {
                              if (viewModel.formKey.currentState?.validate() ??
                                  false) {
                                await viewModel.updateBundle();
                                viewModel.clearSelection();
                                Navigator.pop(context);
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
