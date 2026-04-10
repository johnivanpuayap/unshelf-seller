import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:unshelf_seller/components/custom_app_bar.dart';
import 'package:unshelf_seller/utils/colors.dart';
import 'package:unshelf_seller/utils/theme.dart';
import 'package:unshelf_seller/viewmodels/restock_viewmodel.dart';

class RestockDetailsView extends StatefulWidget {
  const RestockDetailsView({super.key});

  @override
  State<RestockDetailsView> createState() => _RestockDetailsViewState();
}

class _RestockDetailsViewState extends State<RestockDetailsView> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RestockViewModel>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Enter Restock Details',
        onBackPressed: () {
          Navigator.pop(context);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.selectedProducts.length,
                itemBuilder: (context, index) {
                  final product = viewModel.selectedProducts[index];

                  return Card(
                    elevation: AppTheme.elevationHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    margin: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing8),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.product!.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppTheme.spacing8),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Restock Quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacing12),
                            ),
                            onChanged: (value) {
                              final quantity = int.tryParse(value) ?? 0;
                              product.stock = quantity;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? pickedDate =
                                  await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                viewModel.updateExpiryDate(
                                    product, pickedDate);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacing12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                                color: AppColors.surface,
                                border:
                                    Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MM-dd-yyyy')
                                          .format(product.expiryDate),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              color: AppColors.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton(
              onPressed: () async {
                final isFormValid = viewModel.selectedProducts
                    .every((product) => product.stock > 0);

                if (!isFormValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please ensure all products have a quantity and expiry date selected.',
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                await viewModel.batchRestock(viewModel.selectedProducts);
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacing16),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusMedium),
                ),
                backgroundColor: AppColors.primaryColor,
              ),
              child: const Text(
                'Submit Restock',
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (viewModel.error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacing16),
                child: Text(
                  'Error: ${viewModel.error}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
