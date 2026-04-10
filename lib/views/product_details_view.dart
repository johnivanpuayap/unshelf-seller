import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/models/product_model.dart';
import 'package:unshelf_seller/viewmodels/product_summary_viewmodel.dart';
import 'package:unshelf_seller/views/add_batch_view.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:unshelf_seller/views/edit_batch_view.dart';

class ProductDetailsView extends StatefulWidget {
  final String productId;
  final bool? isNew;

  const ProductDetailsView(
      {super.key, required this.productId, this.isNew = false});

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    final viewModel =
        Provider.of<ProductSummaryViewModel>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchProductData(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'Product Details',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: Consumer<ProductSummaryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.product != null &&
              widget.isNew == true &&
              !_dialogShown) {
            _dialogShown = true;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAddBatchDialog(viewModel.product!);
            });
          }

          if (viewModel.product == null) {
            return const Center(child: Text('No product data available.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Image.network(
                  viewModel.product!.mainImageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),

                const SizedBox(height: AppTheme.spacing16),
                _buildProductDetail(context, 'Name', viewModel.product!.name),
                _buildProductDetail(
                    context, 'Description', viewModel.product!.description),
                _buildProductDetail(
                    context, 'Category', viewModel.product!.category),
                const SizedBox(height: AppTheme.spacing4),
                // Batches Section
                _buildSectionHeader(context, 'Batches'),
                _buildBatchesSection(context, viewModel),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<ProductSummaryViewModel>(
        builder: (context, viewModel, child) {
          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddBatchView(
                    product: viewModel.product!,
                  ),
                ),
              );

              if (result == true) {
                viewModel.fetchProductData(widget.productId);
              }
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Batch',
                style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.primaryColor,
          );
        },
      ),
    );
  }

  Widget _buildProductDetail(BuildContext context, String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      elevation: AppTheme.elevationMedium,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: AppColors.primaryColor),
      ),
    );
  }

  Widget _buildBatchesSection(
      BuildContext context, ProductSummaryViewModel viewModel) {
    final batches = viewModel.batches;

    return Column(
      children: [
        if (batches != null && batches.isNotEmpty)
          ListView.builder(
            itemCount: batches.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final batch = batches[index];
              return Card(
                elevation: AppTheme.elevationMedium,
                margin: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacing4),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Number: ${batch.batchNumber}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantity: ${batch.stock}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.textPrimary),
                                    children: [
                                      const TextSpan(
                                        text: 'Price: ',
                                      ),
                                      const TextSpan(
                                        text: '\u20B1 ',
                                        style: TextStyle(
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            '${batch.price.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                    'Expiry Date: ${DateFormat('MM-dd-yyyy').format(batch.expiryDate)}'),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.primaryColor),
                                onPressed: () async {
                                  final editResult = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditBatchView(
                                        batchNumber: batch.batchNumber,
                                      ),
                                    ),
                                  );

                                  if (editResult == true) {
                                    viewModel
                                        .fetchProductData(widget.productId);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.error),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Delete Batch',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this batch?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            'No',
                                            style: TextStyle(
                                              color: AppColors.primaryColor,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            viewModel
                                                .deleteBatch(batch.batchNumber);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            'Yes',
                                            style: TextStyle(
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium),
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          )
        else
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: AppTheme.elevationMedium,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      'No batches available.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddBatchDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Batch',
              style: TextStyle(color: AppColors.primaryColor)),
          content: const Text(
            'Products need to have batches to be listed.\nDo you want to add a batch now?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Skip',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddBatchView(product: product),
                  ),
                );

                if (result == true) {
                  if (mounted) {
                    final viewModel = Provider.of<ProductSummaryViewModel>(
                        context,
                        listen: false);
                    viewModel.fetchProductData(product.id);
                  }
                }
              },
              child: const Text(
                'Add Batch',
                style: TextStyle(color: AppColors.primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }
}
