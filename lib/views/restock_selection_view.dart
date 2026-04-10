import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/viewmodels/restock_viewmodel.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'restock_details_view.dart';

class RestockSelectionView extends StatefulWidget {
  const RestockSelectionView({super.key});

  @override
  State<RestockSelectionView> createState() => _RestockSelectionViewState();
}

class _RestockSelectionViewState extends State<RestockSelectionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<RestockViewModel>(context, listen: false);
      viewModel.fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RestockViewModel>(context);

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Select Products for Restocking',
          onBackPressed: () {
            Navigator.pop(context);
          }),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  if (viewModel.products.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No products available for restocking.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: viewModel.products.length,
                        itemBuilder: (context, index) {
                          final product = viewModel.products[index];
                          bool isSelected = viewModel.contain(product);

                          return Card(
                            elevation: AppTheme.elevationHigh - 1,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            margin: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing8),
                            color: isSelected
                                ? AppColors.primaryColor
                                : Theme.of(context).colorScheme.surface,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacing8,
                                horizontal: AppTheme.spacing16,
                              ),
                              title: Text(
                                product.product!.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                'Current Quantity: ${product.stock}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: isSelected
                                            ? Colors.white70
                                            : AppColors.textSecondary),
                              ),
                              leading: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(product.product!.mainImageUrl),
                                radius: 30,
                                backgroundColor: AppColors.surface,
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.check_circle_outline,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                size: 30,
                              ),
                              onTap: () {
                                setState(() {
                                  viewModel.addSelectedProduct(product);
                                });
                              },
                              onLongPress: () {
                                setState(() {
                                  viewModel.removeSelectedProduct(product);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppTheme.spacing16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.selectedProducts.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RestockDetailsView(),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        backgroundColor: viewModel.selectedProducts.isNotEmpty
                            ? AppColors.primaryColor
                            : AppColors.textSecondary,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
