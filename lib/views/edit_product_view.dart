import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/product_viewmodel.dart';
import 'package:unshelf_seller/components/image_delete.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/components/custom_button.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';

class EditProductView extends StatefulWidget {
  final VoidCallback onProductAdded;
  final ProductModel product;

  const EditProductView({
    Key? key,
    required this.onProductAdded,
    required this.product,
  }) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  late ProductViewModel viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel = context.read<ProductViewModel>();
      viewModel.loadProduct(widget.product);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductViewModel>(builder: (context, viewModel, child) {
      return Scaffold(
        appBar: CustomAppBar(
            title: 'Edit Product Details',
            onBackPressed: () {
              Navigator.pop(context);
              viewModel.clearData();
            }),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryColor, width: 5),
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppTheme.spacing16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product Details',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      'Enter product details below',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                )
              ]),
              const SizedBox(height: AppTheme.spacing32),
              Form(
                key: viewModel.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => viewModel.pickImage(true),
                      child: Container(
                        width: double.infinity,
                        height: 350,
                        color: AppColors.darkColor,
                        child: viewModel.mainImageState.data != null
                            ? ImageWithDelete(
                                imageData: viewModel.mainImageState.data!,
                                onDelete: () =>
                                    viewModel.deleteImage(true, null),
                                width: 400.0,
                                height: 400.0,
                                margin: const EdgeInsets.all(0),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo,
                                        color: Colors.white),
                                    Text(
                                      'Add Main Image',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    Text(
                      'Product Gallery',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double itemWidth =
                              (constraints.maxWidth - 10 * 2.0) / 4 - 10.0;

                          var imageList = viewModel.additionalImages;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height:
                                    itemWidth * ((imageList.length / 4).ceil()),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 2.0,
                                    mainAxisSpacing: 2.0,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: imageList.length,
                                  itemBuilder: (context, index) {
                                    final imageData = imageList[index].data;
                                    return Container(
                                      width: itemWidth,
                                      height: itemWidth,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: imageData != null
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 1.0,
                                        ),
                                        color: imageData == null
                                            ? AppColors.surface
                                            : null,
                                      ),
                                      child: imageData != null
                                          ? ImageWithDelete(
                                              imageData: imageData,
                                              width: itemWidth,
                                              height: itemWidth,
                                              onDelete: () => viewModel
                                                  .deleteImage(false, index),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.add_a_photo,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing8),
                              if (imageList.length >= 4)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spacing8),
                                    child: Text(
                                      'Max images have been added',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: CustomButton(
                                    text: 'Add Addtional Image',
                                    onPressed: () => viewModel.pickImage(false),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (viewModel.errorFound)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: AppTheme.spacing8),
                        child: Text(
                          'Main image is required',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    const SizedBox(height: AppTheme.spacing24),
                    Text(
                      'Name',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextFormField(
                      controller: viewModel.nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing8,
                            horizontal: AppTheme.spacing8),
                        labelStyle:
                            TextStyle(color: AppColors.textPrimary),
                        errorStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.error),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    TextFormField(
                      controller: viewModel.descriptionController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing12,
                            horizontal: AppTheme.spacing12),
                        labelStyle:
                            TextStyle(color: AppColors.textPrimary),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleSmall,
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
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
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
                    const SizedBox(height: AppTheme.spacing8),
                    Align(
                      alignment: Alignment.center,
                      child: viewModel.isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Update Product',
                              onPressed: () async {
                                await viewModel.updateProduct(context);

                                if (await viewModel.updateProduct(context)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Product edited successfully!'),
                                    ),
                                  );
                                  viewModel.clearData();
                                  widget.onProductAdded();
                                  Navigator.pop(context, true);
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
    });
  }
}
